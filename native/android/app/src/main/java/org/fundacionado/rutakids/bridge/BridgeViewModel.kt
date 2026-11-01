package org.fundacionado.rutakids.bridge

import android.app.Application
import android.util.Log
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import android.os.SystemClock
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import org.fundacionado.rutakids.RutaBridgePlugin
import org.fundacionado.rutakids.data.Levels
import org.fundacionado.rutakids.data.SettingsStore
import org.json.JSONObject

/** Estado de Godot que necesitan las pantallas. */
data class GodotState(
    /** Llegó engine_ready. Antes de eso las tarjetas muestran "cargando". */
    val engineReady: Boolean = false,
    /** Nivel pedido con start_level que todavía no se cierra (o null). */
    val requestedLevel: Int? = null,
    /** La vista de Godot se ve (entre level_started y level_exited). */
    val levelVisible: Boolean = false,
    /** Niveles que Godot respondió con level_not_built: su tarjeta sale bloqueada. */
    val notBuiltLevels: Set<Int> = emptySet(),
    /** Tutores abierto encima de un nivel pausado (llegó tutor_requested). */
    val tutorsOverLevel: Boolean = false,
)

/** Mensajes de Godot → nativo ya leídos (contrato en docs/arquitectura.md, sección 3). */
sealed interface BridgeEvent {
    data object EngineReady : BridgeEvent
    data class LevelStarted(val levelId: Int) : BridgeEvent
    data class LevelFinished(
        val levelId: Int,
        val stars: Int,
        val points: Int,
        /** Solo trae las reglas con al menos una falta, p. ej. {"stop":1}. */
        val infractions: Map<String, Int>,
        val durationS: Int,
    ) : BridgeEvent
    data class LevelExited(val levelId: Int, val completed: Boolean) : BridgeEvent
    data object InactivityTimeout : BridgeEvent
    data class TutorRequested(val levelId: Int) : BridgeEvent
    data class Error(val code: String, val detail: String) : BridgeEvent
}

/** Órdenes del ViewModel a la navegación del menú (las cumple RutaKidsApp). */
sealed interface MenuCommand {
    /** Volver a Inicio (kiosco: 60 s sin tocar, inactivity_timeout o recién activado). */
    data object GoHome : MenuCommand
    /** Abrir la lista de niveles (al salir del tutorial de la primera vez). */
    data object OpenLevels : MenuCommand
}

/**
 * Envuelve el puente RutaBridge para que las pantallas no lo toquen directo:
 * solo llaman startLevel(id), abortLevel(), setMuted(...), etc.
 *
 * - [state]: lo que se dibuja (cargando, listo, nivel abierto).
 * - [events]: cada mensaje de Godot, para quien lo necesite
 *   (guardado con LevelFinished, tutores con TutorRequested, kiosco con InactivityTimeout).
 */
class BridgeViewModel(app: Application) : AndroidViewModel(app) {

    val settings = SettingsStore(app)

    private var bridge: RutaBridgePlugin? = null

    private val _state = MutableStateFlow(GodotState())
    val state: StateFlow<GodotState> = _state.asStateFlow()

    private val _events = MutableSharedFlow<BridgeEvent>(extraBufferCapacity = 32)
    val events: SharedFlow<BridgeEvent> = _events.asSharedFlow()

    private val _commands = MutableSharedFlow<MenuCommand>(extraBufferCapacity = 8)
    val commands: SharedFlow<MenuCommand> = _commands.asSharedFlow()

    /** Kiosco guardado, siempre a la mano (lo necesitan el atrás, el temporizador y Tutores). */
    val kiosk: StateFlow<Boolean> = settings.kiosk.stateIn(viewModelScope, SharingStarted.Eagerly, false)

    /** Primera vez en Jugar: al salir del tutorial se abre la lista de niveles. */
    private var openLevelsAfterTutorial = false

