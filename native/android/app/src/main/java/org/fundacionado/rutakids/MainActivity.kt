package org.fundacionado.rutakids

import android.os.Build
import android.os.Bundle
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import androidx.activity.viewModels
import androidx.compose.ui.platform.ComposeView
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import kotlinx.coroutines.launch
import org.fundacionado.rutakids.bridge.BridgeViewModel
import org.godotengine.godot.Godot
import org.godotengine.godot.GodotFragment
import org.godotengine.godot.GodotHost
import org.godotengine.godot.plugin.GodotPlugin
import org.fundacionado.rutakids.ui.RutaKidsApp

/**
 * Solo junta las dos capas: Godot abajo y el menú de Compose arriba.
 * Godot arranca una sola vez, escondido, y nunca se destruye entre niveles (H1).
 * Toda la lógica del puente está en BridgeViewModel; las pantallas están en ui/.
 */
class MainActivity : FragmentActivity(), GodotHost {

    private val vm: BridgeViewModel by viewModels()
    private var godotFragment: GodotFragment? = null
    private lateinit var menu: ComposeView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val root = FrameLayout(this)
        val godotContainer = FrameLayout(this).apply { id = View.generateViewId() }
        menu = ComposeView(this).apply { setContent { RutaKidsApp(vm) } }
        root.addView(godotContainer)
        root.addView(menu)
        setContentView(root)
        enterImmersiveMode()

        godotFragment = supportFragmentManager.findFragmentById(godotContainer.id) as? GodotFragment
        if (godotFragment == null) {
            godotFragment = GodotFragment()
            supportFragmentManager.beginTransaction().replace(godotContainer.id, godotFragment!!).commitNow()
        }

        // El menú se esconde mientras se ve un nivel y regresa con level_exited.
        // Con Tutores abierto desde el nivel (tutor_requested), el menú va encima del nivel pausado.
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                vm.state.collect {
                    val hideMenu = it.levelVisible && !it.tutorsOverLevel
                    menu.visibility = if (hideMenu) View.GONE else View.VISIBLE
                }
            }
        }
    }

    // Pantalla completa: sin barra de estado ni de navegación (con targetSdk 35+ Android dibuja
    // de borde a borde y la barra tapaba el engrane). Un deslizamiento desde el borde las muestra
    // un momento; al regresar el foco se vuelven a esconder.
    private fun enterImmersiveMode() {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
        WindowInsetsControllerCompat(window, window.decorView).apply {
            hide(WindowInsetsCompat.Type.systemBars())
            systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) enterImmersiveMode()
    }

    // Cuenta cada toque real en toda la app (menús y nivel) para el kiosco de 60 s.
    override fun dispatchTouchEvent(ev: MotionEvent): Boolean {
        if (ev.actionMasked == MotionEvent.ACTION_DOWN) vm.onUserTouch()
        return super.dispatchTouchEvent(ev)
    }

    // Con el nivel abierto la vista de Godot tiene el foco y se come la tecla Atrás
    // (Android 13–15 y anteriores). Se manda siempre al OnBackPressedDispatcher para que
    // decidan los BackHandler de RutaKidsApp (cerrar el nivel, o nada en kiosco).
    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.keyCode == KeyEvent.KEYCODE_BACK) {
            if (event.action == KeyEvent.ACTION_UP && !event.isCanceled) onBackPressedDispatcher.onBackPressed()
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    // --- GodotHost ---

    override fun getActivity() = this

    override fun getGodot(): Godot? = godotFragment?.godot

    override fun getHostPlugins(engine: Godot): Set<GodotPlugin> {
        val plugin = RutaBridgePlugin(engine, vm::onBridgeMessage)
        vm.attach(plugin)
        return setOf(plugin)
    }

    // --- Segundo plano (plan, sección 5.1; Ángel lo termina en la tarea 20) ---

    override fun onPause() {
        super.onPause()
        vm.pauseLevel()
    }

    override fun onResume() {
        super.onResume()
        vm.resumeLevel()
    }
}
