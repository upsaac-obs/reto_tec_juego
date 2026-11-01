import SwiftUI

// MARK: - Pantalla de inicio (diseño de whoisdiego/menuIOS)
// Jugar y Opciones, en el mismo lugar. Opciones, mantenido 3 s, abre Tutores.

struct MainMenuView: View {
    let model: AppModel

    var body: some View {
        NavigationStack {
            ZStack {
                MenuBackground()

                VStack(spacing: 18) {
                    Spacer()

                    JugarButton(loading: !model.bridge.engineReady || model.bridge.starting) {
                        AudioManager.shared.playSound(named: "tap")
                        model.play()
                    }

                    OpcionesButton(
                        onTap: {
                            AudioManager.shared.playSound(named: "tap")
                            model.showOptions = true
                        },
                        onLongPress: { model.openTutors() }
                    )

                    Spacer()
                }
            }
            .statusBar(hidden: true)
            .navigationDestination(isPresented: Bindable(model).showLevels) {
                LevelSelectView(model: model)
                    .navigationBarBackButtonHidden(true)
            }
            .sheet(isPresented: Bindable(model).showOptions) {
                OptionsView()
            }
        }
    }
}

// MARK: - Botón JUGAR

private struct JugarButton: View {
    /// Godot todavía está arrancando: el botón se ve apagado con un indicador.
    let loading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if UIImage(named: "btn_jugar") != nil {
                    // Si existe el asset completo del botón, se usa directo
                    Image("btn_jugar")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 4)
                } else {
                    // Reemplazo mientras no llegue la imagen
                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "5C3499"), Color(hex: "3B1F6A")],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                        RoundedRectangle(cornerRadius: 28)
                            .strokeBorder(Color(hex: "D42F35"), lineWidth: 4)

                        VStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)

                            Text(L("MENU_JUGAR"))
                                .textCase(.uppercase)
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .italic()
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 2)
                        }
                    }
                    .frame(width: 180, height: 180)
                    .shadow(color: .black.opacity(0.45), radius: 8, x: 0, y: 5)
                }
                if loading {
                    // "Cargando…": Godot arranca en segundo plano mientras se ve el menú.
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.black.opacity(0.35))
                        .frame(width: 180, height: 180)
                    VStack(spacing: 8) {
                        ProgressView().tint(Theme.gold)
                        Text(L("MENU_CARGANDO"))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(loading)
    }
}

// MARK: - Botón OPCIONES (toque: Opciones; 3 s: Tutores)

private struct OpcionesButton: View {
    let onTap: () -> Void
    let onLongPress: () -> Void
    /// Para que soltar después de los 3 s no cuente también como toque corto.
    @State private var longPressed = false

    var body: some View {
        Group {
            if UIImage(named: "btn_opciones") != nil {
                Image("btn_opciones")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 56)
                    .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 3)
            } else {
                // Cápsula roja con engranaje, mientras no llegue la imagen
                HStack(spacing: 10) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20, weight: .bold))
                    Text(L("MENU_OPCIONES"))
                        .textCase(.uppercase)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "D9302F"), Color(hex: "9B1F1F")],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .overlay(Capsule().strokeBorder(Color(hex: "FF6860"), lineWidth: 2))
                )
                .shadow(color: .black.opacity(0.4), radius: 5, x: 0, y: 3)
            }
        }
        .contentShape(Rectangle())
        // Una sola vista con dos gestos: toque corto abre Opciones, 3 s abre Tutores.
        .onLongPressGesture(minimumDuration: 3) {
            longPressed = true
            onLongPress()
        }
        .simultaneousGesture(TapGesture().onEnded {
            if longPressed {
                longPressed = false
            } else {
                onTap()
            }
        })
        .accessibilityLabel(L("MENU_OPCIONES"))
        .accessibilityAddTraits(.isButton)
    }
}
