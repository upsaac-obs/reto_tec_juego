import SwiftUI

// MARK: - Textos
// Todo texto visible sale de i18n/textos.csv (tools/gen_strings.py lo copia a
// Resources/es.lproj/Localizable.strings). Si falta una clave, se ve la clave.

func L(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}

// MARK: - Colores (de whoisdiego/menuIOS)

extension Color {
    init(hex: String) {
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(
            red: Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8) & 0xFF) / 255,
            blue: Double(int & 0xFF) / 255
        )
    }
}

enum Theme {
    static let cardTop    = Color(hex: "4A2A85")
    static let cardBottom = Color(hex: "2E1660")
    static let border     = Color(hex: "D42F35")
    static let banner     = Color(hex: "D9302F")
    static let gold       = Color(hex: "F5C531")
    static let darkPurple = Color(hex: "3F1B4E")
}

// MARK: - Estilo de botón con efecto de escala al pulsar

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Fondo (asset "bg_zona_vial", o degradado si no existe)

struct MenuBackground: View {
    var body: some View {
        ZStack {
            if UIImage(named: "bg_zona_vial") != nil {
                Image("bg_zona_vial")
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [Color(hex: "4B2A7B"), Color(hex: "8A3F7A"), Color(hex: "E0524F")],
                    startPoint: .top, endPoint: .bottom
                )
            }
        }
        .clipped()
        .ignoresSafeArea()
    }
}

// MARK: - Botón de retroceso
// Asset: "icon_back" (la imagen completa del botón). Si no existe, dibuja uno de ejemplo.

struct BackButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            if UIImage(named: "icon_back") != nil {
                Image("icon_back")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.black.opacity(0.35), radius: 3, x: 0, y: 2)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 14).fill(Theme.cardTop)
                    RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 3)
                    Image(systemName: "arrowshape.left.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Theme.border)
                }
                .frame(width: 56, height: 56)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(L("MENU_REGRESAR"))
    }
}

// MARK: - Estrellas (0 a 3)
// Las llenas son las que se ganaron en el nivel; las vacías, las que faltan.

struct StarsRow: View {
    let earned: Int
    var size: CGFloat = 18
    var showEmpty: Bool = true

    var body: some View {
        HStack(spacing: size * 0.15) {
            ForEach(0..<3, id: \.self) { index in
                if index < earned {
                    Image(systemName: "star.fill")
                        .foregroundColor(Theme.gold)
                } else if showEmpty {
                    Image(systemName: "star")
                        .foregroundColor(Color.white.opacity(0.55))
                }
            }
        }
        .font(.system(size: size, weight: .bold))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(earned) / 3")
    }
}
