import CoreText
import SwiftUI

// MARK: - Textos
// Todo texto visible sale de i18n/textos.csv (tools/gen_strings.py lo copia a
// Resources/es.lproj/Localizable.strings). Si falta una clave, se ve la clave.

func L(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}

// MARK: - Fuente
// Fredoka (OFL; Resources/Fonts/Fredoka.ttf y su licencia), la misma de los niveles y de
// Android. Se registra al abrir la app (no hace falta UIAppFonts en el Info.plist). Es
// variable: .weight() elige el grosor.

func registerAppFonts() {
    let url = Bundle.main.url(forResource: "Fredoka", withExtension: "ttf")
        ?? Bundle.main.url(forResource: "Fredoka", withExtension: "ttf", subdirectory: "Fonts")
    if let url {
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}

extension Font {
    static func fredoka(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .custom("Fredoka", size: size).weight(weight)
    }
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
    /// Pasto del mapa de niveles: rellena alrededor si la pantalla es más ancha o más alta.
    static let grass      = Color(hex: "5E9A5A")
    /// Botones redondos de las esquinas (Regresar, Opciones/Tutores).
    static let cornerButton: CGFloat = 58
}

// MARK: - Estilo de botón con efecto de escala al pulsar

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Fondo (lote 10: "bg_menus" en los menús y "bg_home" en Inicio)

struct MenuBackground: View {
    var image: String = "bg_menus"

    var body: some View {
        ZStack {
            if UIImage(named: image) != nil {
                Image(image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [Color(hex: "4A235A"), Color(hex: "9C4B79"), Color(hex: "E86F56")],
                    startPoint: .top, endPoint: .bottom
                )
            }
        }
        .clipped()
        .ignoresSafeArea()
    }
}

// MARK: - Botón de retroceso (lote 10: "btn_back", botón caramelo morado)

struct BackButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image("btn_back")
                .resizable()
                .scaledToFit()
                .frame(width: Theme.cornerButton, height: Theme.cornerButton)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(L("MENU_REGRESAR"))
    }
}

// MARK: - Estrellas (0 a 3)
// Las llenas son las que se ganaron en el nivel; las vacías, las que faltan (lote 10).

struct StarsRow: View {
    let earned: Int
    var size: CGFloat = 18
    var showEmpty: Bool = true

    var body: some View {
        HStack(spacing: size * 0.05) {
            ForEach(0..<3, id: \.self) { index in
                if index < earned || showEmpty {
                    Image(index < earned ? "star_full" : "star_empty")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(earned) / 3")
    }
}

// MARK: - Barra con el total de estrellas

struct StarsBanner: View {
    let total: Int
    let max: Int

    var body: some View {
        HStack(spacing: 8) {
            Image("star_full")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
            Text("\(total) / \(max)")
                .font(.fredoka(22, .bold))
                .foregroundColor(Theme.gold)
        }
        .padding(.leading, 8)
        .padding(.trailing, 18)
        .padding(.vertical, 4)
        .background(Capsule().fill(Theme.darkPurple.opacity(0.88)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(total) / \(max) ★")
    }
}
