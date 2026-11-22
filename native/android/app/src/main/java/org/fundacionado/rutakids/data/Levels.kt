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
)

object Levels {
    val all = listOf(
        LevelInfo(0, R.string.NIVEL_00_NOMBRE),
        LevelInfo(1, R.string.NIVEL_01_NOMBRE),
        LevelInfo(2, R.string.NIVEL_02_NOMBRE),
        LevelInfo(3, R.string.NIVEL_03_NOMBRE),
        LevelInfo(4, R.string.NIVEL_04_NOMBRE),
        LevelInfo(5, R.string.NIVEL_05_NOMBRE),
        LevelInfo(6, R.string.NIVEL_06_NOMBRE),
        LevelInfo(7, R.string.NIVEL_07_NOMBRE),
        LevelInfo(8, R.string.NIVEL_08_NOMBRE),
    )

    /** El 0 es el tutorial: se abre solo la primera vez que se toca Jugar (fuera del kiosco). */
    const val TUTORIAL_ID = 0

    /** Tarjetas de la lista de niveles y de Tutores (igual que iOS: del 1 al 8). */
    val menu = all.filter { it.id != TUTORIAL_ID }

    /** Las estrellas de la barra solo cuentan los niveles de la lista. */
    val maxStars = menu.size * 3
}
