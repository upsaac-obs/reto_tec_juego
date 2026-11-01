package org.fundacionado.rutakids.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.fundacionado.rutakids.R
import org.fundacionado.rutakids.bridge.GodotState
import org.fundacionado.rutakids.data.LevelInfo
import org.fundacionado.rutakids.data.Levels
import org.fundacionado.rutakids.data.Progress

/**
 * Selección de niveles (diseño del mockup de Paulo): 11 tarjetas con su número y sus estrellas.
 * - El 0 siempre está abierto y cada nivel se abre con 1 estrella en el anterior.
 * - En kiosco todo está abierto.
 * - Si Godot respondió level_not_built, la tarjeta sale bloqueada ("Muy pronto").
 */
@Composable
fun LevelSelectScreen(
    godot: GodotState,
    progress: Progress,
    kiosk: Boolean,
    onLevelSelected: (Int) -> Unit,
    onBack: () -> Unit,
) {
    MenuBackground {
        Column(Modifier.fillMaxSize()) {
            Row(
                Modifier.fillMaxWidth().padding(20.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                ImageButton(R.drawable.btn_exit, stringResource(R.string.MENU_REGRESAR), onBack, Modifier.size(60.dp))
                StarsBanner(progress.totalStars, Levels.maxStars)
                Box(Modifier.size(60.dp))
            }
            LazyVerticalGrid(
                columns = GridCells.Adaptive(minSize = 120.dp),
                contentPadding = PaddingValues(start = 48.dp, end = 48.dp, bottom = 24.dp),
                horizontalArrangement = Arrangement.spacedBy(20.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(Levels.all, key = { it.id }) { level ->
                    val notBuilt = level.id in godot.notBuiltLevels
                    val unlocked = kiosk || progress.isUnlocked(level.id)
                    LevelCard(
                        level = level,
                        stars = progress.starsFor(level.id),
                        locked = !unlocked || notBuilt,
                        notBuilt = notBuilt,
                        loading = !godot.engineReady || godot.requestedLevel == level.id,
                        onClick = {
                            if (unlocked && !notBuilt && godot.engineReady && godot.requestedLevel == null) {
                                onLevelSelected(level.id)
                            }
                        },
                    )
                }
            }
        }
    }
}

@Composable
private fun LevelCard(
    level: LevelInfo,
    stars: Int,
    locked: Boolean,
    notBuilt: Boolean,
    loading: Boolean,
    onClick: () -> Unit,
) {
    val name = stringResource(level.nameRes)
    Column(
        Modifier.clickable(enabled = !locked, onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(Modifier.fillMaxWidth().aspectRatio(130f / 134f)) {
            if (level.iconRes != null) {
                Image(
                    painterResource(level.iconRes),
                    contentDescription = name,
                    contentScale = ContentScale.Fit,
                    modifier = Modifier.fillMaxSize(),
                )
            } else {
                // Sin arte todavía: tarjeta lisa con el mismo estilo y el nombre.
                val shape = RoundedCornerShape(18.dp)
                Box(
                    Modifier.fillMaxSize().padding(3.dp).clip(shape)
                        .background(Palette.DarkPurple).border(4.dp, Palette.AdoRed, shape)
                        .padding(10.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(name, color = Palette.White, fontSize = 14.sp, textAlign = TextAlign.Center, fontWeight = FontWeight.Bold)
                }
            }
            // El número va encima del arte (los dibujos originales traían otro número).
            Text(
                "${level.id}",
                color = Palette.White,
                fontSize = 20.sp,
                fontWeight = FontWeight.Black,
                modifier = Modifier.align(Alignment.TopStart).padding(start = 12.dp, top = 6.dp),
            )
            if (locked) {
                Box(
                    Modifier.fillMaxSize().padding(3.dp).clip(RoundedCornerShape(18.dp))
                        .background(Color.Black.copy(alpha = 0.6f)),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        if (notBuilt) stringResource(R.string.MENU_BLOQUEADO) else "🔒",
                        color = Palette.White,
                        fontSize = if (notBuilt) 14.sp else 28.sp,
                        fontWeight = FontWeight.Bold,
                    )
                }
            } else if (loading) {
                CircularProgressIndicator(
                    color = Palette.Gold,
                    strokeWidth = 3.dp,
                    modifier = Modifier.align(Alignment.Center).size(28.dp),
                )
            }
        }
        StarsRow(stars, Modifier.height(30.dp))
    }
}

/** Las estrellas de abajo de cada tarjeta (Estrellas1-3 de Paulo). Con 0 no se dibuja nada. */
@Composable
fun StarsRow(stars: Int, modifier: Modifier = Modifier) {
    val res = when (stars) {
        1 -> R.drawable.stars_1
        2 -> R.drawable.stars_2
        3 -> R.drawable.stars_3
        else -> null
    }
    Box(modifier, contentAlignment = Alignment.Center) {
        if (res != null) Image(painterResource(res), contentDescription = "$stars ★", contentScale = ContentScale.Fit)
    }
}
