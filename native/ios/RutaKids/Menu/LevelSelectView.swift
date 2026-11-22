import SwiftUI
import UIKit

// MARK: - Selección de niveles: mapa de Puebla en una pantalla (docs/plan_menus_mapa.md)
// El camino hace una "S" con las paradas 1 a 8; cada una es su destino del juego y un
// letrero de talavera con el pictograma del hábito. Todo sale de Resources/menu_map/
// (tools/menu_map.py), lo mismo que usa Android, así que las dos apps se ven igual.
// - El 1 siempre está abierto y cada nivel se abre con 1 estrella en el anterior.
// - En kiosco todo está abierto, no hay estrellas y el auto espera al inicio del camino.
// - El auto espera en la parada que sigue; al ganar una nueva, maneja hasta la siguiente.

struct LevelSelectView: View {
    let model: AppModel
    @Environment(\.dismiss) private var dismiss

    private var map: MenuMap { MenuMap.shared }
    @State private var carIndex: Double = -1
    @State private var pulse = false

    /// Última parada donde se vio el auto (solo para animar el avance; no es progreso).
    private static let carKey = "menu_map_car_index"
    private static let secondsPerStep = 0.022

    private var kiosk: Bool { model.store.kiosk }

    /// La primera parada abierta sin estrellas, o la última si ya se ganaron todas.
    private var nextLevel: Int {
        ProgressStore.menuLevels.first { model.store.isUnlocked($0) && model.store.stars(for: $0) == 0 }
            ?? ProgressStore.menuLevels.last!
    }

    private var targetIndex: Int {
        kiosk ? map.startIndex : map.stop(for: nextLevel).pathIndex
    }

