package org.fundacionado.rutakids.data

import androidx.annotation.DrawableRes
import androidx.annotation.StringRes
import org.fundacionado.rutakids.R

/**
 * Niveles de la entrega: del 0 al 8 (docs/plan_cierre.md). El id es el level_id del juego
 * (data/level_XX.tres), así que no se puede reordenar: el 0 siempre abre "Abróchate y arranca".
 */
data class LevelInfo(
    val id: Int,
    @StringRes val nameRes: Int,
    /** Dibujo de la tarjeta. Null mientras no haya arte: se dibuja una tarjeta lisa con el número. */
    @DrawableRes val iconRes: Int?,
)

object Levels {
    val all = listOf(
        LevelInfo(0, R.string.NIVEL_00_NOMBRE, R.drawable.icon_seatbelt),
        LevelInfo(1, R.string.NIVEL_01_NOMBRE, R.drawable.icon_crosswalk),
        LevelInfo(2, R.string.NIVEL_02_NOMBRE, R.drawable.icon_stop),
        LevelInfo(3, R.string.NIVEL_03_NOMBRE, R.drawable.icon_look_both_ways),
        LevelInfo(4, R.string.NIVEL_04_NOMBRE, R.drawable.icon_pedestrian_light),
        LevelInfo(5, R.string.NIVEL_05_NOMBRE, R.drawable.icon_speed_limit),
        LevelInfo(6, R.string.NIVEL_06_NOMBRE, null),
        LevelInfo(7, R.string.NIVEL_07_NOMBRE, null),
        LevelInfo(8, R.string.NIVEL_08_NOMBRE, R.drawable.icon_bike),
    )

    /** El 0 es el tutorial: se abre solo la primera vez que se toca Jugar (fuera del kiosco). */
    const val TUTORIAL_ID = 0

    /** Tarjetas de la lista de niveles y de Tutores (igual que iOS: del 1 al 8). */
    val menu = all.filter { it.id != TUTORIAL_ID }

    /** Las estrellas de la barra solo cuentan los niveles de la lista. */
    val maxStars = menu.size * 3
}
