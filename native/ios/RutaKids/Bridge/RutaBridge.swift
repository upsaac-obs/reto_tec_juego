import Foundation
import SwiftGodot
import SwiftGodotKit

/// Puente con Godot (contrato en docs/arquitectura.md, sección 3). No guarda nada ni
/// conoce las pantallas: solo manda comandos y avisa de los eventos con closures.
///
/// En iOS Godot no registra un singleton: la app busca el nodo
/// /root/BridgeClient/HostBridge y le habla con un solo texto "nombre|json":
/// - Nativo → Godot: HostBridge.receive_packet("start_level|{...}")
/// - Godot → nativo: señal HostBridge.message("level_started|{...}")
@Observable
final class RutaBridge {
    /// Godot ya arrancó y está esperando en la escena vacía (engine_ready).
    private(set) var engineReady = false
    /// Hay un nivel abierto: la vista de Godot va al frente y el menú se esconde.
    private(set) var playing = false
    /// Se mandó start_level y todavía no llega level_started ni un error.
    private(set) var starting = false
    private(set) var currentLevel: Int?
    private(set) var lastError: String?

    /// level_finished: el nativo guarda el resultado, pero la vista NO se cierra todavía.
    @ObservationIgnored var onLevelFinished: ((LevelResult) -> Void)?
    /// level_exited: la vista de Godot se esconde. completed dice si antes hubo level_finished.
    @ObservationIgnored var onLevelExited: ((_ levelId: Int, _ completed: Bool) -> Void)?
    /// El niño mantuvo presionado el engrane 3 s dentro del nivel (el nivel ya quedó en pausa).
    @ObservationIgnored var onTutorRequested: (() -> Void)?
    /// Kiosco: 60 s sin tocar la pantalla dentro de un nivel.
    @ObservationIgnored var onInactivityTimeout: (() -> Void)?
    /// El nivel existe en los datos pero todavía no tiene escena (level_not_built).
    @ObservationIgnored var onLevelNotBuilt: ((_ levelId: Int) -> Void)?

    @ObservationIgnored private var app: GodotApp?
    @ObservationIgnored private var host: Node?
    @ObservationIgnored private var messageConnection: Callable?
    @ObservationIgnored private var pendingLevel: Int?

    // MARK: Conexión

    func connect(app: GodotApp, handle: GodotAppViewHandle) {
        guard host == nil,
              let node = handle.getRoot()?.findChild(pattern: "HostBridge", recursive: true, owned: false)
        else {
            lastError = "No se encontró HostBridge (¿BridgeClient corre sin la etiqueta ios?)"
            return
        }
        let connection = Callable { [weak self] (packet: String) in
            DispatchQueue.main.async { self?.received(packet) }
        }
        guard node.connect(signal: "message", callable: connection) == .ok else {
            lastError = "No se pudo conectar a HostBridge.message"
            return
        }
        self.app = app
        host = node
        messageConnection = connection
        // HostBridge guardó engine_ready y lo entrega al recibir "connect".
        send("connect")
    }

    // MARK: Nativo → Godot

    func startLevel(_ id: Int, mode: String, kiosk: Bool, muted: Bool) {
        guard engineReady, !starting, !playing else { return }
        starting = true
        pendingLevel = id
        send("start_level", #"{"v":1,"level_id":\#(id),"mode":"\#(mode)","kiosk":\#(kiosk),"muted":\#(muted)}"#)
        // Si Godot no contesta nunca, no dejamos el menú bloqueado.
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let self, self.starting, !self.playing else { return }
            self.starting = false
        }
    }

    func pauseLevel() { if playing { send("pause_level") } }
    func resumeLevel() { if playing { send("resume_level") } }
    func abortLevel() { if playing || starting { send("abort_level") } }
    func setMuted(_ muted: Bool) { send("set_muted", muted ? "true" : "false") }

    private func send(_ command: String, _ json: String = "") {
        let packet = "\(command)|\(json)"
        app?.runOnGodotThread { [weak self] in
            _ = self?.host?.call(method: "receive_packet", Variant(packet))
        }
    }

    // MARK: Godot → nativo

    private func received(_ packet: String) {
        let parts = packet.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
        let event = String(parts[0])
        let json = parts.count > 1 ? String(parts[1]) : "{}"
        let data = (try? JSONSerialization.jsonObject(with: Data(json.utf8))) as? [String: Any] ?? [:]
        switch event {
        case "engine_ready":
            engineReady = true
        case "level_started":
            starting = false
            playing = true
            currentLevel = Self.int(data["level_id"])
        case "level_finished":
            if let result = Self.result(from: data) { onLevelFinished?(result) }
        case "level_exited":
            let id = Self.int(data["level_id"]) ?? currentLevel ?? -1
            let completed = (data["completed"] as? Bool) ?? false
            starting = false
            playing = false
            currentLevel = nil
            onLevelExited?(id, completed)
        case "tutor_requested":
            // El nivel ya se pausó solo; la app abre Tutores.
            pauseLevel()
            onTutorRequested?()
        case "inactivity_timeout":
            onInactivityTimeout?()
        case "bridge_error":
            let code = data["code"] as? String ?? ""
            lastError = "\(code) \(data["detail"] as? String ?? "")"
            starting = false
            if code == "level_not_built" || code == "unknown_level" {
                onLevelNotBuilt?(pendingLevel ?? -1)
            }
        default:
            break
        }
    }

    // MARK: JSON

    private static func int(_ value: Any?) -> Int? {
        (value as? NSNumber)?.intValue
    }

    private static func result(from data: [String: Any]) -> LevelResult? {
        guard let id = int(data["level_id"]), let stars = int(data["stars"]) else { return nil }
        var infractions: [String: Int] = [:]
        for (rule, count) in data["infractions"] as? [String: Any] ?? [:] {
            if let n = int(count) { infractions[rule] = n }
        }
        return LevelResult(
            levelId: id,
            stars: stars,
            points: int(data["points"]) ?? 0,
            infractions: infractions,
            durationSeconds: int(data["duration_s"]) ?? 0
        )
    }
}
