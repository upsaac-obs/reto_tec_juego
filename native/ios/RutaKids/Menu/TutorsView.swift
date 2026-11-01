import SwiftUI

// MARK: - Tutores
// Estrellas por hábito y faltas por regla, cambiar de modo, activar el kiosco y borrar el
// progreso con confirmación. Se abre manteniendo 3 s Opciones (menú) o el engrane (nivel).
// Misma información que la pantalla de Tutores de Android.

struct TutorsView: View {
    let model: AppModel
    @State private var confirmReset = false

    private var store: ProgressStore { model.store }

    var body: some View {
        ZStack {
            MenuBackground()

            VStack(spacing: 14) {
                // ── Barra de arriba ─────────────────────────────────────
                HStack(spacing: 16) {
                    BackButton {
                        AudioManager.shared.playSound(named: "tap")
                        model.showTutors = false
                    }
                    Text(L("TUTOR_TITULO"))
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(Theme.gold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Theme.darkPurple))
                    Spacer()
                }

                ScrollView {
                    VStack(spacing: 12) {
                        settingsCard
                        progressCard
                        ForEach(ProgressStore.menuLevels, id: \.self) { id in
                            levelRow(id)
                        }
                        Button {
                            confirmReset = true
                        } label: {
                            Text(L("MENU_BORRAR_PROGRESO"))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Theme.banner))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.bottom, 20)
                }
            }
            .padding(20)
        }
        .statusBar(hidden: true)
        .confirmationDialog(
            L("TUTOR_BORRAR_TITULO"),
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button(L("TUTOR_BORRAR_SI"), role: .destructive) { store.resetProgress() }
            Button(L("TUTOR_CANCELAR"), role: .cancel) {}
        } message: {
            Text(L("TUTOR_BORRAR_TEXTO"))
        }
    }

    // MARK: Tarjetas

    private var settingsCard: some View {
        TutorCard {
            CardTitle(L("TUTOR_AJUSTES"))
            HStack {
                Text(L("TUTOR_MODO"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.darkPurple)
                Spacer()
                HStack(spacing: 8) {
                    modeButton(L("MENU_PEQUE"), ProgressStore.modePeque)
                    modeButton(L("MENU_GRANDE"), ProgressStore.modeGrande)
                }
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("MENU_KIOSCO"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.darkPurple)
                    Text(L("TUTOR_KIOSCO_AYUDA"))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Color(hex: "534A5E"))
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { store.kiosk },
                    set: { model.setKiosk($0) }
                ))
                .labelsHidden()
                .tint(Theme.darkPurple)
            }
        }
    }

    private var progressCard: some View {
        TutorCard {
            CardTitle(L("TUTOR_PROGRESO"))
            Text("\(store.totalStars) / \(store.maxStars) ★")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Theme.darkPurple)
        }
    }

    private func levelRow(_ id: Int) -> some View {
        let stars = store.stars(for: id)
        let infractions = store.infractions[id] ?? [:]
        return TutorCard {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(id). \(L(String(format: "NIVEL_%02d_NOMBRE", id)))")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.darkPurple)
                    Text(L(String(format: "DECALOGO_%02d", id)))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Color(hex: "534A5E"))
                    if stars > 0 {
                        Text(infractions.isEmpty
                             ? L("TUTOR_SIN_FALTAS")
                             : infractions.sorted { $0.key < $1.key }
                                .map { "\(ruleName($0.key)): \($0.value)" }
                                .joined(separator: ", "))
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(Color(hex: "534A5E"))
                    }
                }
                Spacer()
                if stars > 0 {
                    StarsRow(earned: stars, size: 20, showEmpty: false)
                        .shadow(color: .black.opacity(0.25), radius: 1, x: 0, y: 1)
                } else {
                    Text("—").foregroundColor(Color(hex: "534A5E"))
                }
            }
        }
    }

    // MARK: Piezas

    private func modeButton(_ title: String, _ mode: String) -> some View {
        let selected = store.mode == mode
        return Button {
            store.setMode(mode)
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(selected ? Theme.darkPurple : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(selected ? Theme.gold : Theme.darkPurple))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    /// Nombre de la regla (REGLA_STOP, REGLA_RED_LIGHT…). Si no hay texto, se muestra el id.
    private func ruleName(_ rule: String) -> String {
        let key = "REGLA_" + rule.uppercased()
        let text = L(key)
        return text == key ? rule : text
    }
}

private struct TutorCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.94)))
    }
}

private struct CardTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 17, weight: .black, design: .rounded))
            .foregroundColor(Theme.banner)
    }
}
