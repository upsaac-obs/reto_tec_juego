import AVFoundation
import Combine
import SwiftUI

// MARK: - Gestor de audio global
// Viene de whoisdiego/menuIOS. Cambios: guarda los ajustes en UserDefaults y ya no
// es @MainActor, para poder llamarlo desde AppModel sin reglas de aislamiento.
// Los archivos "bg_music.mp3" y "tap.mp3" aún no están en el proyecto: sin ellos no suena
// nada y no pasa nada (ver "ASSETS de menu de IOS/README.md").

final class AudioManager: ObservableObject {

    static let shared = AudioManager()

    // MARK: Estado publicado

    @Published var isMusicEnabled: Bool {
        didSet {
            defaults.set(isMusicEnabled, forKey: "audio_music_on")
            isMusicEnabled ? resumeMusic() : pauseMusic()
        }
    }

    @Published var isSoundEnabled: Bool {
        didSet { defaults.set(isSoundEnabled, forKey: "audio_sound_on") }
    }

    @Published var musicVolume: Float {
        didSet {
            defaults.set(musicVolume, forKey: "audio_music_volume")
            musicPlayer?.volume = isMusicEnabled ? musicVolume : 0
        }
    }

    @Published var soundVolume: Float {
        didSet { defaults.set(soundVolume, forKey: "audio_sound_volume") }
    }

    // MARK: Privado

    private let defaults = UserDefaults.standard
    private var musicPlayer: AVAudioPlayer?

    private init() {
        // Los observadores didSet no se ejecutan al asignar dentro del init.
        isMusicEnabled = defaults.object(forKey: "audio_music_on") as? Bool ?? true
        isSoundEnabled = defaults.object(forKey: "audio_sound_on") as? Bool ?? true
        musicVolume = defaults.object(forKey: "audio_music_volume") as? Float ?? 0.7
        soundVolume = defaults.object(forKey: "audio_sound_volume") as? Float ?? 1.0
        configureSession()
        prepareMusic()
    }

    // MARK: Sesión de audio

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient, mode: .default, options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioManager: error configurando sesión – \(error)")
        }
    }

    // MARK: Música de fondo
    // Coloca el archivo de música en el bundle con el nombre "bg_music.mp3".

    private func prepareMusic() {
        guard let url = Bundle.main.url(forResource: "bg_music", withExtension: "mp3") else { return }
        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = -1   // loop infinito
            musicPlayer?.volume = musicVolume
            musicPlayer?.prepareToPlay()
            if isMusicEnabled { musicPlayer?.play() }
        } catch {
            print("AudioManager: no se pudo cargar bg_music – \(error)")
        }
    }

    func resumeMusic() {
        musicPlayer?.volume = musicVolume
        musicPlayer?.play()
    }

    func pauseMusic() {
        musicPlayer?.pause()
    }

    // MARK: Efectos de sonido
    // AudioManager.shared.playSound(named: "tap")

    private var activePlayers: [AVAudioPlayer] = []

    func playSound(named name: String, extension ext: String = "mp3") {
        guard isSoundEnabled else { return }
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = soundVolume
            player.play()
            // Se guarda una referencia hasta que termine; si no, el sonido se corta al liberarse.
            activePlayers.removeAll { !$0.isPlaying }
            activePlayers.append(player)
        } catch {
            print("AudioManager: no se pudo reproducir \(name) – \(error)")
        }
    }
}
