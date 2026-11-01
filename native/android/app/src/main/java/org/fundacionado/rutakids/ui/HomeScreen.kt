package org.fundacionado.rutakids.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.fundacionado.rutakids.R

/**
 * Inicio (diseño del mockup de Paulo): Salir arriba a la izquierda, barra de estrellas,
 * sonido y engrane de tutores arriba a la derecha, y el botón grande Jugar al centro.
 * Tiene que verse en menos de 3 s; Godot arranca escondido detrás.
 */
@Composable
fun HomeScreen(
    totalStars: Int,
    maxStars: Int,
    muted: Boolean,
    kiosk: Boolean,
    onPlay: () -> Unit,
    onExit: () -> Unit,
    onToggleSound: () -> Unit,
    onOpenTutors: () -> Unit,
) {
    MenuBackground {
        Row(
            Modifier.fillMaxWidth().padding(20.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            // En kiosco no hay Salir (plan, sección 5.1).
            if (!kiosk) {
                ImageButton(R.drawable.btn_exit, stringResource(R.string.MENU_SALIR), onExit, Modifier.size(60.dp))
            } else {
                Box(Modifier.size(60.dp))
            }
            StarsBanner(totalStars, maxStars)
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                RoundButton(stringResource(R.string.MENU_SONIDO), onToggleSound) {
                    // Provisional hasta tener el ícono de sonido.
                    Text(if (muted) "🔇" else "🔊", fontSize = 24.sp)
                }
                TutorGear(onOpen = onOpenTutors)
            }
        }

        ImageButton(
            R.drawable.btn_start,
            stringResource(R.string.MENU_JUGAR),
            onPlay,
            Modifier.align(Alignment.Center).size(220.dp),
        )
    }
}
