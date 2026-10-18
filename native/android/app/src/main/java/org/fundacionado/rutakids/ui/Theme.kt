package org.fundacionado.rutakids.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color

/** Paleta de ADO (CLAUDE.md, "Paleta de colores"). No escribir colores sueltos en las pantallas. */
object Palette {
    val AdoRed = Color(0xFFDD2835)
    val DarkPurple = Color(0xFF3F1B4E)
    val Gold = Color(0xFFFFC700)
    val White = Color(0xFFFFFFFF)
    val SkyTop = Color(0xFF4A235A)
    val SkyMiddle = Color(0xFF9C4B79)
    val SkyBottom = Color(0xFFE86F56)
    val Outline = Color(0xFF1E0F26)
    val Asphalt = Color(0xFF534A5E)

    /** Fondo de los menús mientras llega el arte del prompt #19. */
    val Sky = Brush.verticalGradient(listOf(SkyTop, SkyMiddle, SkyBottom))
}

@Composable
fun RutaKidsTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = darkColorScheme(
            primary = Palette.Gold,
            onPrimary = Palette.Outline,
            secondary = Palette.AdoRed,
            background = Palette.DarkPurple,
            surface = Palette.DarkPurple,
            onSurface = Palette.White,
        ),
        content = content,
    )
}