    var body: some View {
        ZStack {
            Theme.grass.ignoresSafeArea()

            GeometryReader { geo in
                mapContent(in: geo.size)
            }
            .ignoresSafeArea()

            topBar

            if let key = model.toastKey {
                VStack {
                    Spacer()
                    Text(L(key))
                        .font(.fredoka(16, .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Theme.darkPurple.opacity(0.92)))
                        .overlay(Capsule().strokeBorder(Theme.gold, lineWidth: 2))
                        .padding(.bottom, 20)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.toastKey)
        .statusBar(hidden: true)
        .onAppear(perform: driveCar)
        .onChange(of: targetIndex) { driveCar() }
    }

    // MARK: Mapa

    private func mapContent(in size: CGSize) -> some View {
        let unit = min(size.width / map.width, size.height / map.height)
        // Lo que sobra a lo ancho va a la izquierda (anchor_x = 1): ahí las calles siguen.
        let left = (size.width - unit * map.width) * map.anchorX
        let top = (size.height - unit * map.height) / 2
        func toScreen(_ r: MenuMap.Rect) -> CGRect {
            CGRect(x: left + unit * r.x, y: top + unit * r.y, width: unit * r.width, height: unit * r.height)
        }

        return ZStack(alignment: .topLeading) {
            mapImage(map.background.file, in: toScreen(map.background.rect))

            ForEach(map.stops, id: \.level) { stop in
                stopView(stop, unit: unit, toScreen: toScreen)
            }

            if carIndex >= 0 {
                CarOnPath(index: carIndex, map: map, unit: unit, left: left, top: top)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }

    @ViewBuilder
    private func stopView(_ stop: MenuMap.Stop, unit: CGFloat, toScreen: (MenuMap.Rect) -> CGRect) -> some View {
        let id = stop.level
        let unlocked = model.store.isUnlocked(id)
        let stars = kiosk ? 0 : model.store.stars(for: id)
        let isNext = unlocked && !kiosk && id == nextLevel && carIndex >= Double(targetIndex)
        let sign = toScreen(stop.sign)
        let hit = toScreen(stop.hit)
        let starsAt = toScreen(MenuMap.Rect(x: stop.starsX, y: stop.starsY, width: 0, height: 0))

        mapImage(unlocked ? "sign_\(id)" : "sign_\(id)_lock", in: sign)
            .scaleEffect(isNext && pulse ? 1.08 : 1, anchor: .bottom)
            .animation(isNext ? .easeInOut(duration: 0.7).repeatForever(autoreverses: true) : .default, value: pulse)

        if stars > 0 {
            StarsRow(earned: stars, size: unit * 13)
                .position(x: starsAt.minX, y: starsAt.minY)
        }

        if unlocked && (!model.bridge.engineReady || model.bridge.starting) {
            ProgressView()
                .tint(Theme.gold)
                .position(x: sign.midX, y: sign.minY + sign.width / 2)
        }

        Button {
            model.tapLevel(id)
        } label: {
            Color.clear.contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: hit.width, height: hit.height)
        .position(x: hit.midX, y: hit.midY)
        .accessibilityLabel("\(id). \(L(String(format: "NIVEL_%02d_NOMBRE", id)))")
        .accessibilityValue(unlocked ? (stars > 0 ? "\(stars) ★" : "") : L("MENU_DESBLOQUEAR"))
    }

    private func mapImage(_ name: String, in rect: CGRect) -> some View {
        Group {
            if let image = map.image(name) {
                Image(uiImage: image).resizable()
            } else {
                Color.clear
            }
        }
        .frame(width: rect.width, height: rect.height)
        .position(x: rect.midX, y: rect.midY)
        .accessibilityHidden(true)
    }

    // MARK: Barra de arriba

    private var topBar: some View {
        VStack {
            HStack {
                BackButton {
                    AudioManager.shared.playSound(named: "menu_tap")
                    dismiss()
                }
                Spacer()
                if !kiosk {
                    StarsBanner(total: model.store.totalStars, max: model.store.maxStars)
                }
            }
            .padding(16)
            Spacer()
        }
    }

    // MARK: Auto

    /// Lleva el auto de la parada donde se vio la última vez hasta la que sigue (solo hacia adelante).
    private func driveCar() {
        let target = targetIndex
        let defaults = UserDefaults.standard
        let saved = defaults.object(forKey: Self.carKey) as? Int
        let from = kiosk ? target : min(saved ?? map.startIndex, target)
        if carIndex < 0 { carIndex = Double(from) }
        pulse = true
        if Double(target) > carIndex {
            let duration = min(2.6, max(0.5, (Double(target) - carIndex) * Self.secondsPerStep))
            withAnimation(.easeInOut(duration: duration)) { carIndex = Double(target) }
            // "Ding" cuando el auto llega a la parada nueva.
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                AudioManager.shared.playSound(named: "menu_unlock")
            }
        } else {
            carIndex = Double(target)
        }
        if !kiosk { defaults.set(target, forKey: Self.carKey) }
    }
}

// MARK: - Auto que recorre el camino
// Animatable: SwiftUI interpola `index` y el auto avanza por cada punto del camino
// (no en línea recta), girando hacia donde va.

private struct CarOnPath: View, Animatable {
    var index: Double
    let map: MenuMap
    let unit: CGFloat
    let left: CGFloat
    let top: CGFloat

    var animatableData: Double {
        get { index }
        set { index = newValue }
    }

    var body: some View {
        let p = map.position(at: index)
        Group {
            if let image = map.image(map.car.file) {
                Image(uiImage: image).resizable()
            } else {
                Color.clear
            }
        }
        .frame(width: unit * map.car.rect.width, height: unit * map.car.rect.height)
        .rotationEffect(.degrees(p.angle))
        .position(x: left + unit * p.x, y: top + unit * p.y)
        .accessibilityHidden(true)
    }
}

// MARK: - Datos del mapa (Resources/menu_map/map_layout.json, de tools/menu_map.py)

@MainActor
final class MenuMap {
    struct Rect {
        let x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat
    }
    struct Picture {
        let file: String
        let rect: Rect
    }
    struct Stop {
        let level: Int
        let sign: Rect
        let hit: Rect
        let starsX: CGFloat
        let starsY: CGFloat
        let pathIndex: Int
    }

    static let shared = MenuMap()

    let width: CGFloat
    let height: CGFloat
    /// 0 = pegado a la izquierda, 0.5 = centrado, 1 = pegado a la derecha.
    let anchorX: CGFloat
    let background: Picture
    let car: Picture
    let path: [CGPoint]
    let startIndex: Int
    let stops: [Stop]
    private var images: [String: UIImage] = [:]

    private init() {
        let json = (MenuMap.url("map_layout", "json")
            .flatMap { try? Data(contentsOf: $0) }
            .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }) ?? [:]
        func num(_ value: Any?) -> CGFloat { CGFloat((value as? NSNumber)?.doubleValue ?? 0) }
        func rect(_ o: [String: Any]?) -> Rect {
            Rect(x: num(o?["x"]), y: num(o?["y"]), width: num(o?["width"]), height: num(o?["height"]))
        }
        let content = json["content"] as? [NSNumber] ?? [712, 400]
        width = CGFloat(content[0].doubleValue)
        height = CGFloat(content[1].doubleValue)
        anchorX = json["anchor_x"] != nil ? num(json["anchor_x"]) : 0.5
        let bg = json["background"] as? [String: Any]
        background = Picture(file: (bg?["file"] as? String ?? "map_bg.jpg").replacingOccurrences(of: ".jpg", with: ""),
                             rect: rect(bg))
        let carInfo = json["car"] as? [String: Any]
        car = Picture(file: (carInfo?["file"] as? String ?? "map_car.png").replacingOccurrences(of: ".png", with: ""),
                      rect: Rect(x: 0, y: 0, width: num(carInfo?["width"]), height: num(carInfo?["height"])))
        path = (json["path"] as? [[NSNumber]] ?? []).map { CGPoint(x: $0[0].doubleValue, y: $0[1].doubleValue) }
        startIndex = json["start_index"] as? Int ?? 0
        stops = (json["stops"] as? [[String: Any]] ?? []).map { o in
            let stars = o["stars"] as? [String: Any]
            return Stop(level: o["level"] as? Int ?? 0,
                        sign: rect(o["sign"] as? [String: Any]),
                        hit: rect(o["hit"] as? [String: Any]),
                        starsX: num(stars?["x"]), starsY: num(stars?["y"]),
                        pathIndex: o["path_index"] as? Int ?? 0)
        }
    }

    func stop(for level: Int) -> Stop {
        stops.first { $0.level == level } ?? stops[0]
    }

    /// Posición en el camino para un índice con decimales, y el ángulo (grados) hacia donde avanza.
    func position(at index: Double) -> (x: CGFloat, y: CGFloat, angle: Double) {
        guard path.count > 1 else { return (0, 0, 0) }
        let i = min(max(Int(index), 0), path.count - 2)
        let t = CGFloat(min(max(index - Double(i), 0), 1))
        let a = path[i], b = path[i + 1]
        let angle = atan2(Double(b.y - a.y), Double(b.x - a.x)) * 180 / .pi
        return (a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, angle)
    }

    /// Imagen del mapa por nombre (sin extensión): busca .png y .jpg, sueltos o en menu_map/.
    func image(_ name: String) -> UIImage? {
        if let cached = images[name] { return cached }
        let found = (MenuMap.url(name, "png") ?? MenuMap.url(name, "jpg")).flatMap { UIImage(contentsOfFile: $0.path) }
        if let found { images[name] = found }
        return found
    }

    private static func url(_ name: String, _ ext: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: ext)
            ?? Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "menu_map")
    }
}
