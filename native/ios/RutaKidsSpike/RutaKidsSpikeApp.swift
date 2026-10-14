import SwiftGodot
import SwiftGodotKit
import SwiftUI

/// Spike de la arquitectura híbrida en iOS (docs/arquitectura.md, sección 6).
/// Godot arranca una sola vez y nunca se destruye entre niveles (H1): su vista
/// siempre existe y el menú nativo se pone encima mientras no hay nivel abierto.
@main
struct RutaKidsSpikeApp: App {
    @State private var godot = GodotApp(packFile: "main.pck")
    @State private var bridge = RutaBridge()

    var body: some Scene {
        WindowGroup {
            SpikeView(app: godot, bridge: bridge)
        }
    }
}

private struct SpikeView: View {
    let app: GodotApp
    let bridge: RutaBridge
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            GodotAppView(onReady: { handle in
                bridge.connect(app: app, handle: handle)
            })
            .ignoresSafeArea()

            if !bridge.playing {
                MenuView(bridge: bridge)
            }
        }
        .environment(\.godotApp, app)
        .persistentSystemOverlays(.hidden)
        .statusBarHidden()
        // Sección 4, paso 6: segundo plano y llamadas entrantes.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { bridge.resumeLevel() } else { bridge.pauseLevel() }
        }
    }
}
