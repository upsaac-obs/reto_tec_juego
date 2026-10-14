import Foundation
import SwiftGodot
import SwiftGodotKit

/// Puente con Godot (contrato en docs/arquitectura.md, sección 3).
/// En iOS Godot no registra un singleton: la app busca el nodo
/// /root/BridgeClient/HostBridge y le habla con un solo texto "nombre|json":
/// - Nativo → Godot: HostBridge.receive_packet("start_level|{...}")
/// - Godot → nativo: señal HostBridge.message("level_started|{...}")
@Observable
final class RutaBridge {
    private(set) var engineReady = false
    private(set) var readyMs: Int?
    private(set) var playing = false
    private(set) var lastResult = "—"
    private(set) var log: [String] = []
    /// Guardado nativo del spike (UserDefaults): mejor número de estrellas por nivel.
    private(set) var bestStars: [Int: Int] = [:]
    private(set) var cycleMemoryMB: [Int] = []
    private(set) var cyclesRunning = false

    @ObservationIgnored private var app: GodotApp?
    @ObservationIgnored private var host: Node?
    @ObservationIgnored private var messageConnection: Callable?
    @ObservationIgnored private let launchedAt = Date()
    @ObservationIgnored private var cyclesLeft = 0
    @ObservationIgnored private let defaults = UserDefaults.standard

    init() {
        for id in [0, 1, 2, 99] {
            bestStars[id] = defaults.integer(forKey: "stars_\(id)")
        }
    }

    // MARK: Conexión

    func connect(app: GodotApp, handle: GodotAppViewHandle) {
        guard host == nil,
              let node = handle.getRoot()?.findChild(pattern: "HostBridge", recursive: true, owned: false)
        else {
            addLog("No se encontró HostBridge (¿BridgeClient corre sin la etiqueta ios?)")
            return
        }
        let connection = Callable { [weak self] (packet: String) in
            DispatchQueue.main.async { self?.received(packet) }
        }
        guard node.connect(signal: "message", callable: connection) == .ok else {
            addLog("No se pudo conectar a HostBridge.message")
            return
        }
        self.app = app
        host = node
        messageConnection = connection
        // HostBridge guardó engine_ready y lo entrega al recibir "connect".
        send("connect")
    }

    // MARK: Nativo → Godot

    func startLevel(_ id: Int, mode: String = "grande", kiosk: Bool = false, muted: Bool = false) {
        send("start_level", #"{"v":1,"level_id":\#(id),"mode":"\#(mode)","kiosk":\#(kiosk),"muted":\#(muted)}"#)
    }

    func pauseLevel() { if playing { send("pause_level") } }
    func resumeLevel() { if playing { send("resume_level") } }
    func abortLevel() { send("abort_level") }
    func setMuted(_ muted: Bool) { send("set_muted", muted ? "true" : "false") }

    private func send(_ command: String, _ json: String = "") {
        let packet = "\(command)|\(json)"
        addLog("→ \(packet)")
        app?.runOnGodotThread { [weak self] in
            _ = self?.host?.call(method: "receive_packet", Variant(packet))
        }
    }

    // MARK: Godot → nativo

    private func received(_ packet: String) {
        addLog("← \(packet)")
        let parts = packet.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
        let event = String(parts[0])
        let json = parts.count > 1 ? String(parts[1]) : "{}"
        let data = (try? JSONSerialization.jsonObject(with: Data(json.utf8))) as? [String: Any] ?? [:]
        switch event {
        case "engine_ready":
            engineReady = true
            readyMs = Int(Date().timeIntervalSince(launchedAt) * 1000)
        case "level_started":
            playing = true
        case "level_finished":
            save(data)
        case "level_exited":
            playing = false
            if cyclesLeft > 0 || cyclesRunning { nextCycle() }
        case "inactivity_timeout":
            abortLevel()
        case "bridge_error":
            lastResult = "Error: \(data["code"] ?? "") \(data["detail"] ?? "")"
        default:
            break
        }
    }

    private func save(_ data: [String: Any]) {
        guard let id = (data["level_id"] as? NSNumber)?.intValue,
              let stars = (data["stars"] as? NSNumber)?.intValue else { return }
        let best = max(stars, bestStars[id] ?? 0)
        defaults.set(best, forKey: "stars_\(id)")
        bestStars[id] = best
        let points = (data["points"] as? NSNumber)?.intValue ?? 0
        let seconds = (data["duration_s"] as? NSNumber)?.intValue ?? 0
        lastResult = "Nivel \(id): \(stars)★ (mejor \(best)★), \(points) puntos, faltas \(data["infractions"] ?? [:]), \(seconds) s"
    }

    // MARK: Prueba de 10 ciclos abrir/cerrar (H1, H7)

    func startCycles() {
        guard !cyclesRunning else { return }
        cycleMemoryMB = []
        cyclesLeft = 10
        cyclesRunning = true
        nextCycle()
    }

    private func nextCycle() {
        cycleMemoryMB.append(Self.memoryFootprintMB())
        guard cyclesLeft > 0 else {
            cyclesRunning = false
            addLog("Ciclos terminados. Memoria (MB): \(cycleMemoryMB.map(String.init).joined(separator: ", "))")
            return
        }
        cyclesLeft -= 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.startLevel(99)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self?.abortLevel() }
        }
    }

    /// Memoria física de la app, igual que la que muestra Xcode (phys_footprint).
    static func memoryFootprintMB() -> Int {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Int(info.phys_footprint / 1_048_576) : -1
    }

    private func addLog(_ line: String) {
        print("RutaBridge: \(line)")
        log.insert(line, at: 0)
        if log.count > 30 { log.removeLast() }
    }
}
