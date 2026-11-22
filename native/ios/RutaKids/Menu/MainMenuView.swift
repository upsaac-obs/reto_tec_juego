import SwiftUI

// MARK: - Pantalla de inicio
// Fondo postal de Puebla (lote 10, "bg_home": el auto y el copiloto saludando a la
// izquierda), Jugar grande en el centro libre, estrellas arriba al centro y el engrane
// arriba a la derecha (toque: Opciones; mantenido 3 s: Tutores).

struct MainMenuView: View {
    let model: AppModel

    var body: some View {
        NavigationStack {
            ZStack {
                MenuBackground(image: "bg_home")

                VStack {
                    HStack(alignment: .center) {
                        Color.clear.frame(width: Theme.cornerButton, height: Theme.cornerButton)
                        Spacer()
                        StarsBanner(total: model.store.totalStars, max: model.store.maxStars)
                        Spacer()
                        OpcionesButton(
                            onTap: {
                                AudioManager.shared.playSound(named: "menu_tap")
                                model.showOptions = true
                            },
                            onLongPress: { model.openTutors() }
                        )
                    }
                    .padding(16)
                    Spacer()
                }

                JugarButton(loading: !model.bridge.engineReady || model.bridge.starting) {
                    AudioManager.shared.playSound(named: "menu_tap")
                    model.play()
                }
                .padding(.top, 24)
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

// MARK: - Botón JUGAR (lote 10: "btn_play", dorado con aro rojo)

private struct JugarButton: View {
    /// Godot todavía está arrancando: el botón se ve apagado con un indicador.
    let loading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Image("btn_play")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 170, height: 170)
                    .opacity(loading ? 0.6 : 1)
                if loading {
                    // "Cargando…": Godot arranca en segundo plano mientras se ve el menú.
                    VStack(spacing: 8) {
                        ProgressView().tint(Theme.gold)
                        Text(L("MENU_CARGANDO"))
                            .font(.fredoka(14, .bold))
                            .foregroundColor(.white)
                    }
                    .padding(10)
                    .background(Capsule().fill(Theme.darkPurple.opacity(0.85)))
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(loading)
        .accessibilityLabel(L("MENU_JUGAR"))
    }
}

// MARK: - Botón OPCIONES (lote 10: "btn_tutors"; toque: Opciones; 3 s: Tutores)

private struct OpcionesButton: View {
    let onTap: () -> Void
    let onLongPress: () -> Void
    /// Para que soltar después de los 3 s no cuente también como toque corto.
    @State private var longPressed = false

    var body: some View {
        Image("btn_tutors")
            .resizable()
            .scaledToFit()
            .frame(width: Theme.cornerButton, height: Theme.cornerButton)
            .contentShape(Circle())
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
