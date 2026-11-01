package org.fundacionado.rutakids.ui

import androidx.annotation.DrawableRes
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.waitForUpOrCancellation
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
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

/** Fondo de todos los menús (arte de Paulo) con el contenido encima. */
@Composable
fun MenuBackground(content: @Composable BoxScope.() -> Unit) {
    Box(Modifier.fillMaxSize().background(Palette.DarkPurple)) {
        Image(
            painterResource(R.drawable.menu_background),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.fillMaxSize(),
        )
        content()
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
        modifier = modifier.clickable(onClick = onClick),
    )
}

/** Barra amarilla con el total de estrellas, como en el mockup. */
@Composable
fun StarsBanner(total: Int, max: Int, modifier: Modifier = Modifier) {
    Surface(
        shape = RoundedCornerShape(20.dp),
        color = Palette.AdoRed,
        contentColor = Palette.White,
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
            .clip(CircleShape)
            .background(Palette.DarkPurple)
            .clickable(onClick = onClick)
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
            .clip(CircleShape)
            .background(Palette.DarkPurple)
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
