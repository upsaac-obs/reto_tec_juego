package org.fundacionado.rutakids.ui

import android.app.Activity
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import org.fundacionado.rutakids.bridge.BridgeViewModel
import org.fundacionado.rutakids.bridge.MenuCommand
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
    val kiosk by vm.kiosk.collectAsState()
    val mode by vm.settings.mode.collectAsState(initial = null)
    val progress by vm.settings.progress.collectAsState(initial = Progress())

    val tutors = @Composable { onBack: () -> Unit ->
        TutorsScreen(
            progress = progress,
            mode = mode,
            kiosk = kiosk,
            onModeChange = vm::setMode,
            onKioskChange = { on ->
                vm.setKiosk(on)
                activity?.setScreenPinned(on)
            },
            onResetProgress = vm::resetProgress,
            onBack = onBack,
        )
    }

    val route = nav.currentBackStackEntryAsState().value?.destination?.route
    val inLevel = godot.requestedLevel != null

    // Primera vez sin modo guardado: Selección de edad. Después: el tutorial (si toca) o la lista.
    val openLevelsOrTutorial: suspend () -> Unit = {
        if (vm.playTutorialIfNeeded()) nav.popBackStack(Routes.HOME, inclusive = false)
        else nav.navigate(Routes.LEVEL_SELECT) { popUpTo(Routes.HOME) }
    }

    LaunchedEffect(nav) {
        vm.commands.collect { command ->
            when (command) {
                MenuCommand.GoHome -> nav.popBackStack(Routes.HOME, inclusive = false)
                MenuCommand.OpenLevels -> if (nav.currentDestination?.route != Routes.LEVEL_SELECT) {
                    nav.navigate(Routes.LEVEL_SELECT) { popUpTo(Routes.HOME); launchSingleTop = true }
                }
            }
        }
    }

    // Kiosco: 60 s sin tocar en los menús → Inicio. Se pausa con un nivel abierto (ahí cuenta Godot)
    // y en Tutores (igual que iOS); al volver a contar se empieza de cero.
    LaunchedEffect(kiosk, inLevel, route) {
        if (!kiosk || inLevel || route == Routes.TUTORS || route == Routes.HOME) return@LaunchedEffect
        vm.onUserTouch()
        while (true) {
            delay(KIOSK_IDLE_CHECK_MS)
            if (vm.idleMs() >= KIOSK_IDLE_TIMEOUT_MS) {
                vm.goHome()
                break
            }
        }
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
                                if (vm.settings.mode.first() == null) nav.navigate(Routes.AGE_SELECT)
                                else openLevelsOrTutorial()
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
                            // Edad sale de la pila: al regresar desde Niveles (o del tutorial) se vuelve a Inicio.
                            openLevelsOrTutorial()
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
        // En kiosco no hay Salir: "atrás" no cierra el nivel ni la app desde Inicio.
        BackHandler(enabled = inLevel && !godot.tutorsOverLevel && !kiosk) { vm.abortLevel() }
        BackHandler(enabled = kiosk && !godot.tutorsOverLevel && (inLevel || route == Routes.HOME)) { }
        BackHandler(enabled = godot.tutorsOverLevel) { vm.closeTutorsOverLevel() }
    }
}