    /** Último toque en cualquier parte de la app (SystemClock.elapsedRealtime). */
    @Volatile
    var lastTouchMs: Long = SystemClock.elapsedRealtime()
        private set

    /** Lo llama MainActivity con cada toque real en la pantalla. */
    fun onUserTouch() {
        lastTouchMs = SystemClock.elapsedRealtime()
    }

    /** Kiosco: tiempo sin tocar desde el último toque. */
    fun idleMs(): Long = SystemClock.elapsedRealtime() - lastTouchMs

    /** Vuelve a Inicio y reinicia la cuenta de inactividad. */
    fun goHome() {
        onUserTouch()
        _commands.tryEmit(MenuCommand.GoHome)
    }

    /** Lo llama MainActivity cuando Godot crea el plugin. */
    fun attach(plugin: RutaBridgePlugin) {
        bridge = plugin
    }

    // --- Nativo → Godot ---

    /** Abre un nivel con el modo, kiosco y sonido guardados. No hace nada si Godot no está listo o ya hay uno pedido. */
    fun startLevel(levelId: Int) {
        val current = _state.value
        if (!current.engineReady || current.requestedLevel != null) return
        _state.update { it.copy(requestedLevel = levelId) }
        viewModelScope.launch {
            val mode = settings.mode.first() ?: SettingsStore.MODE_GRANDE
            val kiosk = settings.kiosk.first()
            val muted = settings.muted.first()
            bridge?.startLevel(levelId, mode = mode, kiosk = kiosk, muted = muted)
        }
    }

    /**
     * Botón Jugar después de elegir edad. Si toca el tutorial (primera vez y fuera del kiosco)
     * lo abre en cuanto Godot esté listo y devuelve true; si no, devuelve false y se abre la lista.
     */
    suspend fun playTutorialIfNeeded(): Boolean {
        if (kiosk.value || settings.tutorialDone.first()) return false
        openLevelsAfterTutorial = true
        viewModelScope.launch {
            state.first { it.engineReady }
            startLevel(Levels.TUTORIAL_ID)
        }
        return true
    }

    fun abortLevel() {
        if (_state.value.requestedLevel != null) bridge?.abortLevel()
    }

    fun pauseLevel() {
        if (_state.value.levelVisible) bridge?.pauseLevel()
    }

    fun resumeLevel() {
        // Con Tutores abierto el nivel sigue en pausa hasta cerrar Tutores.
        if (_state.value.levelVisible && !_state.value.tutorsOverLevel) bridge?.resumeLevel()
    }

    fun setMuted(muted: Boolean) {
        viewModelScope.launch { settings.saveMuted(muted) }
        bridge?.setMuted(muted)
    }

    // --- Ajustes de Tutores ---

    fun setMode(mode: String) {
        viewModelScope.launch { settings.saveMode(mode) }
    }

    /** Al activar el kiosco se cierra Tutores (y el nivel de abajo, si lo hay) y se vuelve a Inicio, como en iOS. */
    fun setKiosk(kiosk: Boolean) {
        viewModelScope.launch { settings.saveKiosk(kiosk) }
        if (kiosk) {
            if (_state.value.tutorsOverLevel) {
                _state.update { it.copy(tutorsOverLevel = false) }
                bridge?.abortLevel()
            }
            goHome()
        }
    }

    fun resetProgress() {
        viewModelScope.launch { settings.resetProgress() }
    }

    /** Cierra Tutores cuando se abrió desde dentro de un nivel: el juego sigue, o en kiosco se cierra (como iOS). */
    fun closeTutorsOverLevel() {
        if (!_state.value.tutorsOverLevel) return
        _state.update { it.copy(tutorsOverLevel = false) }
        if (kiosk.value) {
            bridge?.abortLevel()
            goHome()
        } else {
            bridge?.resumeLevel()
        }
    }

    // --- Godot → nativo ---

