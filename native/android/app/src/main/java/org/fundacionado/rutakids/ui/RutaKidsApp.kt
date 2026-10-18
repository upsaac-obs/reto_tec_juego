package org.fundacionado.rutakids.ui

import android.app.Activity
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import org.fundacionado.rutakids.bridge.BridgeViewModel
import org.fundacionado.rutakids.data.Levels
import org.fundacionado.rutakids.data.Progress

/** Rutas de la navegación. Las pantallas nuevas se agregan aquí. */
object Routes {
    const val HOME = "inicio"
    const val AGE_SELECT = "edad"
    const val LEVEL_SELECT = "niveles"
    const val TUTORS = "tutores"
}

/**
 * Menú nativo completo. La vista de Godot no es una ruta: MainActivity la muestra
 * cuando GodotState.levelVisible es true y la esconde con level_exited.
 * Si llega tutor_requested, Tutores se dibuja encima del nivel pausado.
 */
@Composable
fun RutaKidsApp(vm: BridgeViewModel) {
    val nav = rememberNavController()
    val scope = rememberCoroutineScope()
    val activity = LocalContext.current as? Activity
    val godot by vm.state.collectAsState()
    val muted by vm.settings.muted.collectAsState(initial = false)
    val kiosk by vm.settings.kiosk.collectAsState(initial = false)
    val mode by vm.settings.mode.collectAsState(initial = null)
    val progress by vm.settings.progress.collectAsState(initial = Progress())

    val tutors = @Composable { onBack: () -> Unit ->
        TutorsScreen(
            progress = progress,
            mode = mode,
            kiosk = kiosk,
            onModeChange = vm::setMode,
            onKioskChange = vm::setKiosk,
            onResetProgress = vm::resetProgress,
            onBack = onBack,
        )
    }

    RutaKidsTheme {
        Box(Modifier.fillMaxSize()) {
            NavHost(navController = nav, startDestination = Routes.HOME) {
                composable(Routes.HOME) {
                    HomeScreen(
                        totalStars = progress.totalStars,
                        maxStars = Levels.maxStars,
                        muted = muted,
                        kiosk = kiosk,
                        onPlay = {
                            scope.launch {
                                // Primera vez (sin modo guardado): Selección de edad. Después: directo a los niveles.
                                val saved = vm.settings.mode.first()
                                nav.navigate(if (saved == null) Routes.AGE_SELECT else Routes.LEVEL_SELECT)
                            }
                        },
                        onExit = { activity?.finish() },
                        onToggleSound = { vm.setMuted(!muted) },
                        onOpenTutors = { nav.navigate(Routes.TUTORS) },
                    )
                }
                composable(Routes.AGE_SELECT) {
                    AgeSelectScreen(onModeSelected = { selected ->
                        scope.launch {
                            vm.settings.saveMode(selected)
                            // Quita Edad de la pila: al regresar desde Niveles se vuelve a Inicio.
                            nav.navigate(Routes.LEVEL_SELECT) { popUpTo(Routes.AGE_SELECT) { inclusive = true } }
                        }
                    })
                }
                composable(Routes.LEVEL_SELECT) {
                    LevelSelectScreen(
                        godot = godot,
                        progress = progress,
                        kiosk = kiosk,
                        onLevelSelected = vm::startLevel,
                        onBack = { nav.popBackStack() },
                    )
                }
                composable(Routes.TUTORS) {
                    tutors { nav.popBackStack() }
                }
            }

            // Tutores encima del nivel pausado (tutor_requested). Al cerrar, el nivel sigue.
            if (godot.tutorsOverLevel) {
                tutors { vm.closeTutorsOverLevel() }
            }
        }

        // Van después del NavHost para que ganen sobre su "atrás".
        // Con un nivel abierto, "atrás" cierra el nivel; con Tutores encima, cierra Tutores.
        BackHandler(enabled = godot.requestedLevel != null && !godot.tutorsOverLevel) { vm.abortLevel() }
        BackHandler(enabled = godot.tutorsOverLevel) { vm.closeTutorsOverLevel() }
    }
}
