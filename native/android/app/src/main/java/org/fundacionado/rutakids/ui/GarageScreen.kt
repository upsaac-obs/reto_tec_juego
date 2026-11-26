// Creación y desarrollo: Dylan Isaac Mancilla López
package org.fundacionado.rutakids.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import org.fundacionado.rutakids.R
import org.fundacionado.rutakids.data.Garage
import org.fundacionado.rutakids.data.GarageState
import org.fundacionado.rutakids.data.Vehicle

/**
 * Garaje (se abre desde el mapa): el niño gasta sus estrellas en otro vehículo y elige
 * con cuál juega. Comprar pide confirmación porque no hay devoluciones.
 * - Comprado: un toque lo elige.
 * - Alcanza: un toque pregunta si lo compra.
 * - No alcanza: suena cerrado y avisa "Te faltan estrellas".
 * - Kiosco: todo disponible, sin precios ni saldo.
 */
@Composable
fun GarageScreen(
    garage: GarageState,
    totalStars: Int,
    kiosk: Boolean,
    kioskVehicle: String,
    onSelect: (String) -> Unit,
    onBuy: (String) -> Unit,
    onBack: () -> Unit,
) {
    val audio = LocalMenuAudio.current
    val balance = Garage.balance(totalStars, garage.owned)
    val selected = if (kiosk) kioskVehicle else garage.selected
    var confirm by remember { mutableStateOf<Vehicle?>(null) }
    var missingTick by remember { mutableStateOf(0) }

    MenuBackground {
        Column(Modifier.fillMaxSize().padding(16.dp)) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                ImageButton(R.drawable.btn_back, stringResource(R.string.MENU_REGRESAR), onBack, Modifier.size(CornerButtonSize))
                Text(
                    stringResource(R.string.GARAJE_TITULO),
                    color = Palette.White,
                    fontSize = 30.sp,
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.weight(1f),
                )
                if (!kiosk) CoinBalance(balance) else Spacer(Modifier.size(CornerButtonSize))
            }
            Spacer(Modifier.height(12.dp))
            LazyRow(
                Modifier.fillMaxWidth().weight(1f),
                horizontalArrangement = Arrangement.spacedBy(14.dp),
                contentPadding = PaddingValues(horizontal = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                items(Garage.all, key = { it.id }) { vehicle ->
                    val owned = kiosk || vehicle.id in garage.owned
                    VehicleCard(
                        vehicle = vehicle,
                        owned = owned,
                        selected = vehicle.id == selected,
                        affordable = balance >= vehicle.price,
                        onClick = {
                            when {
                                owned -> { audio?.tap(); onSelect(vehicle.id) }
                                balance >= vehicle.price -> { audio?.tap(); confirm = vehicle }
                                else -> { audio?.locked(); missingTick++ }
                            }
                        },
                    )
                }
            }
            // "Te faltan estrellas" un momento después de tocar uno que no alcanza.
            var showMissing by remember { mutableStateOf(false) }
            LaunchedEffect(missingTick) {
                if (missingTick == 0) return@LaunchedEffect
                showMissing = true
                delay(MISSING_MS)
                showMissing = false
            }
            Text(
                stringResource(R.string.GARAJE_FALTAN),
                color = Palette.Gold,
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().alpha(if (showMissing) 1f else 0f),
            )
        }

        confirm?.let { vehicle ->
            BuyDialog(
                vehicle = vehicle,
                onYes = {
                    audio?.unlock()
                    onBuy(vehicle.id)
                    confirm = null
                },
                onNo = {
                    audio?.tap()
                    confirm = null
                },
            )
        }
    }
}

private const val MISSING_MS = 1800L

