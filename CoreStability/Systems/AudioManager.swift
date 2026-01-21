// AudioManager.swift
// CoreStability
// Manages sound effects and background music with volume controls

import AVFoundation
import AudioToolbox

final class AudioManager {
    static let shared = AudioManager()
    
    // MARK: - Background Music
    
    private var backgroundMusicPlayer: AVAudioPlayer?
    private(set) var isMusicPlaying: Bool = false
    
    // MARK: - Volume Controls
    
    /// Master volume (0.0 - 1.0)
    var masterVolume: Float = 1.0 {
        didSet {
            masterVolume = max(0, min(1, masterVolume))
            updateMusicVolume()
        }
    }
    
    /// Music volume (0.0 - 1.0)
    var musicVolume: Float = 0.7 {
        didSet {
            musicVolume = max(0, min(1, musicVolume))
            updateMusicVolume()
        }
    }
    
    /// SFX volume (0.0 - 1.0)
    var sfxVolume: Float = 1.0 {
        didSet { sfxVolume = max(0, min(1, sfxVolume)) }
    }
    
    /// Music enabled toggle
    var isMusicEnabled: Bool = true {
        didSet {
            if isMusicEnabled {
                resumeBackgroundMusic()
            } else {
                pauseBackgroundMusic()
            }
        }
    }
    
    /// SFX enabled toggle
    var isSFXEnabled: Bool = true
    
    private var isMuted: Bool = false
    
    private init() {
        // Configure Audio Session for mixing with other audio
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio setup error: \(error)")
        }
        
        // Prepare background music
        prepareBackgroundMusic()
    }
    
    // MARK: - Background Music Functions
    
    /// Prepares the background music player (call during init)
    private func prepareBackgroundMusic() {
        // Look for music file in bundle
        let musicFiles = ["bgm_arcade", "background_music", "game_music"]
        
        for fileName in musicFiles {
            if let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") {
                do {
                    backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
                    backgroundMusicPlayer?.numberOfLoops = -1 // Loop forever
                    backgroundMusicPlayer?.volume = musicVolume * masterVolume
                    backgroundMusicPlayer?.prepareToPlay()
                    print("✅ Background music loaded: \(fileName).mp3")
                    return
                } catch {
                    print("Failed to load \(fileName): \(error)")
                }
            }
        }
        
        // Try m4a format
        for fileName in musicFiles {
            if let url = Bundle.main.url(forResource: fileName, withExtension: "m4a") {
                do {
                    backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
                    backgroundMusicPlayer?.numberOfLoops = -1
                    backgroundMusicPlayer?.volume = musicVolume * masterVolume
                    backgroundMusicPlayer?.prepareToPlay()
                    print("✅ Background music loaded: \(fileName).m4a")
                    return
                } catch {
                    print("Failed to load \(fileName): \(error)")
                }
            }
        }
        
        print("⚠️ No background music file found. Add 'bgm_arcade.mp3' to bundle.")
    }
    
    /// Starts background music (call after user interaction - e.g., tap to start)
    func startBackgroundMusic() {
        guard canPlayMusic else {
            print("Music disabled or muted")
            return
        }
        
        guard let player = backgroundMusicPlayer else {
            print("No music player prepared")
            return
        }
        
        if !player.isPlaying {
            player.play()
            isMusicPlaying = true
            print("🎵 Background music started")
        }
    }
    
    /// Pauses background music
    func pauseBackgroundMusic() {
        backgroundMusicPlayer?.pause()
        isMusicPlaying = false
    }
    
    /// Resumes background music
    func resumeBackgroundMusic() {
        guard canPlayMusic, let player = backgroundMusicPlayer else { return }
        
        if !player.isPlaying {
            player.play()
            isMusicPlaying = true
        }
    }
    
    /// Stops background music completely
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer?.currentTime = 0
        isMusicPlaying = false
    }
    
    /// Updates music volume based on master and music volume
    private func updateMusicVolume() {
        let effectiveVolume = masterVolume * musicVolume
        backgroundMusicPlayer?.volume = effectiveVolume
    }
    
    // MARK: - Effective Volume Check
    
    private var canPlaySFX: Bool {
        return !isMuted && isSFXEnabled && masterVolume > 0 && sfxVolume > 0
    }
    
    private var canPlayMusic: Bool {
        return !isMuted && isMusicEnabled && masterVolume > 0 && musicVolume > 0
    }
    
    // MARK: - Game Sounds
    
    func playTowerFire() {
        guard canPlaySFX else { return }
        AudioServicesPlaySystemSound(1104) // Tock
    }
    
    func playEnemyHit() {
        guard canPlaySFX else { return }
        AudioServicesPlaySystemSound(1306) // Pop
    }
    
    func playEnemyDeath() {
        guard canPlaySFX else { return }
        AudioServicesPlaySystemSound(1057) // Short explosion
    }
    
    func playSkillActivate() {
        guard canPlaySFX else { return }
        AudioServicesPlaySystemSound(1117) // Swoosh
    }
    
    func playWaveComplete() {
        guard canPlaySFX else { return }
        AudioServicesPlaySystemSound(1025) // Fanfare short
    }
    
    func playBossSpawn() {
        guard canPlaySFX else { return }
        AudioServicesPlaySystemSound(1073) // Warning
    }
    
    func playGameOver() {
        guard canPlaySFX else { return }
        AudioServicesPlaySystemSound(1073) // Descending
    }
    
    func playButtonTap() {
        guard canPlaySFX else { return }
        AudioServicesPlaySystemSound(1104) // Click
    }
    
    func playSpark() {
        guard canPlaySFX else { return }
        AudioServicesPlaySystemSound(1117) // Swoosh/Zap
    }
    
    func playUpgrade() {
        guard canPlaySFX else { return }
        AudioServicesPlaySystemSound(1057) // Level up
    }
    
    func playCoinCollect() {
        guard canPlaySFX else { return }
        AudioServicesPlaySystemSound(1016) // Coin
    }
    
    func playShopOpen() {
        guard canPlaySFX else { return }
        AudioServicesPlaySystemSound(1103) // Tink
    }
    
    func playCriticalHit() {
        guard canPlaySFX else { return }
        AudioServicesPlaySystemSound(1057) // Impact
    }
    
    func playPerfectClear() {
        guard canPlaySFX else { return }
        AudioServicesPlaySystemSound(1025) // Celebration
    }
    
    // MARK: - Settings
    
    func toggleMute() {
        isMuted = !isMuted
        if isMuted {
            pauseBackgroundMusic()
        } else if isMusicEnabled {
            resumeBackgroundMusic()
        }
    }
    
    func toggleMusic() {
        isMusicEnabled = !isMusicEnabled
    }
    
    func toggleSFX() {
        isSFXEnabled = !isSFXEnabled
    }
    
    var muted: Bool {
        get { isMuted }
        set {
            isMuted = newValue
            if isMuted {
                pauseBackgroundMusic()
            } else if isMusicEnabled {
                resumeBackgroundMusic()
            }
        }
    }
}

