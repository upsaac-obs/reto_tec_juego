// Creación y desarrollo: Dylan Isaac Mancilla López, José Paulo Vélez Ortiz
package org.fundacionado.rutakids.data

import android.content.Context
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
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
    val totalStars get() = Levels.menu.sumOf { starsFor(it.id) }

    /** El tutorial y el primer nivel de la lista siempre están abiertos; los demás con 1 estrella en el anterior. */
    fun isUnlocked(levelId: Int) = levelId <= Levels.menu.first().id || starsFor(levelId - 1) >= 1
}

/**
 * Todo lo que guarda la app (plan del sprint, sección 5.2). Nada personal.
 * Claves: mode, muted, kiosk, tutorial_done, level_<id>_stars, level_<id>_points, level_<id>_infractions,
 * garage_owned, garage_vehicle, garage_hint_seen.
 */
class SettingsStore(private val context: Context) {

    /** "peque", "grande" o null si todavía no se elige (primera vez que se abre la app). */
    val mode: Flow<String?> = context.dataStore.data.map { it[MODE] }
    val muted: Flow<Boolean> = context.dataStore.data.map { it[MUTED] ?: false }
    val kiosk: Flow<Boolean> = context.dataStore.data.map { it[KIOSK] ?: false }
    /** Se terminó el tutorial (nivel 0). Hasta entonces Jugar abre el tutorial. */
    val tutorialDone: Flow<Boolean> = context.dataStore.data.map { it[TUTORIAL_DONE] ?: false }

    /** Vehículos comprados, el elegido y si ya se vio el aviso (Garage). */
    val garage: Flow<GarageState> = context.dataStore.data.map { prefs ->
        val owned = (prefs[GARAGE_OWNED] ?: emptySet()) + Garage.DEFAULT
        val selected = prefs[GARAGE_VEHICLE]?.takeIf { it in owned } ?: Garage.DEFAULT
        GarageState(owned, selected, prefs[GARAGE_HINT_SEEN] ?: false)
    }

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
            if (levelId == Levels.TUTORIAL_ID) prefs[TUTORIAL_DONE] = true
        }
    }

    /**
     * Compra [vehicleId] y lo deja elegido, si alcanzan las estrellas. Revisa el saldo dentro
     * de la misma escritura para que dos toques seguidos no gasten dos veces. Devuelve si compró.
     */
    suspend fun buyVehicle(vehicleId: String): Boolean {
        val vehicle = Garage.all.firstOrNull { it.id == vehicleId } ?: return false
        var bought = false
        context.dataStore.edit { prefs ->
            val owned = (prefs[GARAGE_OWNED] ?: emptySet()) + Garage.DEFAULT
            val total = Levels.menu.sumOf { prefs[starsKey(it.id)] ?: 0 }
            if (vehicle.id !in owned && Garage.balance(total, owned) >= vehicle.price) {
                prefs[GARAGE_OWNED] = owned + vehicle.id
                prefs[GARAGE_VEHICLE] = vehicle.id
                bought = true
            }
        }
        return bought
    }

    /** Elige un vehículo ya comprado. */
    suspend fun selectVehicle(vehicleId: String) {
        context.dataStore.edit { prefs ->
            val owned = (prefs[GARAGE_OWNED] ?: emptySet()) + Garage.DEFAULT
            if (vehicleId in owned) prefs[GARAGE_VEHICLE] = vehicleId
        }
    }

    suspend fun markGarageHintSeen() {
        context.dataStore.edit { it[GARAGE_HINT_SEEN] = true }
    }

    /**
     * Borra estrellas, puntos, faltas, el tutorial terminado y el garaje (sin estrellas no hay
     * con qué haberlo comprado). El modo, el sonido y el kiosco se quedan.
     */
    suspend fun resetProgress() {
        context.dataStore.edit { prefs ->
            for (level in Levels.all) {
                prefs.remove(starsKey(level.id))
                prefs.remove(pointsKey(level.id))
                prefs.remove(infractionsKey(level.id))
            }
            prefs.remove(TUTORIAL_DONE)
            prefs.remove(GARAGE_OWNED)
            prefs.remove(GARAGE_VEHICLE)
            prefs.remove(GARAGE_HINT_SEEN)
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
        private val TUTORIAL_DONE = booleanPreferencesKey("tutorial_done")
        private val GARAGE_OWNED = stringSetPreferencesKey("garage_owned")
        private val GARAGE_VEHICLE = stringPreferencesKey("garage_vehicle")
        private val GARAGE_HINT_SEEN = booleanPreferencesKey("garage_hint_seen")
        private fun starsKey(id: Int): Preferences.Key<Int> = intPreferencesKey("level_${id}_stars")
        private fun pointsKey(id: Int): Preferences.Key<Int> = intPreferencesKey("level_${id}_points")
        private fun infractionsKey(id: Int): Preferences.Key<String> = stringPreferencesKey("level_${id}_infractions")
    }
}
