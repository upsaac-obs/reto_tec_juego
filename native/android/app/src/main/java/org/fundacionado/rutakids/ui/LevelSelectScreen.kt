package org.fundacionado.rutakids.ui

import android.content.Context
import android.graphics.BitmapFactory
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.displayCutout
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.disabled
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import org.fundacionado.rutakids.R
import org.fundacionado.rutakids.bridge.GodotState
import org.fundacionado.rutakids.data.Levels
import org.fundacionado.rutakids.data.Progress
import org.json.JSONObject
import kotlin.math.atan2
import androidx.compose.ui.unit.min
import kotlin.math.roundToInt

/**
 * Selección de niveles: un mapa de Puebla en una sola pantalla (docs/plan_menus_mapa.md).
 * El camino hace una "S" con las paradas 1 a 8; cada una es su destino del juego y un
 * letrero de talavera con el pictograma del hábito. Todo sale de assets/menu_map/
 * (tools/menu_map.py), el mismo que usa iOS.
 * - El 0 (tutorial) no sale aquí: se abre solo la primera vez que se toca Jugar.
 * - El 1 siempre está abierto y cada nivel se abre con 1 estrella en el anterior.
 * - En kiosco todo está abierto, no hay estrellas y el auto espera al inicio del camino.
 * - Si Godot respondió level_not_built, la parada queda cerrada.
 * - El auto espera en la parada que sigue; al ganar una nueva, maneja hasta la siguiente.
 */
@Composable
fun LevelSelectScreen(
    godot: GodotState,
    progress: Progress,
    kiosk: Boolean,
    onLevelSelected: (Int) -> Unit,
    onBack: () -> Unit,
) {
    val context = LocalContext.current
    val map = remember { MenuMap.load(context) }
    val names = Levels.menu.associate { it.id to stringResource(it.nameRes) }
    val lockedLabel = stringResource(R.string.MENU_DESBLOQUEAR)

    // A qué parada va el auto: la primera abierta sin estrellas (o la última si ya ganó todas).
    val nextLevel = Levels.menu.firstOrNull { progress.isUnlocked(it.id) && progress.starsFor(it.id) == 0 }?.id
        ?: Levels.menu.last().id
    val target = if (kiosk) map.startIndex else map.stopFor(nextLevel).pathIndex
    val prefs = remember { context.getSharedPreferences(PREFS, Context.MODE_PRIVATE) }
    val from = if (kiosk) target else prefs.getInt(KEY_CAR, map.startIndex).coerceIn(0, map.path.lastIndex)
    val car = remember { Animatable(minOf(from, target).toFloat()) }
    LaunchedEffect(target) {
        if (car.value < target) {
            val steps = target - car.value
            car.animateTo(target.toFloat(), tween((steps * CAR_MS_PER_STEP).roundToInt().coerceIn(500, 2600), easing = FastOutSlowInEasing))
        } else {
            car.snapTo(target.toFloat())
        }
        if (!kiosk) prefs.edit().putInt(KEY_CAR, target).apply()
    }
    val pulse by rememberInfiniteTransition(label = "pulso").animateFloat(
        1f, 1.08f, infiniteRepeatable(tween(700), RepeatMode.Reverse), label = "pulso",
    )

    BoxWithConstraints(Modifier.fillMaxSize().background(Palette.Grass)) {
        val unit: Dp = min(maxWidth / map.width, maxHeight / map.height)
        val left = (maxWidth - unit * map.width) / 2
        val top = (maxHeight - unit * map.height) / 2
        fun Modifier.at(x: Float, y: Float, w: Float, h: Float) =
            this.offset(left + unit * x, top + unit * y).size(unit * w, unit * h)

        val bg = map.background
        Image(map.image(bg.file), null, Modifier.at(bg.x, bg.y, bg.width, bg.height), contentScale = ContentScale.FillBounds)

        map.stops.forEach { stop ->
            val id = stop.level
            val notBuilt = id in godot.notBuiltLevels
            val unlocked = (kiosk || progress.isUnlocked(id)) && !notBuilt
            val stars = if (kiosk) 0 else progress.starsFor(id)
            val loading = unlocked && (!godot.engineReady || godot.requestedLevel == id)
            val isNext = unlocked && !kiosk && id == nextLevel && car.value >= target
            val s = stop.sign
            Image(
                map.image(if (unlocked) "sign_$id.png" else "sign_${id}_lock.png"),
                contentDescription = null,
                modifier = Modifier.at(s.x, s.y, s.width, s.height)
                    .graphicsLayer {
                        val k = if (isNext) pulse else 1f
                        scaleX = k; scaleY = k
                        transformOrigin = androidx.compose.ui.graphics.TransformOrigin(0.5f, 1f)
                    },
            )
            if (stars > 0) {
                Row(
                    Modifier.at(stop.starsX - 22f, stop.starsY - 7f, 44f, 14f),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically,
                ) { StarsRow(stars, starSize = unit * 13f) }
            }
            if (loading) {
                CircularProgressIndicator(
                    color = Palette.Gold,
                    strokeWidth = 3.dp,
                    modifier = Modifier.at(s.x + s.width * 0.25f, s.y + s.width * 0.25f, s.width * 0.5f, s.width * 0.5f),
                )
            }
            val h = stop.hit
            val label = "$id. ${names[id].orEmpty()}" + when {
                !unlocked -> ". $lockedLabel"
                stars > 0 -> ", $stars ★"
                else -> ""
            }
            Box(
                Modifier.at(h.x, h.y, h.width, h.height)
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null,
                        enabled = unlocked && godot.engineReady && godot.requestedLevel == null,
                    ) { onLevelSelected(id) }
                    .semantics {
                        role = Role.Button
                        contentDescription = label
                        if (!unlocked) disabled()
                    },
            )
        }

        // El auto sobre el camino, mirando hacia donde avanza.
        val (cx, cy, angle) = map.carAt(car.value)
        Image(
            map.image(map.car.file),
            contentDescription = null,
            modifier = Modifier.at(cx - map.car.width / 2, cy - map.car.height / 2, map.car.width, map.car.height)
                .graphicsLayer { rotationZ = angle },
        )

        // Barra de arriba: Regresar a la izquierda y las estrellas a la derecha.
        Row(
            Modifier.fillMaxWidth().windowInsetsPadding(WindowInsets.displayCutout).padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            ImageButton(R.drawable.btn_back, stringResource(R.string.MENU_REGRESAR), onBack, Modifier.size(CornerButtonSize))
            if (!kiosk) StarsBanner(progress.totalStars, Levels.maxStars) else Box(Modifier.alpha(0f))
        }
    }
}

