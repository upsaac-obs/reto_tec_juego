package org.fundacionado.rutakids.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.fundacionado.rutakids.R
import org.fundacionado.rutakids.data.SettingsStore

/**
 * Selección de edad: solo sale la primera vez. Un toque elige el modo y se guarda.
 * Dos tarjetas grandes con degradado (como iOS); los dibujos llegan con el prompt #20.
 */
@Composable
fun AgeSelectScreen(onModeSelected: (String) -> Unit) {
    MenuBackground {
        Column(
            Modifier.fillMaxSize().padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Text(
                stringResource(R.string.MENU_EDAD_TITULO),
                color = Palette.White,
                fontSize = 32.sp,
                fontWeight = FontWeight.Black,
                style = TextStyle(shadow = Shadow(Color.Black.copy(alpha = 0.4f), Offset(0f, 4f), 6f)),
            )
            Spacer(Modifier.height(24.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(28.dp)) {
                AgeCard(
                    emoji = "🙂",
                    title = stringResource(R.string.MENU_PEQUE),
                    ages = stringResource(R.string.MENU_PEQUE_EDADES),
                    onClick = { onModeSelected(SettingsStore.MODE_PEQUE) },
                )
                AgeCard(
                    emoji = "🎮",
                    title = stringResource(R.string.MENU_GRANDE),
                    ages = stringResource(R.string.MENU_GRANDE_EDADES),
                    onClick = { onModeSelected(SettingsStore.MODE_GRANDE) },
                )
            }
        }
    }
}

/** Tarjeta con degradado morado y borde rojo, como en iOS. El emoji es provisional hasta tener el dibujo. */
@Composable
private fun AgeCard(
    emoji: String,
    title: String,
    ages: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val shape = RoundedCornerShape(28.dp)
    Column(
        modifier
            .width(240.dp)
            .shadow(8.dp, shape)
            .clip(shape)
            .background(Palette.Card)
            .border(4.dp, Palette.AdoRed, shape)
            .pressClickable(onClick = onClick)
            .padding(20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(emoji, fontSize = 64.sp)
        Text(title, color = Palette.White, fontSize = 26.sp, fontWeight = FontWeight.Black)
        Text(ages, color = Palette.White.copy(alpha = 0.8f), fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
    }
}
