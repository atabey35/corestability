// GameStats.swift
// CoreStability
// Tracks game statistics for end-of-game dashboard

import Foundation

final class GameStats {
    static let shared = GameStats()
    
    // Current game stats
    var enemiesKilled: Int = 0
    var bossesKilled: Int = 0
    var totalDamageDealt: CGFloat = 0
    var maxCombo: Int = 0
    var coinsEarned: Int = 0
    var wavesCompleted: Int = 0
    var skillsUsed: Int = 0
    var timePlayed: TimeInterval = 0
    
    private init() {}
    
    func reset() {
        enemiesKilled = 0
        bossesKilled = 0
        totalDamageDealt = 0
        maxCombo = 0
        coinsEarned = 0
        wavesCompleted = 0
        skillsUsed = 0
        timePlayed = 0
    }
    
    func recordKill(isBoss: Bool) {
        enemiesKilled += 1
        if isBoss { bossesKilled += 1 }
        // Lifetime Stats
        AchievementManager.shared.recordKill(isBoss: isBoss)
    }
    
    func recordDamage(_ amount: CGFloat) {
        totalDamageDealt += amount
    }
    
    func recordCombo(_ combo: Int) {
        if combo > maxCombo {
            maxCombo = combo
        }
    }
    
    func recordWaveComplete() {
        wavesCompleted += 1
        // Lifetime Stats
        AchievementManager.shared.recordWave(wave: wavesCompleted)
    }
    
    func recordSkillUse() {
        skillsUsed += 1
    }
    
    func recordCoins(_ amount: Int) {
        coinsEarned += amount
    }
    
    // Formatted stats for display
    var formattedDamage: String {
        if totalDamageDealt >= 1_000_000 {
            return String(format: "%.1fM", totalDamageDealt / 1_000_000)
        } else if totalDamageDealt >= 1_000 {
            return String(format: "%.1fK", totalDamageDealt / 1_000)
        }
        return String(format: "%.0f", totalDamageDealt)
    }
    
    var formattedTime: String {
        let minutes = Int(timePlayed) / 60
        let seconds = Int(timePlayed) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

import CoreGraphics
