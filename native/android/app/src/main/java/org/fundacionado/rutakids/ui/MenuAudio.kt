package org.fundacionado.rutakids.ui

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.SoundPool
import androidx.compose.runtime.staticCompositionLocalOf
import org.fundacionado.rutakids.R

/**
 * Sonidos de los menús (res/raw, de tools/menu_sounds.sh; los mismos que iOS):
 * menu_tap al tocar un botón, menu_locked en una parada cerrada, menu_unlock cuando el
 * auto llega a una parada nueva y menu_music en bucle mientras se ve el menú.
 * RutaKidsApp decide cuándo suena la música ([setMusicPlaying]) y si todo está callado
 * ([muted], el mismo botón de sonido que calla al juego).
 */
class MenuAudio(context: Context) {
    private val appContext = context.applicationContext
    private val attributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_GAME)
        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
        .build()
    private val pool = SoundPool.Builder().setMaxStreams(4).setAudioAttributes(attributes).build()
    private val tap = pool.load(appContext, R.raw.menu_tap, 1)
    private val locked = pool.load(appContext, R.raw.menu_locked, 1)
    private val unlock = pool.load(appContext, R.raw.menu_unlock, 1)
    private var music: MediaPlayer? = null

    var muted: Boolean = false
        set(value) {
            field = value
            if (value) music?.pause()
        }

    fun tap() = play(tap, TAP_VOLUME)
    fun locked() = play(locked, TAP_VOLUME)
    fun unlock() = play(unlock, 1f)

    private fun play(id: Int, volume: Float) {
        if (!muted) pool.play(id, volume, volume, 1, 0, 1f)
    }

    /** Música del menú: suena si [playing] y no está callado; si no, se pausa donde iba. */
    fun setMusicPlaying(playing: Boolean) {
        if (!playing || muted) {
            music?.takeIf { it.isPlaying }?.pause()
            return
        }
        val player = music ?: MediaPlayer.create(appContext, R.raw.menu_music)?.apply {
            isLooping = true
            setVolume(MUSIC_VOLUME, MUSIC_VOLUME)
        }.also { music = it }
        player?.takeIf { !it.isPlaying }?.start()
    }

    fun release() {
        music?.release()
        music = null
        pool.release()
    }

    private companion object {
        const val TAP_VOLUME = 0.8f
        const val MUSIC_VOLUME = 0.45f
    }
}

/** El MenuAudio de la app (lo pone RutaKidsApp); null en vistas previas. */
val LocalMenuAudio = staticCompositionLocalOf<MenuAudio?> { null }
