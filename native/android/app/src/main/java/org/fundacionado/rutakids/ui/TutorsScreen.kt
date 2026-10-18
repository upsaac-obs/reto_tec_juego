package org.fundacionado.rutakids.ui

import android.content.res.Resources
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.fundacionado.rutakids.R
import org.fundacionado.rutakids.data.Levels
import org.fundacionado.rutakids.data.Progress
import org.fundacionado.rutakids.data.SettingsStore

/**
 * Tutores (diseño de Paulo, conectado al guardado): estrellas por hábito, faltas por regla,
 * cambiar el modo, activar el kiosco y borrar el progreso con confirmación.
 * Se abre manteniendo el engrane 3 s en Inicio, o desde un nivel con tutor_requested.
 */
@Composable
fun TutorsScreen(
    progress: Progress,
    mode: String?,
    kiosk: Boolean,
    onModeChange: (String) -> Unit,
    onKioskChange: (Boolean) -> Unit,
    onResetProgress: () -> Unit,
    onBack: () -> Unit,
) {
    var confirmReset by remember { mutableStateOf(false) }
    val resources = LocalContext.current.resources

    MenuBackground {
        Column(Modifier.fillMaxSize().padding(20.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                ImageButton(R.drawable.btn_exit, stringResource(R.string.MENU_REGRESAR), onBack, Modifier.size(56.dp))
                Spacer(Modifier.width(16.dp))
                Surface(shape = RoundedCornerShape(20.dp), color = Palette.DarkPurple) {
                    Text(
                        stringResource(R.string.TUTOR_TITULO),
                        color = Palette.Gold,
                        fontSize = 22.sp,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(horizontal = 20.dp, vertical = 10.dp),
                    )
                }
            }
            Spacer(Modifier.height(16.dp))

            LazyColumn(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                item {
                    TutorCard {
                        CardTitle(stringResource(R.string.TUTOR_AJUSTES))
                        Row(
                            Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(stringResource(R.string.TUTOR_MODO), color = Palette.Outline, fontSize = 15.sp)
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                ModeButton(stringResource(R.string.MENU_PEQUE), mode == SettingsStore.MODE_PEQUE) {
                                    onModeChange(SettingsStore.MODE_PEQUE)
                                }
                                ModeButton(stringResource(R.string.MENU_GRANDE), mode == SettingsStore.MODE_GRANDE) {
                                    onModeChange(SettingsStore.MODE_GRANDE)
                                }
                            }
                        }
                        Row(
                            Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Column(Modifier.weight(1f)) {
                                Text(stringResource(R.string.MENU_KIOSCO), color = Palette.Outline, fontSize = 15.sp)
                                Text(stringResource(R.string.TUTOR_KIOSCO_AYUDA), color = Palette.Asphalt, fontSize = 12.sp)
                            }
                            Switch(
                                checked = kiosk,
                                onCheckedChange = onKioskChange,
                                colors = SwitchDefaults.colors(
                                    checkedThumbColor = Palette.Gold,
                                    checkedTrackColor = Palette.DarkPurple,
                                ),
                            )
                        }
                    }
                }

                item {
                    TutorCard {
                        CardTitle(stringResource(R.string.TUTOR_PROGRESO))
                        Text(
                            "${progress.totalStars} / ${Levels.maxStars} ★",
                            color = Palette.Outline,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold,
                        )
                    }
                }

                items(Levels.all, key = { it.id }) { level ->
                    val stars = progress.starsFor(level.id)
                    val infractions = progress.infractions[level.id].orEmpty()
                    TutorCard {
                        Row(
                            Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Column(Modifier.weight(1f)) {
                                Text(
                                    "${level.id}. ${stringResource(level.nameRes)}",
                                    color = Palette.DarkPurple,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 15.sp,
                                )
                                if (stars > 0) {
                                    Text(
                                        if (infractions.isEmpty()) stringResource(R.string.TUTOR_SIN_FALTAS)
                                        else infractions.entries.joinToString { (rule, n) -> "${ruleName(resources, rule)}: $n" },
                                        color = Palette.Asphalt,
                                        fontSize = 12.sp,
                                    )
                                }
                            }
                            if (stars > 0) StarsRow(stars, Modifier.height(28.dp))
                            else Text("—", color = Palette.Asphalt)
                        }
                    }
                }

                item {
                    Button(
                        onClick = { confirmReset = true },
                        colors = ButtonDefaults.buttonColors(containerColor = Palette.AdoRed),
                        shape = RoundedCornerShape(16.dp),
                        modifier = Modifier.fillMaxWidth().height(50.dp),
                    ) {
                        Text(stringResource(R.string.MENU_BORRAR_PROGRESO), fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Palette.White)
                    }
                }
            }
        }

        if (confirmReset) {
            AlertDialog(
                onDismissRequest = { confirmReset = false },
                title = { Text(stringResource(R.string.TUTOR_BORRAR_TITULO)) },
                text = { Text(stringResource(R.string.TUTOR_BORRAR_TEXTO)) },
                confirmButton = {
                    TextButton(onClick = { onResetProgress(); confirmReset = false }) {
                        Text(stringResource(R.string.TUTOR_BORRAR_SI), color = Palette.AdoRed, fontWeight = FontWeight.Bold)
                    }
                },
                dismissButton = {
                    TextButton(onClick = { confirmReset = false }) {
                        Text(stringResource(R.string.TUTOR_CANCELAR))
                    }
                },
            )
        }
    }
}

@Composable
private fun TutorCard(content: @Composable () -> Unit) {
    Card(
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = Palette.White.copy(alpha = 0.93f)),
    ) {
        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) { content() }
    }
}

@Composable
private fun CardTitle(text: String) {
    Text(text, color = Palette.DarkPurple, fontSize = 17.sp, fontWeight = FontWeight.Bold)
}

@Composable
private fun ModeButton(label: String, selected: Boolean, onClick: () -> Unit) {
    if (selected) {
        Button(onClick = onClick, colors = ButtonDefaults.buttonColors(containerColor = Palette.DarkPurple)) {
            Text(label, color = Palette.Gold, fontWeight = FontWeight.Bold)
        }
    } else {
        OutlinedButton(onClick = onClick) { Text(label, color = Palette.DarkPurple) }
    }
}

/** Nombre corto de cada rule_id del RuleManager (docs/arquitectura.md, sección 3). */
private fun ruleName(res: Resources, ruleId: String): String = when (ruleId) {
    "stop" -> res.getString(R.string.REGLA_STOP)
    "red_light" -> res.getString(R.string.REGLA_RED_LIGHT)
    "speed" -> res.getString(R.string.REGLA_SPEED)
    "crosswalk" -> res.getString(R.string.REGLA_CROSSWALK)
    "bike_lane" -> res.getString(R.string.REGLA_BIKE_LANE)
    "look" -> res.getString(R.string.REGLA_LOOK)
    "patience" -> res.getString(R.string.REGLA_PATIENCE)
    "yellow" -> res.getString(R.string.REGLA_YELLOW)
    "phone" -> res.getString(R.string.REGLA_PHONE)
    "lights" -> res.getString(R.string.REGLA_LIGHTS)
    "distance" -> res.getString(R.string.REGLA_DISTANCE)
    "ambulance" -> res.getString(R.string.REGLA_AMBULANCE)
    "crash" -> res.getString(R.string.REGLA_CRASH)
    else -> ruleId
}
