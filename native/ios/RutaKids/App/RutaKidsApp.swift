import SwiftGodot
import SwiftGodotKit
import SwiftUI

/// App de iOS de RutaKids: menú nativo en SwiftUI y Godot incrustado para los niveles.
/// Godot arranca una sola vez y nunca se destruye entre niveles (docs/arquitectura.md, H1):
/// su vista siempre existe y el menú se pone encima mientras no hay nivel abierto.
@main
struct RutaKidsApp: App {
    @State private var godot = GodotApp(packFile: "main.pck")
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView(app: godot, model: model)
        }
    }
}

struct RootView: View {
    let app: GodotApp
    let model: AppModel
    @Environment(\.scenePhase) private var scenePhase

    private let secondTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            GodotAppView(onReady: { handle in
                model.bridge.connect(app: app, handle: handle)
            })
            .ignoresSafeArea()

            if !model.bridge.playing {
                MainMenuView(model: model)
                    // Cualquier toque cuenta como "alguien está usando la pantalla" (kiosco).
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0).onChanged { _ in model.touched() }
                    )
            }
        }
        .environment(\.godotApp, app)
        .persistentSystemOverlays(.hidden)
        .statusBarHidden()
        // Primera vez: elegir Peque o Grande antes de empezar.
        .fullScreenCover(isPresented: .constant(model.store.mode == nil)) {
            AgeSelectView { mode in model.store.setMode(mode) }
        }
        .sheet(isPresented: Bindable(model).showTutors, onDismiss: { model.tutorsClosed() }) {
            TutorsView(model: model)
        }
        // Segundo plano y llamadas entrantes: el nivel se pausa y reanuda (sección 4, paso 6).
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.appBecameActive() } else { model.appBecameInactive() }
        }
        .onReceive(secondTimer) { _ in model.tick() }
    }
}
