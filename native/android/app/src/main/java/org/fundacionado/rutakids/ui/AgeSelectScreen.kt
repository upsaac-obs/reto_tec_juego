package org.fundacionado.rutakids.ui

import androidx.annotation.DrawableRes
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.fundacionado.rutakids.R
import org.fundacionado.rutakids.data.SettingsStore

/**
 * Selección de edad: solo sale la primera vez. Un toque elige el modo y se guarda.
 * Cada tarjeta es la ilustración del lote 10 (age_peque, age_grande) con el texto debajo.
 */
@Composable
fun AgeSelectScreen(onModeSelected: (String) -> Unit) {
    MenuBackground {
        Column(
            Modifier.fillMaxSize().padding(horizontal = 24.dp, vertical = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(
                stringResource(R.string.MENU_EDAD_TITULO),
                color = Palette.White,
                fontSize = 34.sp,
                fontWeight = FontWeight.Bold,
            )
            Row(
                Modifier.weight(1f).padding(horizontal = 32.dp),
                horizontalArrangement = Arrangement.spacedBy(36.dp, Alignment.CenterHorizontally),
            ) {
                AgeCard(
                    image = R.drawable.age_peque,
                    title = stringResource(R.string.MENU_PEQUE),
                    ages = stringResource(R.string.MENU_PEQUE_EDADES),
                    onClick = { onModeSelected(SettingsStore.MODE_PEQUE) },
                )
                AgeCard(
                    image = R.drawable.age_grande,
                    title = stringResource(R.string.MENU_GRANDE),
                    ages = stringResource(R.string.MENU_GRANDE_EDADES),
                    onClick = { onModeSelected(SettingsStore.MODE_GRANDE) },
                )
            }
        }
    }
}

@Composable
private fun AgeCard(
    @DrawableRes image: Int,
    title: String,
    ages: String,
    onClick: () -> Unit,
) {
    val shape = RoundedCornerShape(28.dp)
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val audio = LocalMenuAudio.current
    Column(
        Modifier
            .fillMaxHeight()
            .aspectRatio(0.82f)
            .scale(if (pressed) 0.96f else 1f)
            .clip(shape)
            .background(Palette.DarkPurple)
            .border(5.dp, Palette.Gold, shape)
            .clickable(interactionSource = interaction, indication = null) {
                audio?.tap()
                onClick()
            }
            .semantics { role = Role.Button; contentDescription = "$title, $ages" }
            .padding(10.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Image(
            painterResource(image),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.fillMaxWidth().weight(1f).clip(RoundedCornerShape(20.dp)),
        )
        Text(title, color = Palette.Gold, fontSize = 34.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(top = 4.dp))
        Text(ages, color = Palette.White, fontSize = 18.sp)
    }
}
