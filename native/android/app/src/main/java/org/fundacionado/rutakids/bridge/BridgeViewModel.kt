package org.fundacionado.rutakids.bridge

import android.app.Application
import android.util.Log
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import org.fundacionado.rutakids.RutaBridgePlugin
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

    fun setKiosk(kiosk: Boolean) {
        viewModelScope.launch { settings.saveKiosk(kiosk) }
    }

    fun resetProgress() {
        viewModelScope.launch { settings.resetProgress() }
    }

    /** Cierra Tutores cuando se abrió desde dentro de un nivel y reanuda el juego. */
    fun closeTutorsOverLevel() {
        if (!_state.value.tutorsOverLevel) return
        _state.update { it.copy(tutorsOverLevel = false) }
        bridge?.resumeLevel()
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
            is BridgeEvent.LevelExited -> _state.update {
                it.copy(levelVisible = false, requestedLevel = null, tutorsOverLevel = false)
            }
            // Engrane de 3 s dentro del nivel: se pausa y se abre Tutores encima.
            is BridgeEvent.TutorRequested -> if (_state.value.levelVisible) {
                bridge?.pauseLevel()
                _state.update { it.copy(tutorsOverLevel = true) }
            }
            is BridgeEvent.Error -> _state.update { s ->
                val notBuilt = event.detail.toIntOrNull()
                    ?.takeIf { event.code == "level_not_built" }
                    ?.let { s.notBuiltLevels + it } ?: s.notBuiltLevels
                // Si el error llegó antes de abrir el nivel, Godot no manda level_exited: se libera aquí.
                if (s.levelVisible) s.copy(notBuiltLevels = notBuilt)
                else s.copy(notBuiltLevels = notBuilt, requestedLevel = null)
            }
            // TODO(Ángel, tarea 20): en kiosco, abort_level y regresar a Inicio.
            BridgeEvent.InactivityTimeout -> Unit
        }
    }

    private companion object {
        const val TAG = "RutaBridge"
    }
}