    /** Lo llama el plugin en el hilo principal. */
    fun onBridgeMessage(event: String, json: String) {
        Log.i(TAG, "← $event $json")
        val data = runCatching { JSONObject(json) }.getOrNull() ?: JSONObject()
        val parsed: BridgeEvent = when (event) {
            "engine_ready" -> BridgeEvent.EngineReady
            "level_started" -> BridgeEvent.LevelStarted(data.optInt("level_id"))
            "level_finished" -> BridgeEvent.LevelFinished(
                levelId = data.optInt("level_id"),
                stars = data.optInt("stars"),
                points = data.optInt("points"),
                infractions = data.optJSONObject("infractions")?.let { obj ->
                    obj.keys().asSequence().associateWith { obj.optInt(it) }
                } ?: emptyMap(),
                durationS = data.optInt("duration_s"),
            )
            "level_exited" -> BridgeEvent.LevelExited(data.optInt("level_id"), data.optBoolean("completed"))
            "inactivity_timeout" -> BridgeEvent.InactivityTimeout
            "tutor_requested" -> BridgeEvent.TutorRequested(data.optInt("level_id"))
            "bridge_error" -> BridgeEvent.Error(data.optString("code"), data.optString("detail"))
            else -> {
                Log.w(TAG, "Evento desconocido: $event")
                return
            }
        }
        updateState(parsed)
        _events.tryEmit(parsed)
    }

    private fun updateState(event: BridgeEvent) {
        when (event) {
            BridgeEvent.EngineReady -> _state.update { it.copy(engineReady = true) }
            is BridgeEvent.LevelStarted -> _state.update { it.copy(levelVisible = true) }
            // La vista NO se cierra con level_finished: Godot muestra la tarjeta de hábito.
            // Se guarda en ese momento por si la app se cierra. En kiosco no se guarda nada.
            is BridgeEvent.LevelFinished -> viewModelScope.launch {
                if (!settings.kiosk.first()) {
                    settings.saveLevelResult(event.levelId, event.stars, event.points, event.infractions)
                }
            }
            // Solo aquí se esconde Godot. Puede llegar sin level_started antes (contrato).
            is BridgeEvent.LevelExited -> {
                _state.update { it.copy(levelVisible = false, requestedLevel = null, tutorsOverLevel = false) }
                onUserTouch()
                if (openLevelsAfterTutorial) {
                    openLevelsAfterTutorial = false
                    _commands.tryEmit(MenuCommand.OpenLevels)
                }
            }
            // Engrane de 3 s dentro del nivel: se pausa y se abre Tutores encima.
            is BridgeEvent.TutorRequested -> if (_state.value.levelVisible) {
                bridge?.pauseLevel()
                _state.update { it.copy(tutorsOverLevel = true) }
            }
            is BridgeEvent.Error -> {
                val beforeLevel = !_state.value.levelVisible
                _state.update { s ->
                    val notBuilt = event.detail.toIntOrNull()
                        ?.takeIf { event.code == "level_not_built" }
                        ?.let { s.notBuiltLevels + it } ?: s.notBuiltLevels
                    // Si el error llegó antes de abrir el nivel, Godot no manda level_exited: se libera aquí.
                    if (s.levelVisible) s.copy(notBuiltLevels = notBuilt)
                    else s.copy(notBuiltLevels = notBuilt, requestedLevel = null)
                }
                // El tutorial no abrió: se pasa directo a la lista.
                if (beforeLevel && openLevelsAfterTutorial) {
                    openLevelsAfterTutorial = false
                    _commands.tryEmit(MenuCommand.OpenLevels)
                }
            }
            // Godot cuenta la inactividad dentro del nivel (solo en kiosco): se cierra y se vuelve a Inicio.
            BridgeEvent.InactivityTimeout -> {
                abortLevel()
                goHome()
            }
        }
    }

    private companion object {
        const val TAG = "RutaBridge"
    }
}
