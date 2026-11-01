import SwiftUI

// MARK: - Modelo de una tarjeta

struct Level: Identifiable {
    let id: Int                 // 1...8, el mismo level_id del juego
    var stars: Int              // 0...3, las que se ganaron
    var isLocked: Bool = false

    /// Nombre del asset del recuadro: imagen_nl1 ... imagen_nl8
    var imageName: String { "imagen_nl\(id)" }
}

// MARK: - Recuadro de nivel
// Muestra la imagen "imagen_nlX" (trae el número y el dibujo) y, encima, abajo, las
// estrellas ganadas: llenas las que ya se sacaron, vacías las que faltan.

struct LevelCardView: View {
    let level: Level

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)

            ZStack {
                if UIImage(named: level.imageName) != nil {
                    Image(level.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: s, height: s)
                        .clipped()
                } else {
                    // Reemplazo mientras no llegue la imagen
                    RoundedRectangle(cornerRadius: s * 0.16)
                        .fill(LinearGradient(colors: [Theme.cardTop, Theme.cardBottom],
                                             startPoint: .top, endPoint: .bottom))
                    RoundedRectangle(cornerRadius: s * 0.16)
                        .strokeBorder(Theme.border, lineWidth: s * 0.035)
                    VStack(spacing: s * 0.04) {
                        Text("\(level.id)")
                            .font(.system(size: s * 0.4, weight: .black, design: .rounded))
                            .italic()
                            .foregroundColor(.white)
                        Text(level.imageName)
                            .font(.system(size: s * 0.09, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                }

                if level.isLocked {
                    RoundedRectangle(cornerRadius: s * 0.16)
                        .fill(Color.black.opacity(0.55))
                    Image(systemName: "lock.fill")
                        .font(.system(size: s * 0.3))
                        .foregroundColor(.white)
                } else {
                    // Estrellas ganadas, abajo al centro de la tarjeta.
                    VStack {
                        Spacer()
                        StarsRow(earned: level.stars, size: max(12, s * 0.15))
                            .padding(.horizontal, s * 0.08)
                            .padding(.vertical, s * 0.03)
                            .background(Capsule().fill(Theme.darkPurple.opacity(0.78)))
                            .padding(.bottom, s * 0.06)
                    }
                    .frame(width: s, height: s)
                }
            }
            .frame(width: s, height: s)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 3)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(level.id). \(L(String(format: "NIVEL_%02d_NOMBRE", level.id)))")
        .accessibilityValue(level.isLocked ? L("MENU_BLOQUEADO") : "\(level.stars) / 3")
    }
}

// MARK: - Pantalla de niveles (horizontal)

struct LevelSelectView: View {
    let model: AppModel
    @Environment(\.dismiss) private var dismiss

    /// Las tarjetas con las estrellas y los candados que dicen el guardado y el modo kiosco.
    private var levels: [Level] {
        ProgressStore.menuLevels.map { id in
            Level(id: id, stars: model.store.stars(for: id), isLocked: !model.store.isUnlocked(id))
        }
    }

    var body: some View {
        ZStack {
            MenuBackground()

            GeometryReader { geo in
                content(in: geo.size)
            }

            if let key = model.toastKey {
                VStack {
                    Spacer()
                    Text(L(key))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Theme.darkPurple.opacity(0.92)))
                        .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 2))
                        .padding(.bottom, 20)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.toastKey)
        .statusBar(hidden: true)
    }

    // MARK: Contenido

    private func content(in size: CGSize) -> some View {
        let levels = self.levels
        let spacing: CGFloat = 12
        let backBarHeight: CGFloat = 56
        let padding: CGFloat = 12
        let columnsCount = 4
        let rowCount = max(1, Int(ceil(Double(levels.count) / Double(columnsCount))))

        let availableHeight = size.height - backBarHeight - padding * 3
        let availableWidth  = size.width * 0.90
        let cardByWidth  = (availableWidth  - spacing * CGFloat(columnsCount - 1)) / CGFloat(columnsCount)
        let cardByHeight = (availableHeight - spacing * CGFloat(rowCount    - 1)) / CGFloat(rowCount)
        let cardSize = max(60, min(cardByWidth, cardByHeight))

        let rows: [[Level]] = stride(from: 0, to: levels.count, by: columnsCount).map {
            Array(levels[$0..<min($0 + columnsCount, levels.count)])
        }

        return VStack(spacing: 0) {
            // ── Barra de arriba: botón de regreso y, mientras Godot arranca, "Cargando…" ──
            HStack {
                BackButton {
                    AudioManager.shared.playSound(named: "tap")
                    dismiss()
                }
                Spacer()
                if !model.bridge.engineReady {
                    HStack(spacing: 8) {
                        ProgressView().tint(Theme.gold)
                        Text(L("MENU_CARGANDO"))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Theme.darkPurple.opacity(0.85)))
                }
            }
            .frame(height: backBarHeight)

            Spacer(minLength: 0)

            // ── Cuadrícula de niveles ────────────────────────────────────
            VStack(spacing: spacing) {
                ForEach(rows.indices, id: \.self) { r in
                    HStack(spacing: spacing) {
                        ForEach(rows[r]) { level in
                            Button {
                                model.tapLevel(level.id)
                            } label: {
                                LevelCardView(level: level)
                                    .frame(width: cardSize, height: cardSize)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .opacity(model.bridge.engineReady ? 1 : 0.6)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(padding)
        .frame(width: size.width, height: size.height)
    }
}
