// Creación y desarrollo: Dylan Isaac Mancilla López, José Paulo Vélez Ortiz
package org.fundacionado.rutakids.data

import androidx.annotation.StringRes
import org.fundacionado.rutakids.R

/**
 * Niveles de la entrega: del 0 al 8 (docs/plan_cierre.md). El id es el level_id del juego
 * (data/level_XX.tres), así que no se puede reordenar: el 0 siempre abre "Abróchate y arranca".
 */
data class LevelInfo(
    val id: Int,
    @StringRes val nameRes: Int,
    /** Punto del decálogo que enseña (el decalogo_key de data/level_XX.tres); null en el tutorial. */
    @StringRes val decalogoRes: Int?,
)

object Levels {
    val all = listOf(
        LevelInfo(0, R.string.NIVEL_00_NOMBRE, null),
        LevelInfo(1, R.string.NIVEL_01_NOMBRE, R.string.DECALOGO_01),
        LevelInfo(2, R.string.NIVEL_02_NOMBRE, R.string.DECALOGO_04),
        LevelInfo(3, R.string.NIVEL_03_NOMBRE, R.string.DECALOGO_03),
        LevelInfo(4, R.string.NIVEL_04_NOMBRE, R.string.DECALOGO_08),
        LevelInfo(5, R.string.NIVEL_05_NOMBRE, R.string.DECALOGO_02),
        LevelInfo(6, R.string.NIVEL_06_NOMBRE, R.string.DECALOGO_06),
        LevelInfo(7, R.string.NIVEL_07_NOMBRE, R.string.DECALOGO_07),
        LevelInfo(8, R.string.NIVEL_08_NOMBRE, R.string.DECALOGO_05),
    )

    /** El 0 es el tutorial: se abre solo la primera vez que se toca Jugar (fuera del kiosco). */
    const val TUTORIAL_ID = 0

    /** Tarjetas de la lista de niveles y de Tutores (igual que iOS: del 1 al 8). */
    val menu = all.filter { it.id != TUTORIAL_ID }

    /** Las estrellas de la barra solo cuentan los niveles de la lista. */
    val maxStars = menu.size * 3
}
