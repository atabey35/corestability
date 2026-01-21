// DailyRewardManager.swift
// CoreStability
// Manages daily login rewards and streak tracking

import Foundation

struct DailyReward {
    let day: Int
    let coins: Int
    let gems: Int
    let description: String
    let icon: String
}

final class DailyRewardManager {
    static let shared = DailyRewardManager()
    
    private let defaults = UserDefaults.standard
    private let lastClaimKey = "lastDailyClaimDate"
    private let streakKey = "dailyStreak"
    private let totalDaysKey = "totalLoginDays"
    
    // MARK: - 7-Day Reward Cycle
    
    static let rewards: [DailyReward] = [
        DailyReward(day: 1, coins: 500, gems: 0, description: "500 Coins", icon: "dollarsign.circle.fill"),
        DailyReward(day: 2, coins: 1000, gems: 0, description: "1000 Coins", icon: "dollarsign.circle.fill"),
        DailyReward(day: 3, coins: 0, gems: 10, description: "10 Gems", icon: "diamond.fill"),
        DailyReward(day: 4, coins: 1500, gems: 0, description: "1500 Coins", icon: "dollarsign.circle.fill"),
        DailyReward(day: 5, coins: 0, gems: 25, description: "25 Gems", icon: "diamond.fill"),
        DailyReward(day: 6, coins: 2000, gems: 0, description: "2000 Coins", icon: "dollarsign.circle.fill"),
        DailyReward(day: 7, coins: 0, gems: 50, description: "50 Gems + Chest", icon: "gift.fill")
    ]
    
    // MARK: - Properties
    
    var currentStreak: Int {
        get { defaults.integer(forKey: streakKey) }
        set { defaults.set(newValue, forKey: streakKey) }
    }
    
    var totalLoginDays: Int {
        get { defaults.integer(forKey: totalDaysKey) }
        set { defaults.set(newValue, forKey: totalDaysKey) }
    }
    
    var lastClaimDate: Date? {
        get { defaults.object(forKey: lastClaimKey) as? Date }
        set { defaults.set(newValue, forKey: lastClaimKey) }
    }
    
    var currentDayInCycle: Int {
        return (currentStreak % 7) + 1
    }
    
    var todaysReward: DailyReward {
        return DailyRewardManager.rewards[currentDayInCycle - 1]
    }
    
    private init() {}
    
    // MARK: - Logic
    
    var canClaimToday: Bool {
        guard let lastClaim = lastClaimDate else { return true }
        return !Calendar.current.isDateInToday(lastClaim)
    }
    
    var didMissDay: Bool {
        guard let lastClaim = lastClaimDate else { return false }
        let daysSince = Calendar.current.dateComponents([.day], from: lastClaim, to: Date()).day ?? 0
        return daysSince > 1
    }
    
    func claimReward(currencyManager: CurrencyManager) -> DailyReward? {
        guard canClaimToday else { return nil }
        
        // Check if streak broken
        if didMissDay {
            currentStreak = 0
        }
        
        let reward = todaysReward
        
        // Award rewards
        if reward.coins > 0 {
            currencyManager.addCoins(reward.coins)
        }
        if reward.gems > 0 {
            GemManager.shared.addGems(reward.gems, source: .dailyLogin)
        }
        
        // Update tracking
        currentStreak += 1
        totalLoginDays += 1
        lastClaimDate = Date()
        
        // Milestone bonuses
        checkMilestones()
        
        return reward
    }
    
    private func checkMilestones() {
        // Streak milestones
        switch currentStreak {
        case 14:
            GemManager.shared.addGems(50, source: .achievement)
        case 30:
            GemManager.shared.addGems(100, source: .achievement)
        case 100:
            GemManager.shared.addGems(500, source: .achievement)
        default:
            break
        }
    }
    
    // MARK: - Debug
    
    func resetForTesting() {
        currentStreak = 0
        totalLoginDays = 0
        lastClaimDate = nil
    }
}
