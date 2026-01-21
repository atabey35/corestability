// WaveController.swift
// Idle Tower Defense
// Controls wave progression and difficulty scaling

import Foundation

protocol WaveControllerDelegate: AnyObject {
    func waveController(_ controller: WaveController, didStartWave wave: Int)
    func waveController(_ controller: WaveController, didCompleteWave wave: Int)
}

final class WaveController {
    
    weak var delegate: WaveControllerDelegate?
    
    private(set) var currentWave: Int = 0
    private(set) var isWaveActive: Bool = false
    private var waveCompleteDelay: TimeInterval = 0
    
    private(set) var currentChapter: Int = 1 {
        didSet {
            saveProgress()
        }
    }
    
    // Persistence
    private let defaults = UserDefaults.standard
    private let chapterKey = "playerCurrentChapter"
    
    init() {
        // Load saved chapter
        let savedChapter = defaults.integer(forKey: chapterKey)
        self.currentChapter = savedChapter > 0 ? savedChapter : 1
    }
    
    // MARK: - S-Curve Difficulty Scaling (50 Waves)
    // Phase 1: Waves 1-15 (Tutorial/Learning) - Gentle curve
    // Phase 2: Waves 16-35 (Core Challenge) - Steep curve
    // Phase 3: Waves 36-50 (Epic Endgame) - Exponential
    
    func enemyCountForWave(_ wave: Int) -> Int {
        // S-curve enemy count: starts slow, ramps up mid-game
        let effectiveWave = (currentChapter - 1) * 50 + wave
        if effectiveWave <= 15 {
            return 5 + effectiveWave / 2  // 5-12 enemies
        } else if effectiveWave <= 35 {
            return 12 + (effectiveWave - 15)  // 12-32 enemies
        } else {
            return min(60, 32 + (effectiveWave - 35) * 2)  // 32-60 enemies
        }
    }
    
    func spawnIntervalForWave(_ wave: Int) -> TimeInterval {
        // Faster spawns as waves progress
        let effectiveWave = (currentChapter - 1) * 50 + wave
        if effectiveWave <= 15 {
            return max(1.2, 1.8 - Double(effectiveWave) * 0.04)  // 1.8s -> 1.2s
        } else if effectiveWave <= 35 {
            return max(0.6, 1.2 - Double(effectiveWave - 15) * 0.03)  // 1.2s -> 0.6s
        } else {
            return max(0.3, 0.6 - Double(effectiveWave - 35) * 0.02)  // 0.6s -> 0.3s
        }
    }
    
    func enemyHPForWave(_ wave: Int) -> CGFloat {
        // Infinite Progression Scaling (Cumulative)
        // Base * (1.065 ^ CumulativeWave) - Reduced from 1.09 to allow smoother infinite play
        
        let effectiveWave = CGFloat((currentChapter - 1) * 50 + wave)
        let baseHP: CGFloat = 20.0 
        
        // Wave 50: ~466 HP (manageable)
        // Wave 100: ~10,000 HP (challenging but possible)
        
        return baseHP * pow(1.065, effectiveWave)
    }
    
    func enemyDamageForWave(_ wave: Int) -> CGFloat {
        // Infinite Progression Scaling (Cumulative)
        // Damage needs to outpace Defense (Flat) and keep up with HP (Exponential)
        
        let effectiveWave = CGFloat((currentChapter - 1) * 50 + wave)
        let baseDamage: CGFloat = 8.0 // Increased base
        
        // Wave 51 (P2): 8 * 1.055^51 ≈ 120 Damage
        // Wave 101 (P3): 8 * 1.055^101 ≈ 1800 Damage
        return baseDamage * pow(1.055, effectiveWave)
    }
    
    func enemySpeedForWave(_ wave: Int) -> CGFloat {
        let effectiveWave = (currentChapter - 1) * 50 + wave
        let baseSpeed: CGFloat = 55.0
        
        // Cap speed to preventing "teleporting" enemies at very high waves
        let rawSpeed = baseSpeed + CGFloat(effectiveWave) * 0.4 + log10(CGFloat(effectiveWave + 1)) * 5
        return min(rawSpeed, 220.0) // Hard cap at speed 220
    }
    
    func coinValueForWave(_ wave: Int) -> Int {
        // Coin income must keep up with upgrade costs
        
        let effectiveWave = Double((currentChapter - 1) * 50 + wave)
        let base = 3.5 // Slightly increased base for better start
        
        // Coin Curve: Base * 1.065 ^ Wave
        // Matches new HP scaling so effort/reward ratio stays consistent
        return Int(base * pow(1.065, effectiveWave))
    }
    
    // MARK: - Special Wave Detection
    
    func isMiniBossWave(_ wave: Int) -> Bool {
        // Mini-boss every 5 waves (except boss waves)
        return wave % 5 == 0 && wave % 10 != 0
    }
    
    func isBossWave(_ wave: Int) -> Bool {
        // Boss at waves 10, 20, 30, 40, 50
        return wave % 10 == 0
    }
    
    func shouldSpawnSpecialist(_ wave: Int) -> Bool {
        // Specialists appear from wave 15+
        return wave >= 15
    }
    
    // MARK: - Control
    
    func startNextWave() {
        currentWave += 1
        if currentWave > 50 {
            currentWave = 1
            currentChapter += 1 // This triggers didSet -> saveProgress()
        }
        
        isWaveActive = true
        delegate?.waveController(self, didStartWave: currentWave)
    }
    
    func onWaveComplete() {
        isWaveActive = false
        delegate?.waveController(self, didCompleteWave: currentWave)
    }
    
    func update(deltaTime: TimeInterval, waveComplete: Bool) {
        if isWaveActive && waveComplete {
            waveCompleteDelay -= deltaTime
            if waveCompleteDelay <= 0 {
                onWaveComplete()
                waveCompleteDelay = 2.0  // Delay before next wave
            }
        } else if !isWaveActive {
            waveCompleteDelay -= deltaTime
            if waveCompleteDelay <= 0 {
                startNextWave()
            }
        }
    }
    
    func reset() {
        currentWave = 0
        // Do NOT reset chapter, as user wants to keep progress
        // Only reset if strict permadeath, but usually Idle games keep stages.
        // If user wants to "start from Part 2", we keep currentChapter.
        // If "Game Over" logic requires restarting from Wave 1 of CURRENT chapter, that is fine.
        isWaveActive = false
        waveCompleteDelay = 1.0
    }
    
    func saveProgress() {
        defaults.set(currentChapter, forKey: chapterKey)
    }
    
    /// Test/Dev only: Jump directly to a specific chapter
    func jumpToChapter(_ chapter: Int) {
        currentChapter = chapter
        currentWave = 0
        isWaveActive = false
        waveCompleteDelay = 0.5
    }
}