private const val PREFS = "menu_map"
/** Última parada donde se vio el auto (solo para animar el avance; no es progreso). */
private const val KEY_CAR = "car_index"
private const val CAR_MS_PER_STEP = 22f

/** Datos de assets/menu_map/map_layout.json (tools/menu_map.py). Unidades del contenido. */
private class MenuMap(private val context: Context, json: JSONObject) {
    class Rect(val x: Float, val y: Float, val width: Float, val height: Float)
    class Image(val file: String, val x: Float, val y: Float, val width: Float, val height: Float)
    class Stop(val level: Int, val sign: Rect, val hit: Rect, val starsX: Float, val starsY: Float, val pathIndex: Int)

    val width: Float
    val height: Float
    val background: Image
    val car: Image
    val path: List<Pair<Float, Float>>
    val startIndex: Int
    val stops: List<Stop>
    private val images = HashMap<String, ImageBitmap>()

    init {
        val content = json.getJSONArray("content")
        width = content.getDouble(0).toFloat()
        height = content.getDouble(1).toFloat()
        background = json.getJSONObject("background").let {
            Image(it.getString("file"), it.f("x"), it.f("y"), it.f("width"), it.f("height"))
        }
        car = json.getJSONObject("car").let { Image(it.getString("file"), 0f, 0f, it.f("width"), it.f("height")) }
        val points = json.getJSONArray("path")
        path = List(points.length()) { i -> points.getJSONArray(i).let { it.getDouble(0).toFloat() to it.getDouble(1).toFloat() } }
        startIndex = json.getInt("start_index")
        val list = json.getJSONArray("stops")
        stops = List(list.length()) { i ->
            val o = list.getJSONObject(i)
            val stars = o.getJSONObject("stars")
            Stop(o.getInt("level"), o.getJSONObject("sign").rect(), o.getJSONObject("hit").rect(),
                stars.f("x"), stars.f("y"), o.getInt("path_index"))
        }
    }

    fun stopFor(level: Int) = stops.first { it.level == level }

    /** Posición en el camino para un índice con decimales, y el ángulo (grados) hacia donde avanza. */
    fun carAt(index: Float): Triple<Float, Float, Float> {
        val i = index.toInt().coerceIn(0, path.lastIndex - 1)
        val t = (index - i).coerceIn(0f, 1f)
        val (x0, y0) = path[i]
        val (x1, y1) = path[i + 1]
        val angle = Math.toDegrees(atan2((y1 - y0).toDouble(), (x1 - x0).toDouble())).toFloat()
        return Triple(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, angle)
    }

    fun image(file: String): ImageBitmap = images.getOrPut(file) {
        context.assets.open("$DIR/$file").use { BitmapFactory.decodeStream(it).asImageBitmap() }
    }

    private fun JSONObject.f(key: String) = getDouble(key).toFloat()
    private fun JSONObject.rect() = Rect(f("x"), f("y"), f("width"), f("height"))

    companion object {
        private const val DIR = "menu_map"
        private var cached: MenuMap? = null

        fun load(context: Context): MenuMap = cached ?: MenuMap(
            context.applicationContext,
            JSONObject(context.assets.open("$DIR/map_layout.json").bufferedReader().use { it.readText() }),
        ).also { cached = it }
    }
}
