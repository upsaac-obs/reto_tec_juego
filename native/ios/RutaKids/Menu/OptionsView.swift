import SwiftUI

// MARK: - Menú de opciones (diseño de whoisdiego/menuIOS)

struct OptionsView: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var audio = AudioManager.shared

    var body: some View {
        ZStack {
            MenuBackground()

            VStack(spacing: 0) {
                // ── Título ──────────────────────────────────────────────
                Text(L("MENU_OPCIONES"))
                    .textCase(.uppercase)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                    .padding(.top, 32)

                // ── Panel ────────────────────────────────────────────────
                VStack(spacing: 20) {

                    // Música
                    OptionRow(
                        icon: "music.note",
                        label: L("MENU_MUSICA"),
                        isOn: $audio.isMusicEnabled,
                        volume: $audio.musicVolume
                    )

                    Divider().background(Color.white.opacity(0.3))

                    // Sonido
                    OptionRow(
                        icon: "speaker.wave.2.fill",
                        label: L("MENU_SONIDO"),
                        isOn: $audio.isSoundEnabled,
                        volume: $audio.soundVolume
                    )
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "2E1660").opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(Color(hex: "D42F35"), lineWidth: 2)
                        )
                )
                .padding(.horizontal, 40)
                .padding(.top, 24)

                Spacer()

                // ── Botón cerrar ─────────────────────────────────────────
                Button {
                    dismiss()
                } label: {
                    Text(L("MENU_CERRAR"))
                        .textCase(.uppercase)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color(hex: "D9302F"))
                                .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 3)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, 32)
            }
        }
        .statusBar(hidden: true)
    }
}

// MARK: - Fila de opción (toggle + slider)

private struct OptionRow: View {
    let icon: String
    let label: String
    @Binding var isOn: Bool
    @Binding var volume: Float

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color(hex: "F5C531"))
                    .frame(width: 30)

                Text(label)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(Color(hex: "F5C531"))
            }

            // Slider de volumen (desactivado si el toggle está apagado)
            HStack(spacing: 10) {
                Image(systemName: "speaker.fill")
                    .foregroundColor(.white.opacity(isOn ? 0.7 : 0.3))
                    .font(.system(size: 14))

                Slider(value: $volume, in: 0...1)
                    .tint(Color(hex: "F5C531"))
                    .disabled(!isOn)
                    .opacity(isOn ? 1 : 0.4)

                Image(systemName: "speaker.wave.3.fill")
                    .foregroundColor(.white.opacity(isOn ? 0.7 : 0.3))
                    .font(.system(size: 14))
            }
        }
    }
}
