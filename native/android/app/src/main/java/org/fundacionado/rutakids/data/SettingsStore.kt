package org.fundacionado.rutakids.data

import android.content.Context
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import org.json.JSONObject

private val Context.dataStore by preferencesDataStore(name = "rutakids")

/** Progreso guardado de todos los niveles. */
data class Progress(
    val stars: Map<Int, Int> = emptyMap(),
    val points: Map<Int, Int> = emptyMap(),
    /** Faltas del último intento terminado de cada nivel, p. ej. {"stop":1}. */
    val infractions: Map<Int, Map<String, Int>> = emptyMap(),
) {
    fun starsFor(levelId: Int) = stars[levelId] ?: 0
    val totalStars get() = stars.values.sum()

    /** El 0 siempre está abierto; cada nivel se abre con 1 estrella en el anterior. */
    fun isUnlocked(levelId: Int) = levelId == 0 || starsFor(levelId - 1) >= 1
}

/**
 * Todo lo que guarda la app (plan del sprint, sección 5.2). Nada personal.
 * Claves: mode, muted, kiosk, level_<id>_stars, level_<id>_points, level_<id>_infractions.
 */
class SettingsStore(private val context: Context) {

    /** "peque", "grande" o null si todavía no se elige (primera vez que se abre la app). */
    val mode: Flow<String?> = context.dataStore.data.map { it[MODE] }
    val muted: Flow<Boolean> = context.dataStore.data.map { it[MUTED] ?: false }
    val kiosk: Flow<Boolean> = context.dataStore.data.map { it[KIOSK] ?: false }

    val progress: Flow<Progress> = context.dataStore.data.map { prefs ->
        val ids = Levels.all.map { it.id }
        Progress(
            stars = ids.associateWith { prefs[starsKey(it)] ?: 0 },
            points = ids.associateWith { prefs[pointsKey(it)] ?: 0 },
            infractions = ids.associateWith { parseInfractions(prefs[infractionsKey(it)]) },
        )
    }

    suspend fun saveMode(mode: String) {
        require(mode == MODE_PEQUE || mode == MODE_GRANDE) { "Modo inválido: $mode" }
        context.dataStore.edit { it[MODE] = mode }
    }

    suspend fun saveMuted(value: Boolean) {
        context.dataStore.edit { it[MUTED] = value }
    }

    suspend fun saveKiosk(value: Boolean) {
        context.dataStore.edit { it[KIOSK] = value }
    }

    /** Guarda el resultado de level_finished. Estrellas y puntos: siempre el mejor. */
    suspend fun saveLevelResult(levelId: Int, stars: Int, points: Int, infractions: Map<String, Int>) {
        context.dataStore.edit { prefs ->
            prefs[starsKey(levelId)] = maxOf(stars, prefs[starsKey(levelId)] ?: 0)
            prefs[pointsKey(levelId)] = maxOf(points, prefs[pointsKey(levelId)] ?: 0)
            prefs[infractionsKey(levelId)] = JSONObject(infractions).toString()
        }
    }

    /** Borra estrellas, puntos y faltas. El modo, el sonido y el kiosco se quedan. */
    suspend fun resetProgress() {
        context.dataStore.edit { prefs ->
            for (level in Levels.all) {
                prefs.remove(starsKey(level.id))
                prefs.remove(pointsKey(level.id))
                prefs.remove(infractionsKey(level.id))
            }
        }
    }

    private fun parseInfractions(json: String?): Map<String, Int> {
        if (json == null) return emptyMap()
        return runCatching {
            val obj = JSONObject(json)
            obj.keys().asSequence().associateWith { obj.getInt(it) }
        }.getOrDefault(emptyMap())
    }

    companion object {
        const val MODE_PEQUE = "peque"
        const val MODE_GRANDE = "grande"
        private val MODE = stringPreferencesKey("mode")
        private val MUTED = booleanPreferencesKey("muted")
        private val KIOSK = booleanPreferencesKey("kiosk")
        private fun starsKey(id: Int): Preferences.Key<Int> = intPreferencesKey("level_${id}_stars")
        private fun pointsKey(id: Int): Preferences.Key<Int> = intPreferencesKey("level_${id}_points")
        private fun infractionsKey(id: Int): Preferences.Key<String> = stringPreferencesKey("level_${id}_infractions")
    }
}