@Composable
private fun VehicleCard(vehicle: Vehicle, owned: Boolean, selected: Boolean, affordable: Boolean, onClick: () -> Unit) {
    val name = stringResource(vehicle.nameRes)
    val using = stringResource(R.string.GARAJE_USANDO)
    Column(
        Modifier
            .width(170.dp)
            .clip(RoundedCornerShape(22.dp))
            .background(Palette.DarkPurple.copy(alpha = 0.9f))
            .border(if (selected) 4.dp else 2.dp, if (selected) Palette.Gold else Palette.Outline, RoundedCornerShape(22.dp))
            .pressClickable(onClick = onClick)
            .semantics {
                role = Role.Button
                contentDescription = when {
                    selected -> "$name, $using"
                    owned -> name
                    else -> "$name, ${vehicle.price} ★"
                }
            }
            .padding(12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(Modifier.fillMaxWidth().height(96.dp), contentAlignment = Alignment.Center) {
            Image(
                painterResource(vehicle.image),
                contentDescription = null,
                contentScale = ContentScale.Fit,
                modifier = Modifier.fillMaxSize().alpha(if (owned || affordable) 1f else 0.55f),
            )
            if (vehicle.id == Garage.MOTO) {
                Image(
                    painterResource(R.drawable.icon_helmet),
                    contentDescription = stringResource(R.string.GARAJE_MOTO_CASCO),
                    modifier = Modifier.size(34.dp).align(Alignment.TopEnd),
                )
            }
            if (!owned && !affordable) {
                Image(painterResource(R.drawable.icon_lock), null, Modifier.size(34.dp).align(Alignment.TopStart))
            }
        }
        Spacer(Modifier.height(6.dp))
        Text(name, color = Palette.White, fontSize = 18.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center)
        Spacer(Modifier.height(6.dp))
        Box(Modifier.height(32.dp), contentAlignment = Alignment.Center) {
            when {
                selected -> Text(using, color = Palette.Gold, fontSize = 14.sp, fontWeight = FontWeight.Bold)
                !owned -> Price(vehicle.price, dim = !affordable)
            }
        }
    }
}

/** Estrella moneda y número (precio de un vehículo). */
@Composable
private fun Price(price: Int, dim: Boolean = false, iconSize: Dp = 26.dp) {
    Row(Modifier.alpha(if (dim) 0.6f else 1f), verticalAlignment = Alignment.CenterVertically) {
        Image(painterResource(R.drawable.icon_coin_star), contentDescription = null, modifier = Modifier.size(iconSize))
        Spacer(Modifier.width(4.dp))
        Text("$price", color = Palette.Gold, fontSize = 20.sp, fontWeight = FontWeight.Bold)
    }
}

/** Saldo para comprar: cápsula morada con la estrella moneda. */
@Composable
private fun CoinBalance(balance: Int) {
    Row(
        Modifier
            .clip(RoundedCornerShape(24.dp))
            .background(Palette.DarkPurple.copy(alpha = 0.88f))
            .padding(start = 8.dp, end = 18.dp, top = 4.dp, bottom = 4.dp)
            .semantics { contentDescription = "$balance ★" },
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Image(painterResource(R.drawable.icon_coin_star), contentDescription = null, modifier = Modifier.size(34.dp))
        Spacer(Modifier.width(8.dp))
        Text("$balance", fontWeight = FontWeight.Bold, fontSize = 22.sp, color = Palette.Gold)
    }
}

/** ¿Lo compras? Con el dibujo grande, el precio y Sí / Todavía no. */
@Composable
private fun BuyDialog(vehicle: Vehicle, onYes: () -> Unit, onNo: () -> Unit) {
    Box(
        Modifier
            .fillMaxSize()
            .background(Palette.Outline.copy(alpha = 0.6f))
            .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null, onClick = onNo),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            Modifier
                .width(380.dp)
                .clip(RoundedCornerShape(26.dp))
                .background(Palette.DarkPurple)
                .border(3.dp, Palette.Gold, RoundedCornerShape(26.dp))
                // Tocar dentro del cuadro no lo cierra.
                .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) {}
                .padding(18.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Image(painterResource(vehicle.image), null, Modifier.height(100.dp), contentScale = ContentScale.Fit)
            Spacer(Modifier.height(8.dp))
            Text(stringResource(vehicle.nameRes), color = Palette.White, fontSize = 22.sp, fontWeight = FontWeight.Bold)
            Price(vehicle.price)
            Spacer(Modifier.height(6.dp))
            if (vehicle.id == Garage.MOTO) {
                Text(stringResource(R.string.GARAJE_MOTO_CASCO), color = Palette.White, fontSize = 15.sp, textAlign = TextAlign.Center)
                Spacer(Modifier.height(4.dp))
            }
            Text(stringResource(R.string.GARAJE_COMPRAR), color = Palette.White, fontSize = 16.sp, textAlign = TextAlign.Center)
            Spacer(Modifier.height(14.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                Pill(stringResource(R.string.GARAJE_NO), Palette.Asphalt, Palette.White, onNo)
                Pill(stringResource(R.string.GARAJE_SI), Palette.Gold, Palette.DarkPurple, onYes)
            }
        }
    }
}

@Composable
private fun Pill(label: String, color: androidx.compose.ui.graphics.Color, textColor: androidx.compose.ui.graphics.Color, onClick: () -> Unit) {
    Box(
        Modifier
            .clip(RoundedCornerShape(50))
            .background(color)
            .pressClickable(onClick = onClick)
            .semantics { role = Role.Button }
            .padding(horizontal = 26.dp, vertical = 10.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(label, color = textColor, fontSize = 20.sp, fontWeight = FontWeight.Bold)
    }
}
