import SwiftUI

/// Menú nativo del spike. Los textos están fijos porque es una prueba; en la
/// app real salen de textos.csv (H8).
struct MenuView: View {
    let bridge: RutaBridge

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("RutaKids · spike iOS").font(.largeTitle).foregroundStyle(.white)
                if bridge.engineReady {
                    Text("Godot listo en \(bridge.readyMs ?? 0) ms").foregroundStyle(gold)
                } else {
                    HStack { ProgressView().tint(gold); Text("Cargando Godot…").foregroundStyle(.white) }
                }
                ForEach([(0, "Nivel 0 · tutorial"), (1, "Nivel 1 · Primero el peatón"),
                         (2, "Nivel 2 · Respeta las señales"), (99, "Nivel 99 · botones")], id: \.0) { id, name in
                    Button("\(name) (\(bridge.bestStars[id] ?? 0)★)") { bridge.startLevel(id) }
                        .buttonStyle(.borderedProminent)
                        .disabled(!bridge.engineReady || bridge.cyclesRunning)
                }
                Button("Abrir y cerrar 10 veces") { bridge.startCycles() }
                    .buttonStyle(.bordered)
                    .disabled(!bridge.engineReady || bridge.cyclesRunning)
                Text("Último resultado: \(bridge.lastResult)").foregroundStyle(.white)
                if !bridge.cycleMemoryMB.isEmpty {
                    Text("Memoria por ciclo (MB): \(bridge.cycleMemoryMB.map(String.init).joined(separator: ", "))")
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mensajes del puente").foregroundStyle(gold)
                    ForEach(Array(bridge.log.enumerated()), id: \.offset) { _, line in
                        Text(line).font(.caption).foregroundStyle(.white)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0x3F / 255, green: 0x1B / 255, blue: 0x4E / 255))
    }

    private var gold: Color { Color(red: 1, green: 0xC7 / 255, blue: 0) }
}
