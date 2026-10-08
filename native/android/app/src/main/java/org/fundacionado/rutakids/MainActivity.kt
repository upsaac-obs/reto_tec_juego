package org.fundacionado.rutakids

import android.os.Bundle
import android.os.Debug
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.View
import android.widget.FrameLayout
import androidx.activity.OnBackPressedCallback
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.fragment.app.FragmentActivity
import org.godotengine.godot.Godot
import org.godotengine.godot.GodotFragment
import org.godotengine.godot.GodotHost
import org.godotengine.godot.plugin.GodotPlugin
import org.json.JSONObject

/**
 * Spike de la arquitectura híbrida (docs/arquitectura.md, sección 6).
 * El menú es nativo (Compose) y va encima de Godot. Godot arranca una sola vez
 * en segundo plano (idle.tscn) y nunca se destruye entre niveles (H1).
 * Los textos están fijos porque es una prueba; en la app real salen de textos.csv (H8).
 */
class MainActivity : FragmentActivity(), GodotHost {

    private var godotFragment: GodotFragment? = null
    private var bridge: RutaBridgePlugin? = null
    private lateinit var menu: ComposeView

    private val createdAt = SystemClock.elapsedRealtime()
    private val engineReady = mutableStateOf(false)
    private val readyMs = mutableStateOf<Long?>(null)
    private val playing = mutableStateOf(false)
    private val lastResult = mutableStateOf("—")
    private val log = mutableStateListOf<String>()

    // Prueba de 10 ciclos abrir/cerrar (H1, H7).
    private val handler = Handler(Looper.getMainLooper())
    private var cyclesLeft = 0
    private val cycleMemory = mutableStateListOf<Int>()

    private val prefs by lazy { getSharedPreferences("progreso", MODE_PRIVATE) }
    private val bestStars = mutableStateMapOf<Int, Int>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        for (id in listOf(1, 99)) bestStars[id] = prefs.getInt("stars_$id", 0)
        val root = FrameLayout(this)
        val godotContainer = FrameLayout(this).apply { id = View.generateViewId() }
        menu = ComposeView(this).apply { setContent { Menu() } }
        root.addView(godotContainer)
        root.addView(menu)
        setContentView(root)

        godotFragment = supportFragmentManager.findFragmentById(godotContainer.id) as? GodotFragment
        if (godotFragment == null) {
            godotFragment = GodotFragment()
            supportFragmentManager.beginTransaction().replace(godotContainer.id, godotFragment!!).commitNow()
        }

        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                if (playing.value) bridge?.abortLevel() else finish()
            }
        })
    }

    // --- GodotHost ---

    override fun getActivity() = this

    override fun getGodot(): Godot? = godotFragment?.godot

    override fun getHostPlugins(engine: Godot): Set<GodotPlugin> {
        val plugin = RutaBridgePlugin(engine, ::onBridgeEvent)
        bridge = plugin
        return setOf(plugin)
    }

    // --- Ciclo de vida (sección 4, paso 6) ---

    override fun onPause() {
        super.onPause()
        if (playing.value) bridge?.pauseLevel()
    }

    override fun onResume() {
        super.onResume()
        if (playing.value) bridge?.resumeLevel()
    }

    // --- Godot → nativo ---

    private fun onBridgeEvent(event: String, json: String) {
        addLog("← $event $json")
        val data = runCatching { JSONObject(json) }.getOrNull()
        when (event) {
            "engine_ready" -> {
                engineReady.value = true
                readyMs.value = SystemClock.elapsedRealtime() - createdAt
            }
            "level_started" -> showGodot(true)
            "level_finished" -> data?.let { saveResult(it) }
            "level_exited" -> {
                showGodot(false)
                if (cyclesLeft > 0) nextCycle()
            }
            "inactivity_timeout" -> bridge?.abortLevel()
            "bridge_error" -> lastResult.value = "Error: ${data?.optString("code")} ${data?.optString("detail")}"
        }
    }

    /** Guardado nativo (SharedPreferences en el spike): mejor número de estrellas por nivel. */
    private fun saveResult(data: JSONObject) {
        val id = data.getInt("level_id")
        val stars = data.getInt("stars")
        val best = maxOf(stars, prefs.getInt("stars_$id", 0))
        prefs.edit().putInt("stars_$id", best).apply()
        bestStars[id] = best
        lastResult.value = "Nivel $id: $stars★ (mejor $best★), ${data.getInt("points")} puntos, " +
            "faltas ${data.getJSONObject("infractions")}, ${data.getInt("duration_s")} s"
    }

    private fun showGodot(show: Boolean) {
        playing.value = show
        menu.visibility = if (show) View.GONE else View.VISIBLE
    }

    private fun startLevel(id: Int) {
        bridge?.startLevel(id, mode = "grande", kiosk = false, muted = false)
    }

    // --- Prueba de 10 ciclos ---

    private fun startCycles() {
        cycleMemory.clear()
        cyclesLeft = 10
        nextCycle()
    }

    private fun nextCycle() {
        cycleMemory.add(Debug.getPss().toInt() / 1024)
        if (cyclesLeft == 0) {
            addLog("Ciclos terminados. Memoria (MB): ${cycleMemory.joinToString()}")
            return
        }
        cyclesLeft--
        handler.postDelayed({
            startLevel(99)
            handler.postDelayed({ bridge?.abortLevel() }, 1500)
        }, 500)
    }

    private fun addLog(line: String) {
        Log.i("RutaBridge", line)
        log.add(0, line)
        if (log.size > 30) log.removeAt(log.lastIndex)
    }

    // --- Menú nativo ---

    @androidx.compose.runtime.Composable
    private fun Menu() {
        MaterialTheme {
            Row(
                Modifier.fillMaxSize().background(Color(0xFF3F1B4E)).padding(24.dp),
                horizontalArrangement = Arrangement.spacedBy(24.dp),
            ) {
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text("RutaKids · spike Android", color = Color.White, fontSize = 28.sp)
                    if (engineReady.value) {
                        Text("Godot listo en ${readyMs.value} ms", color = Color(0xFFFFC700))
                    } else {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            CircularProgressIndicator(color = Color(0xFFFFC700))
                            Text("  Cargando Godot…", color = Color.White)
                        }
                    }
                    val ready = engineReady.value
                    Button(onClick = { startLevel(1) }, enabled = ready) {
                        Text("Nivel 1 · calle de prueba (${bestStars[1]}★)")
                    }
                    Button(onClick = { startLevel(99) }, enabled = ready) {
                        Text("Nivel 99 · botones (${bestStars[99]}★)")
                    }
                    OutlinedButton(onClick = { startCycles() }, enabled = ready) {
                        Text("Abrir y cerrar 10 veces", color = Color.White)
                    }
                    Text("Último resultado: ${lastResult.value}", color = Color.White)
                    if (cycleMemory.isNotEmpty()) {
                        Text("Memoria por ciclo (MB): ${cycleMemory.joinToString()}", color = Color.White)
                    }
                }
                Column(Modifier.weight(1f).verticalScroll(rememberScrollState())) {
                    Text("Mensajes del puente", color = Color(0xFFFFC700))
                    log.forEach { Text(it, color = Color.White, fontSize = 12.sp) }
                }
            }
        }
    }
}
