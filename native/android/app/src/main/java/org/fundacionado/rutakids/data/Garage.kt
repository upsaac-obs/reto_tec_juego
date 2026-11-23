// Creación y desarrollo: Dylan Isaac Mancilla López
package org.fundacionado.rutakids.data

import androidx.annotation.DrawableRes
import androidx.annotation.StringRes
import org.fundacionado.rutakids.R

/**
 * Vehículo del garaje. El id es el mismo de Godot (scenes/level/vehicles.gd, Vehicles.IDS):
 * se manda en start_level como "vehicle". El dibujo es garage_<id> (tools/art/integrar_garaje.py).
 */
data class Vehicle(
    val id: String,
    @StringRes val nameRes: Int,
    @DrawableRes val image: Int,
    /** Estrellas que cuesta. Se gastan y no se devuelven. */
    val price: Int,
)

/**
 * Garaje: las estrellas ganadas son la moneda. El saldo es lo ganado menos lo que costó
 * lo comprado, así que no hay contador aparte que se pueda descuadrar.
 * Hay 24 estrellas en los niveles y todo cuesta 36: no alcanza para todo, hay que elegir.
 * En kiosco todo está disponible y nada se guarda.
 */
object Garage {
    const val DEFAULT = "clasico"
    const val MOTO = "moto"

    val all = listOf(
        Vehicle(DEFAULT, R.string.VEHICULO_CLASICO, R.drawable.garage_clasico, 0),
        Vehicle("burbuja", R.string.VEHICULO_BURBUJA, R.drawable.garage_burbuja, 3),
        Vehicle("todoterreno", R.string.VEHICULO_TODOTERRENO, R.drawable.garage_todoterreno, 3),
        Vehicle("convertible", R.string.VEHICULO_CONVERTIBLE, R.drawable.garage_convertible, 6),
        Vehicle(MOTO, R.string.VEHICULO_MOTO, R.drawable.garage_moto, 6),
        Vehicle("deportivo", R.string.VEHICULO_DEPORTIVO, R.drawable.garage_deportivo, 9),
        Vehicle("futuro", R.string.VEHICULO_FUTURO, R.drawable.garage_futuro, 9),
    )

    fun byId(id: String?): Vehicle = all.firstOrNull { it.id == id } ?: all.first()

    /** Estrellas gastadas en lo comprado. */
    fun spent(owned: Set<String>): Int = all.filter { it.id in owned }.sumOf { it.price }

    /** Estrellas que quedan para comprar. */
    fun balance(totalStars: Int, owned: Set<String>): Int = (totalStars - spent(owned)).coerceAtLeast(0)
}

/** Lo guardado del garaje. El clásico siempre es tuyo. */
data class GarageState(
    val owned: Set<String> = setOf(Garage.DEFAULT),
    val selected: String = Garage.DEFAULT,
    /** Ya se vio el aviso del garaje (sale en el mapa al terminar el tutorial). */
    val hintSeen: Boolean = false,
)
