import Foundation

/// Une el puente con Godot, el guardado y las pantallas: qué se muestra y cuándo.
@Observable
final class AppModel {
    let store: ProgressStore
    let bridge: RutaBridge

    // Navegación
    var showLevels = false
    var showOptions = false
    var showTutors = false
    /// Mensaje corto sobre la lista de niveles (clave de textos.csv), o nil.
    private(set) var toastKey: String?

    /// Primera vez en Jugar: después del tutorial se abre la lista de niveles.
    @ObservationIgnored private var openLevelsAfterTutorial = false
    /// Un nivel quedó en pausa porque se abrió Tutores desde dentro del juego.
    @ObservationIgnored private var levelPausedForTutors = false
    @ObservationIgnored private var lastTouch = Date()
    @ObservationIgnored private var toastToken = 0
    /// Segundos sin tocar la pantalla (en menús) para volver al inicio en modo kiosco.
    @ObservationIgnored let kioskIdleSeconds: TimeInterval = 60

    init(store: ProgressStore = ProgressStore(), bridge: RutaBridge = RutaBridge()) {
        self.store = store
        self.bridge = bridge
        bridge.onLevelFinished = { [weak self] result in self?.store.record(result) }
        bridge.onLevelExited = { [weak self] id, completed in self?.levelExited(id: id, completed: completed) }
        bridge.onTutorRequested = { [weak self] in self?.tutorRequestedFromLevel() }
        bridge.onInactivityTimeout = { [weak self] in self?.inactivityTimeoutInLevel() }
        bridge.onLevelNotBuilt = { [weak self] _ in self?.showToast("MENU_BLOQUEADO") }
    }

    // MARK: Abrir niveles

    /// Botón Jugar. La primera vez (y fuera del kiosco) abre el tutorial; después, la lista.
    func play() {
        if !store.tutorialDone && !store.kiosk {
            openLevelsAfterTutorial = true
            start(ProgressStore.tutorialLevel)
        } else {
            showLevels = true
        }
    }

    /// Toque en una tarjeta de la lista de niveles.
    func tapLevel(_ id: Int) {
        guard bridge.engineReady else { return }
        guard store.isUnlocked(id) else {
            showToast("MENU_DESBLOQUEAR")
            return
        }
        start(id)
    }

    private func start(_ id: Int) {
        AudioManager.shared.playSound(named: "tap")
        // La música del menú se calla mientras juega Godot; el sonido del juego respeta Opciones.
        AudioManager.shared.pauseMusic()
        bridge.startLevel(
            id,
            mode: store.mode ?? ProgressStore.modeGrande,
            kiosk: store.kiosk,
            muted: !AudioManager.shared.isSoundEnabled
        )
    }

    private func levelExited(id: Int, completed: Bool) {
        if AudioManager.shared.isMusicEnabled { AudioManager.shared.resumeMusic() }
        if openLevelsAfterTutorial {
            openLevelsAfterTutorial = false
            showLevels = true
        }
        // Un nivel que se cerró mientras Tutores estaba abierto ya no hay que reanudarlo.
        levelPausedForTutors = false
    }

    // MARK: Tutores

    /// Presión larga de 3 s en Opciones (menú).
    func openTutors() {
        showTutors = true
    }

    private func tutorRequestedFromLevel() {
        levelPausedForTutors = true
        showTutors = true
    }

    /// Se cerró la hoja de Tutores. Si venía de un nivel, sigue o se cierra según el kiosco.
    func tutorsClosed() {
        guard levelPausedForTutors else { return }
        levelPausedForTutors = false
        if store.kiosk {
            // Se activó el kiosco desde dentro de un nivel: se cierra y se vuelve al inicio.
            bridge.abortLevel()
        } else {
            bridge.resumeLevel()
        }
    }

    func setKiosk(_ value: Bool) {
        store.setKiosk(value)
        if value {
            showTutors = false
            goHome()
        }
    }

    // MARK: Kiosco: volver al inicio sin tocar

    func touched() { lastTouch = Date() }

    /// Se llama cada segundo desde la vista raíz.
    func tick() {
        guard store.kiosk, !bridge.playing, !bridge.starting, !showTutors else {
            return
        }
        if Date().timeIntervalSince(lastTouch) > kioskIdleSeconds { goHome() }
    }

    private func inactivityTimeoutInLevel() {
        bridge.abortLevel()
        goHome()
    }

    func goHome() {
        showLevels = false
        showOptions = false
        lastTouch = Date()
    }

    // MARK: Segundo plano

    func appBecameInactive() { bridge.pauseLevel() }

    func appBecameActive() {
        // Con Tutores abierto sobre un nivel, el nivel sigue en pausa hasta cerrar la hoja.
        if !showTutors { bridge.resumeLevel() }
    }

    // MARK: Avisos

    func showToast(_ key: String) {
        toastKey = key
        toastToken += 1
        let token = toastToken
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self, self.toastToken == token else { return }
            self.toastKey = nil
        }
    }
}
