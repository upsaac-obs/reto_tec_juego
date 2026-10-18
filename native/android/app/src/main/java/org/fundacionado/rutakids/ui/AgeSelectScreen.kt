package org.fundacionado.rutakids.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.fundacionado.rutakids.R
import org.fundacionado.rutakids.data.SettingsStore

/**
 * Selección de edad: solo sale la primera vez. Un toque elige el modo y se guarda.
 * Los dibujos grandes llegan con el prompt #20; mientras, tarjetas de color.
 */
@Composable
fun AgeSelectScreen(onModeSelected: (String) -> Unit) {
    MenuBackground {
        Column(
            Modifier.fillMaxSize().padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(24.dp),
        ) {
            Text(
                stringResource(R.string.MENU_EDAD_TITULO),
                color = Palette.White,
                fontSize = 36.sp,
                fontWeight = FontWeight.Bold,
            )
            Row(
                Modifier.weight(1f).padding(horizontal = 48.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(32.dp),
            ) {
                AgeCard(
                    title = stringResource(R.string.MENU_PEQUE),
                    ages = stringResource(R.string.MENU_PEQUE_EDADES),
                    color = Palette.DarkPurple,
                    textColor = Palette.Gold,
                    onClick = { onModeSelected(SettingsStore.MODE_PEQUE) },
                    modifier = Modifier.weight(1f),
                )
                AgeCard(
                    title = stringResource(R.string.MENU_GRANDE),
                    ages = stringResource(R.string.MENU_GRANDE_EDADES),
                    color = Palette.DarkPurple,
                    textColor = Palette.Gold,
                    onClick = { onModeSelected(SettingsStore.MODE_GRANDE) },
                    modifier = Modifier.weight(1f),
                )
            }
        }
    }
}

@Composable
private fun AgeCard(
    title: String,
    ages: String,
    color: Color,
    textColor: Color,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val shape = RoundedCornerShape(32.dp)
    Column(
        modifier
            .fillMaxHeight()
            .clip(shape)
            .background(color)
            .border(5.dp, Palette.AdoRed, shape)
            .clickable(onClick = onClick)
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(title, color = textColor, fontSize = 48.sp, fontWeight = FontWeight.Black)
        Text(ages, color = Palette.White, fontSize = 24.sp)
    }
}
