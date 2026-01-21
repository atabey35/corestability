// AchievementManager.swift
// CoreStability
// Manages persistent achievements and mastery bonuses

import Foundation

enum AchievementType: String, CaseIterable {
    case noviceKiller = "Novice Killer" // 100 Kills
    case veteranKiller = "Veteran Killer" // 1000 Kills
    case bossSlayer = "Boss Slayer" // 10 Bosses
    case millionaire = "Millionaire" // 1000 Total Coins (Lifetime)
}

final class AchievementManager {
    static let shared = AchievementManager()
    
    private let defaults = UserDefaults.standard
    
    // Persistent Stats
    var totalKills: Int {
        get { defaults.integer(forKey: "totalKills") }
        set { defaults.set(newValue, forKey: "totalKills") }
    }
    
    var totalBosses: Int {
        get { defaults.integer(forKey: "totalBosses") }
        set { defaults.set(newValue, forKey: "totalBosses") }
    }
    
    var highestWave: Int {
        get { defaults.integer(forKey: "highestWave") }
        set { defaults.set(newValue, forKey: "highestWave") }
    }
    
    // Bonuses (Calculated)
    var startGoldBonus: Int {
        var bonus = 0
        if totalKills >= 1000 { bonus += 100 }
        if totalBosses >= 10 { bonus += 200 }
        if highestWave >= 50 { bonus += 500 }
        return bonus
    }
    
    var damageBonusMultiplier: Double {
        var mult = 1.0
        if totalKills >= 5000 { mult += 0.1 } // +10%
        return mult
    }
    
    private init() {}
    
    // MARK: - API
    
    func recordKill(isBoss: Bool) {
        totalKills += 1
        if isBoss {
            totalBosses += 1
        }
        checkAchievements()
    }
    
    func recordWave(wave: Int) {
        if wave > highestWave {
            highestWave = wave
        }
    }
    
    private func checkAchievements() {
        // Here we could trigger notifications via GameScene if we had a delegate
        // For now, logic is passive.
    }
    
    func getStatusReport() -> String {
        return """
        Kills: \(totalKills)
        Bosses: \(totalBosses)
        Best Wave: \(highestWave)
        Gold Bonus: +\(startGoldBonus)
        """
    }
}
