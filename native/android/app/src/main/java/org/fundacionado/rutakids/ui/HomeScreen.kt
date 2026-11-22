// Creación y desarrollo: José Paulo Vélez Ortiz, Dylan Isaac Mancilla López
package org.fundacionado.rutakids.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import org.fundacionado.rutakids.R

/**
 * Inicio: fondo postal de Puebla (bg_home, con el auto y el copiloto saludando), Salir arriba a
 * la izquierda, estrellas al centro, sonido y engrane de Tutores a la derecha, y el botón
 * grande de Jugar en el centro libre del fondo. Tiene que verse en menos de 3 s; Godot
 * arranca escondido detrás.
 */
@Composable
fun HomeScreen(
    totalStars: Int,
    maxStars: Int,
    muted: Boolean,
    kiosk: Boolean,
    /** Godot sigue arrancando: Jugar ya funciona, pero se avisa que el nivel tardará un momento. */
    loading: Boolean,
    onPlay: () -> Unit,
    onExit: () -> Unit,
    onToggleSound: () -> Unit,
    onOpenTutors: () -> Unit,
) {
    MenuBackground(R.drawable.bg_home) {
        Row(
            Modifier.fillMaxWidth().padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            // En kiosco no hay Salir (plan, sección 5.1).
            if (!kiosk) {
                ImageButton(R.drawable.btn_exit, stringResource(R.string.MENU_SALIR), onExit, Modifier.size(CornerButtonSize))
            } else {
                Box(Modifier.size(CornerButtonSize))
            }
            StarsBanner(totalStars, maxStars)
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                SoundButton(muted, onToggleSound)
                TutorGear(onOpen = onOpenTutors)
            }
        }

        ImageButton(
            R.drawable.btn_play,
            stringResource(R.string.MENU_JUGAR),
            onPlay,
            Modifier.align(Alignment.Center).padding(top = 24.dp).size(170.dp),
        )
        if (loading) {
            LoadingChip(Modifier.align(Alignment.BottomCenter).padding(bottom = 28.dp))
        }
    }
}
