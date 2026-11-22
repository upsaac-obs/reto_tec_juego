// Creación y desarrollo: Dylan Isaac Mancilla López, José Paulo Vélez Ortiz
package org.fundacionado.rutakids.ui

import androidx.annotation.DrawableRes
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.waitForUpOrCancellation
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.displayCutout
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import org.fundacionado.rutakids.R

/** Tamaño de los botones redondos de las esquinas (Regresar, Salir, sonido, Tutores). */
val CornerButtonSize = 58.dp

/**
 * Fondo de los menús (lote 10 de Codex: bg_menus o bg_home) con el contenido encima. El fondo
 * llena toda la pantalla; los botones se apartan de la cámara (notch) para que no queden tapados.
 */
@Composable
fun MenuBackground(
    @DrawableRes background: Int = R.drawable.bg_menus,
    content: @Composable BoxScope.() -> Unit,
) {
    Box(Modifier.fillMaxSize().background(Palette.DarkPurple)) {
        Image(
            painterResource(background),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.fillMaxSize(),
        )
        Box(Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.displayCutout), content = content)
    }
}

/** Botón que es solo una imagen (los botones "caramelo" del lote 10). Rebota al tocarlo. */
@Composable
fun ImageButton(
    @DrawableRes image: Int,
    label: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val audio = LocalMenuAudio.current
    Image(
        painterResource(image),
        contentDescription = label,
        contentScale = ContentScale.Fit,
        modifier = modifier
            .pressClickable {
                audio?.tap()
                onClick()
            }
            .semantics { role = Role.Button },
    )
}

/**
 * Como un clic normal, pero el botón se encoge un poco al pulsarlo y rebota al soltar
 * (el ScaleButtonStyle de iOS). Sin la onda gris de Material. (De Paulo, feature/ui-android.)
 */
fun Modifier.pressClickable(enabled: Boolean = true, onClick: () -> Unit): Modifier = composed {
    val source = remember { MutableInteractionSource() }
    val pressed by source.collectIsPressedAsState()
    val scale by animateFloatAsState(
        targetValue = if (pressed) 0.93f else 1f,
        animationSpec = spring(dampingRatio = 0.6f, stiffness = Spring.StiffnessMedium),
        label = "pressScale",
    )
    this
        .graphicsLayer { scaleX = scale; scaleY = scale }
        .clickable(interactionSource = source, indication = null, enabled = enabled, onClick = onClick)
}

/** Cápsula morada con "Cargando…" mientras Godot arranca en segundo plano (como iOS). (De Paulo.) */
@Composable
fun LoadingChip(modifier: Modifier = Modifier) {
    Row(
        modifier
            .clip(RoundedCornerShape(50))
            .background(Palette.DarkPurple.copy(alpha = 0.85f))
            .padding(horizontal = 14.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        CircularProgressIndicator(color = Palette.Gold, strokeWidth = 2.dp, modifier = Modifier.size(16.dp))
        Spacer(Modifier.width(8.dp))
        Text(stringResource(R.string.MENU_CARGANDO), color = Palette.White, fontSize = 14.sp, fontWeight = FontWeight.Bold)
    }
}

/** Barra con el total de estrellas: estrella dorada y "total / máximo" en Fredoka. */
@Composable
fun StarsBanner(total: Int, max: Int, modifier: Modifier = Modifier) {
    Surface(
        shape = RoundedCornerShape(24.dp),
        color = Palette.DarkPurple.copy(alpha = 0.88f),
        contentColor = Palette.White,
        modifier = modifier,
    ) {
        Row(
            Modifier.padding(start = 8.dp, end = 18.dp, top = 4.dp, bottom = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Image(painterResource(R.drawable.star_full), contentDescription = null, modifier = Modifier.size(34.dp))
            Spacer(Modifier.width(8.dp))
            Text("$total / $max", fontWeight = FontWeight.Bold, fontSize = 22.sp, color = Palette.Gold)
        }
    }
}

/** Bocina con ondas o tachada, según [muted]. */
@Composable
fun SoundButton(muted: Boolean, onToggle: () -> Unit, modifier: Modifier = Modifier) {
    ImageButton(
        if (muted) R.drawable.btn_sound_off else R.drawable.btn_sound_on,
        stringResource(R.string.MENU_SONIDO),
        onToggle,
        modifier.size(CornerButtonSize),
    )
}

/**
 * Engrane de Tutores: se abre solo manteniéndolo presionado [holdMillis] (plan, sección 5.1),
 * para que los niños no entren con un toque. Mientras se mantiene, se llena un aro dorado.
 */
@Composable
fun TutorGear(onOpen: () -> Unit, modifier: Modifier = Modifier, holdMillis: Int = 3000, size: Dp = CornerButtonSize) {
    val progress = remember { Animatable(0f) }
    val scope = rememberCoroutineScope()
    val currentOnOpen = rememberUpdatedState(onOpen)
    val label = stringResource(R.string.MENU_TUTORES)
    Box(
        modifier
            .size(size)
            .semantics { contentDescription = label }
            .pointerInput(holdMillis) {
                awaitEachGesture {
                    awaitFirstDown()
                    val fill = scope.launch {
                        progress.snapTo(0f)
                        progress.animateTo(1f, tween(holdMillis, easing = LinearEasing))
                        currentOnOpen.value()
                    }
                    waitForUpOrCancellation()
                    fill.cancel()
                    scope.launch { progress.snapTo(0f) }
                }
            },
        contentAlignment = Alignment.Center,
    ) {
        Image(painterResource(R.drawable.btn_tutors), contentDescription = null, modifier = Modifier.fillMaxSize())
        if (progress.value > 0f) {
            CircularProgressIndicator(
                progress = { progress.value },
                color = Palette.Gold,
                strokeWidth = 5.dp,
                modifier = Modifier.fillMaxSize(),
            )
        }
    }
}

/** Tres estrellas (llenas las ganadas, vacías las demás). Con 0 no se dibuja nada. */
@Composable
fun StarsRow(stars: Int, modifier: Modifier = Modifier, starSize: Dp = 22.dp) {
    if (stars <= 0) return
    Row(modifier.semantics { contentDescription = "$stars ★" }, verticalAlignment = Alignment.CenterVertically) {
        repeat(3) { i ->
            Image(
                painterResource(if (i < stars) R.drawable.star_full else R.drawable.star_empty),
                contentDescription = null,
                modifier = Modifier.size(starSize),
            )
        }
    }
}
