package org.fundacionado.rutakids.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.ExperimentalTextApi
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontVariation
import androidx.compose.ui.text.font.FontWeight
import org.fundacionado.rutakids.R

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
    /** Pasto del mapa (plan visual): rellena alrededor del mapa si la pantalla es más ancha. */
    val Grass = Color(0xFF5E9A5A)

    val Sky = Brush.verticalGradient(listOf(SkyTop, SkyMiddle, SkyBottom))
}

/**
 * Fredoka (OFL, res/font/fredoka.ttf; licencia en assets/fredoka_OFL.txt), la misma fuente
 * de los niveles. Es variable: cada peso pide su grosor (Android 8+; antes sale Regular).
 */
@OptIn(ExperimentalTextApi::class)
val Fredoka = FontFamily(
    listOf(FontWeight.Normal to 500, FontWeight.Medium to 550, FontWeight.SemiBold to 600,
        FontWeight.Bold to 650, FontWeight.ExtraBold to 700, FontWeight.Black to 700).map { (weight, axis) ->
        Font(R.font.fredoka, weight, variationSettings = FontVariation.Settings(FontVariation.weight(axis)))
    },
)

private fun TextStyle.fredoka() = copy(fontFamily = Fredoka)

private val FredokaTypography = Typography().run {
    Typography(
        displayLarge = displayLarge.fredoka(), displayMedium = displayMedium.fredoka(), displaySmall = displaySmall.fredoka(),
        headlineLarge = headlineLarge.fredoka(), headlineMedium = headlineMedium.fredoka(), headlineSmall = headlineSmall.fredoka(),
        titleLarge = titleLarge.fredoka(), titleMedium = titleMedium.fredoka(), titleSmall = titleSmall.fredoka(),
        bodyLarge = bodyLarge.fredoka(), bodyMedium = bodyMedium.fredoka(), bodySmall = bodySmall.fredoka(),
        labelLarge = labelLarge.fredoka(), labelMedium = labelMedium.fredoka(), labelSmall = labelSmall.fredoka(),
    )
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
        typography = FredokaTypography,
        content = content,
    )
}
