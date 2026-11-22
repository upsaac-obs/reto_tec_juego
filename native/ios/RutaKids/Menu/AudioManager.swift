// Creación y desarrollo: Dylan Isaac Mancilla López, Diego Sánchez López
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
            // .playback: la voz del copiloto es parte de la enseñanza, así que suena aunque el
            // iPhone esté en silencio (con .ambient, el interruptor de silencio callaba todo).
            // Godot usa la misma categoría (project.godot, audio/general/ios/session_category).
            try AVAudioSession.sharedInstance().setCategory(
                .playback, mode: .default, options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioManager: error configurando sesión – \(error)")
        }
    }

    // MARK: Música de fondo
    // Resources/Audio/menu_music.m4a (la música del juego; tools/menu_sounds.sh). M4A porque
    // AVAudioPlayer no lee .ogg.

    private func url(_ name: String, _ ext: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: ext)
            ?? Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Audio")
    }

    private func prepareMusic() {
        guard let url = url("menu_music", "m4a") else { return }
        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = -1   // loop infinito
            musicPlayer?.volume = musicVolume
            musicPlayer?.prepareToPlay()
            if isMusicEnabled { musicPlayer?.play() }
        } catch {
            print("AudioManager: no se pudo cargar menu_music – \(error)")
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
    // menu_tap (botones), menu_locked (parada cerrada), menu_unlock (el auto llega a una
    // parada nueva). Resources/Audio/, de tools/menu_sounds.sh.

    private var activePlayers: [AVAudioPlayer] = []

    func playSound(named name: String, extension ext: String = "m4a") {
        guard isSoundEnabled else { return }
        guard let url = url(name, ext) else { return }
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
