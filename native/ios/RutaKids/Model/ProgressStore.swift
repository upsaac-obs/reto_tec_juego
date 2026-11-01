import Foundation

/// Resultado de un nivel terminado (evento level_finished del puente).
struct LevelResult {
    let levelId: Int
    let stars: Int
    let points: Int
    /// Faltas por regla, p. ej. ["stop": 1]. Solo trae las reglas con al menos una falta.
    let infractions: [String: Int]
    let durationSeconds: Int
}

/// Lo único que guarda la app (docs/sprint_15_28_oct.md, sección 5.2). Nada personal:
/// modo de juego, kiosco, tutorial visto, y por nivel: estrellas, puntos y faltas.
/// Claves (las mismas que usa Android): mode, kiosk, tutorial_done,
/// level_<id>_stars, level_<id>_points, level_<id>_infractions.
@Observable
final class ProgressStore {
    static let modePeque = "peque"
    static let modeGrande = "grande"
    /// Niveles que salen en el menú (el 0 es el tutorial y se abre solo la primera vez).
    static let menuLevels: [Int] = Array(1...8)
    static let tutorialLevel = 0

    /// "peque", "grande" o nil si todavía no se elige (primera vez que se abre la app).
    private(set) var mode: String?
    private(set) var kiosk: Bool
    private(set) var tutorialDone: Bool
    private(set) var stars: [Int: Int] = [:]
    private(set) var points: [Int: Int] = [:]
    private(set) var infractions: [Int: [String: Int]] = [:]

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        mode = defaults.string(forKey: "mode")
        kiosk = defaults.bool(forKey: "kiosk")
        tutorialDone = defaults.bool(forKey: "tutorial_done")
        for id in [Self.tutorialLevel] + Self.menuLevels {
            stars[id] = defaults.integer(forKey: Self.starsKey(id))
            points[id] = defaults.integer(forKey: Self.pointsKey(id))
            infractions[id] = Self.parseInfractions(defaults.string(forKey: Self.infractionsKey(id)))
        }
    }

    // MARK: Lectura

    func stars(for levelId: Int) -> Int { stars[levelId] ?? 0 }

    /// Suma de estrellas de los niveles del menú.
    var totalStars: Int { Self.menuLevels.reduce(0) { $0 + stars(for: $1) } }
    var maxStars: Int { Self.menuLevels.count * 3 }

    /// El nivel 1 siempre está abierto; cada uno se abre con 1 estrella en el anterior.
    /// En modo kiosco todos están abiertos.
    func isUnlocked(_ levelId: Int) -> Bool {
        if kiosk || levelId <= Self.menuLevels[0] { return true }
        return stars(for: levelId - 1) >= 1
    }

    // MARK: Cambios

    func setMode(_ newMode: String) {
        guard newMode == Self.modePeque || newMode == Self.modeGrande else { return }
        mode = newMode
        defaults.set(newMode, forKey: "mode")
    }

    func setKiosk(_ value: Bool) {
        kiosk = value
        defaults.set(value, forKey: "kiosk")
    }

    /// Guarda el resultado de level_finished. Estrellas y puntos: siempre el mejor.
    /// En modo kiosco no se guarda nada.
    func record(_ result: LevelResult) {
        guard !kiosk else { return }
        let id = result.levelId
        stars[id] = max(result.stars, stars(for: id))
        points[id] = max(result.points, points[id] ?? 0)
        infractions[id] = result.infractions
        defaults.set(stars[id], forKey: Self.starsKey(id))
        defaults.set(points[id], forKey: Self.pointsKey(id))
        defaults.set(Self.encodeInfractions(result.infractions), forKey: Self.infractionsKey(id))
        if id == Self.tutorialLevel {
            tutorialDone = true
            defaults.set(true, forKey: "tutorial_done")
        }
    }

    /// Borra estrellas, puntos y faltas. El modo y el kiosco se quedan.
    func resetProgress() {
        for id in [Self.tutorialLevel] + Self.menuLevels {
            stars[id] = 0
            points[id] = 0
            infractions[id] = [:]
            defaults.removeObject(forKey: Self.starsKey(id))
            defaults.removeObject(forKey: Self.pointsKey(id))
            defaults.removeObject(forKey: Self.infractionsKey(id))
        }
        tutorialDone = false
        defaults.removeObject(forKey: "tutorial_done")
    }

    // MARK: Claves y formato

    private static func starsKey(_ id: Int) -> String { "level_\(id)_stars" }
    private static func pointsKey(_ id: Int) -> String { "level_\(id)_points" }
    private static func infractionsKey(_ id: Int) -> String { "level_\(id)_infractions" }

    private static func encodeInfractions(_ value: [String: Int]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]),
              let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }

    private static func parseInfractions(_ json: String?) -> [String: Int] {
        guard let json,
              let object = try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]
        else { return [:] }
        var result: [String: Int] = [:]
        for (rule, count) in object {
            if let number = count as? NSNumber { result[rule] = number.intValue }
        }
        return result
    }
}
