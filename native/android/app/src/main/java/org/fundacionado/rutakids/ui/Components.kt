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
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.waitForUpOrCancellation
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.displayCutout
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.CircleShape
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
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.imageResource
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import org.fundacionado.rutakids.R

/**
 * Fondo de todos los menús (arte de Paulo) con el contenido encima. El fondo llena toda la
 * pantalla; los botones se apartan de la cámara (notch) para que no queden tapados.
 */
@Composable
fun MenuBackground(content: @Composable BoxScope.() -> Unit) {
    Box(Modifier.fillMaxSize().background(Palette.DarkPurple)) {
        Image(
            painterResource(R.drawable.menu_background),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.fillMaxSize(),
        )
        Box(Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.displayCutout), content = content)
    }
}

/** Botón que es solo una imagen (Jugar, Salir). */
@Composable
fun ImageButton(
    @DrawableRes image: Int,
    label: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Image(
        painterResource(image),
        contentDescription = label,
        contentScale = ContentScale.Fit,
        modifier = modifier.pressClickable(onClick = onClick),
    )
}

/** Barra amarilla con el total de estrellas, como en el mockup. */
@Composable
fun StarsBanner(total: Int, max: Int, modifier: Modifier = Modifier) {
    Surface(
        shape = RoundedCornerShape(20.dp),
        color = Palette.Banner,
        contentColor = Palette.White,
        shadowElevation = 4.dp,
        modifier = modifier,
    ) {
        Row(
            Modifier.padding(horizontal = 18.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("$total / $max", fontWeight = FontWeight.Bold, fontSize = 18.sp, color = Palette.Gold)
            Text(" ★", fontSize = 18.sp, color = Palette.Gold)
        }
    }
}

/** Botón redondo morado (sonido, regresar). */
@Composable
fun RoundButton(
    label: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable BoxScope.() -> Unit,
) {
    Box(
        modifier
            .size(52.dp)
            .shadow(4.dp, CircleShape)
            .clip(CircleShape)
            .background(Palette.Card)
            .border(2.dp, Palette.AdoRed, CircleShape)
            .pressClickable(onClick = onClick)
            .semantics { contentDescription = label },
        contentAlignment = Alignment.Center,
        content = content,
    )
}

/**
 * Engrane de Tutores: se abre solo manteniéndolo presionado [holdMillis] (plan, sección 5.1),
 * para que los niños no entren con un toque. Mientras se mantiene, se llena un círculo.
 */
@Composable
fun TutorGear(onOpen: () -> Unit, modifier: Modifier = Modifier, holdMillis: Int = 3000) {
    val progress = remember { Animatable(0f) }
    val scope = rememberCoroutineScope()
    val currentOnOpen = rememberUpdatedState(onOpen)
    val label = stringResource(R.string.MENU_TUTORES)
    Box(
        modifier
            .size(52.dp)
            .shadow(4.dp, CircleShape)
            .clip(CircleShape)
            .background(Palette.Card)
            .border(2.dp, Palette.AdoRed, CircleShape)
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
        if (progress.value > 0f) {
            CircularProgressIndicator(
                progress = { progress.value },
                color = Palette.Gold,
                strokeWidth = 4.dp,
                modifier = Modifier.fillMaxSize(),
            )
        }
        Image(
            bitmap = ImageBitmap.imageResource(R.drawable.ic_engrane),
            contentDescription = null,
            filterQuality = FilterQuality.None,
            modifier = Modifier.size(32.dp),
        )
    }
}

/**
 * Como un clic normal, pero el botón se encoge un poco al pulsarlo y rebota al soltar
 * (el ScaleButtonStyle de iOS). Sin la onda gris de Material.
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

/** Cápsula morada con "Cargando…" mientras Godot arranca en segundo plano (como iOS). */
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
