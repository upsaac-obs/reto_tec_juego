// Creación y desarrollo: Dylan Isaac Mancilla López
import Foundation

/// Vehículo del garaje. El id es el mismo de Godot (scenes/level/vehicles.gd, Vehicles.IDS)
/// y se manda en start_level como "vehicle". El dibujo es "garage_<id>" en Assets.xcassets
/// (tools/art/integrar_garaje.py), igual que en Android.
struct Vehicle: Identifiable, Equatable {
    let id: String
    /// Clave de textos.csv con el nombre.
    let nameKey: String
    /// Estrellas que cuesta. Se gastan y no se devuelven.
    let price: Int

    var image: String { "garage_\(id)" }
}

/// Garaje: las estrellas ganadas son la moneda. El saldo es lo ganado menos lo que costó
/// lo comprado, así que no hay contador aparte que se pueda descuadrar.
/// Hay 24 estrellas en los niveles y todo cuesta 36: no alcanza para todo, hay que elegir.
/// En kiosco todo está disponible y nada se guarda. (Igual que data/Garage.kt de Android.)
enum Garage {
    static let defaultId = "clasico"
    static let motoId = "moto"

    static let all: [Vehicle] = [
        Vehicle(id: defaultId, nameKey: "VEHICULO_CLASICO", price: 0),
        Vehicle(id: "burbuja", nameKey: "VEHICULO_BURBUJA", price: 3),
        Vehicle(id: "todoterreno", nameKey: "VEHICULO_TODOTERRENO", price: 3),
        Vehicle(id: "convertible", nameKey: "VEHICULO_CONVERTIBLE", price: 6),
        Vehicle(id: motoId, nameKey: "VEHICULO_MOTO", price: 6),
        Vehicle(id: "deportivo", nameKey: "VEHICULO_DEPORTIVO", price: 9),
        Vehicle(id: "futuro", nameKey: "VEHICULO_FUTURO", price: 9),
    ]

    static func byId(_ id: String?) -> Vehicle { all.first { $0.id == id } ?? all[0] }

    /// Estrellas gastadas en lo comprado.
    static func spent(_ owned: Set<String>) -> Int {
        all.filter { owned.contains($0.id) }.reduce(0) { $0 + $1.price }
    }

    /// Estrellas que quedan para comprar.
    static func balance(totalStars: Int, owned: Set<String>) -> Int {
        max(0, totalStars - spent(owned))
    }
}
