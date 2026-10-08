package org.fundacionado.rutakids

import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

/**
 * Puente con Godot (contrato en docs/arquitectura.md, sección 3).
 * - Nativo → Godot: señales start_level, pause_level, resume_level, abort_level, set_muted.
 * - Godot → nativo: Godot llama notify(event, json); se pasa a [onEvent] en el hilo principal.
 * En GDScript se obtiene con Engine.get_singleton("RutaBridge").
 */
class RutaBridgePlugin(
    godot: Godot,
    private val onEvent: (event: String, json: String) -> Unit,
) : GodotPlugin(godot) {

    override fun getPluginName() = "RutaBridge"

    override fun getPluginSignals() = setOf(START_LEVEL, PAUSE_LEVEL, RESUME_LEVEL, ABORT_LEVEL, SET_MUTED)

    /** Lo llama Godot desde su hilo; la app lo recibe en el hilo principal. */
    @UsedByGodot
    fun notify(event: String, json: String) {
        runOnUiThread { onEvent(event, json) }
    }

    fun startLevel(levelId: Int, mode: String, kiosk: Boolean, muted: Boolean) {
        val json = """{"v":1,"level_id":$levelId,"mode":"$mode","kiosk":$kiosk,"muted":$muted}"""
        emit(START_LEVEL, json)
    }

    fun pauseLevel() = emit(PAUSE_LEVEL)
    fun resumeLevel() = emit(RESUME_LEVEL)
    fun abortLevel() = emit(ABORT_LEVEL)
    fun setMuted(muted: Boolean) = emit(SET_MUTED, muted)

    private fun emit(signal: SignalInfo, vararg args: Any) {
        runOnRenderThread { emitSignal(signal, *args) }
    }

    companion object {
        private val START_LEVEL = SignalInfo("start_level", String::class.java)
        private val PAUSE_LEVEL = SignalInfo("pause_level")
        private val RESUME_LEVEL = SignalInfo("resume_level")
        private val ABORT_LEVEL = SignalInfo("abort_level")
        private val SET_MUTED = SignalInfo("set_muted", java.lang.Boolean::class.java)
    }
}
