// BattlePassManager.swift
// CoreStability
// Manages seasonal battle pass with free and premium tracks

import Foundation

struct BattlePassReward {
    let level: Int
    let isPremium: Bool
    let coins: Int
    let gems: Int
    let description: String
    let icon: String
}

final class BattlePassManager {
    static let shared = BattlePassManager()
    
    private let defaults = UserDefaults.standard
    private let xpKey = "battlePassXP"
    private let claimedFreeKey = "battlePassClaimedFree"
    private let claimedPremiumKey = "battlePassClaimedPremium"
    private let seasonKey = "battlePassSeason"
    
    // MARK: - Configuration
    
    let maxLevel = 50
    let xpPerLevel = 1000
    
    // Current Season (increment when new season starts)
    let currentSeason = 1
    
    // MARK: - Properties
    
    var currentXP: Int {
        get { 
            // Check if season changed
            if defaults.integer(forKey: seasonKey) != currentSeason {
                defaults.set(currentSeason, forKey: seasonKey)
                defaults.set(0, forKey: xpKey)
                defaults.set([], forKey: claimedFreeKey)
                defaults.set([], forKey: claimedPremiumKey)
            }
            return defaults.integer(forKey: xpKey) 
        }
        set { defaults.set(newValue, forKey: xpKey) }
    }
    
    var currentLevel: Int {
        return min(maxLevel, currentXP / xpPerLevel + 1)
    }
    
    var xpInCurrentLevel: Int {
        return currentXP % xpPerLevel
    }
    
    var levelProgress: Float {
        return Float(xpInCurrentLevel) / Float(xpPerLevel)
    }
    
    var claimedFreeLevels: [Int] {
        get { defaults.array(forKey: claimedFreeKey) as? [Int] ?? [] }
        set { defaults.set(newValue, forKey: claimedFreeKey) }
    }
    
    var claimedPremiumLevels: [Int] {
        get { defaults.array(forKey: claimedPremiumKey) as? [Int] ?? [] }
        set { defaults.set(newValue, forKey: claimedPremiumKey) }
    }
    
    var hasPremiumPass: Bool {
        return IAPManager.shared.hasBattlePass
    }
    
    private init() {}
    
    // MARK: - Rewards
    
    // MARK: - Rewards
    
    // Helper to generate rewards for every level
    static var freeRewards: [Int: BattlePassReward] = {
        var rewards: [Int: BattlePassReward] = [:]
        // Specific Milestones
        rewards[1] = BattlePassReward(level: 1, isPremium: false, coins: 500, gems: 0, description: "500 Coins", icon: "dollarsign.circle.fill")
        rewards[5] = BattlePassReward(level: 5, isPremium: false, coins: 0, gems: 20, description: "20 Gems", icon: "diamond.fill")
        rewards[10] = BattlePassReward(level: 10, isPremium: false, coins: 2000, gems: 0, description: "2000 Coins", icon: "dollarsign.circle.fill")
        rewards[15] = BattlePassReward(level: 15, isPremium: false, coins: 0, gems: 50, description: "50 Gems", icon: "diamond.fill")
        rewards[20] = BattlePassReward(level: 20, isPremium: false, coins: 5000, gems: 0, description: "5000 Coins", icon: "dollarsign.circle.fill")
        rewards[25] = BattlePassReward(level: 25, isPremium: false, coins: 0, gems: 100, description: "100 Gems", icon: "diamond.fill")
        rewards[30] = BattlePassReward(level: 30, isPremium: false, coins: 10000, gems: 0, description: "10K Coins", icon: "dollarsign.circle.fill")
        rewards[40] = BattlePassReward(level: 40, isPremium: false, coins: 0, gems: 150, description: "150 Gems", icon: "diamond.fill")
        rewards[50] = BattlePassReward(level: 50, isPremium: false, coins: 0, gems: 500, description: "500 Gems!", icon: "gift.fill")
        
        // Fill gaps with small rewards
        for i in 1...50 {
            if rewards[i] == nil {
                rewards[i] = BattlePassReward(level: i, isPremium: false, coins: 50, gems: 0, description: "50 Coins", icon: "dollarsign.circle")
            }
        }
        return rewards
    }()
    
    static var premiumRewards: [Int: BattlePassReward] = {
        var rewards: [Int: BattlePassReward] = [:]
        // Specific Milestones
        rewards[1] = BattlePassReward(level: 1, isPremium: true, coins: 1000, gems: 50, description: "1000 Coins + 50 Gems", icon: "star.fill")
        rewards[5] = BattlePassReward(level: 5, isPremium: true, coins: 0, gems: 100, description: "100 Gems", icon: "diamond.fill")
        rewards[10] = BattlePassReward(level: 10, isPremium: true, coins: 5000, gems: 0, description: "5000 Coins + Skin", icon: "paintbrush.fill")
        rewards[15] = BattlePassReward(level: 15, isPremium: true, coins: 0, gems: 150, description: "150 Gems", icon: "diamond.fill")
        rewards[20] = BattlePassReward(level: 20, isPremium: true, coins: 10000, gems: 0, description: "10K Coins + Skin", icon: "paintbrush.fill")
        rewards[25] = BattlePassReward(level: 25, isPremium: true, coins: 0, gems: 200, description: "200 Gems", icon: "diamond.fill")
        rewards[30] = BattlePassReward(level: 30, isPremium: true, coins: 20000, gems: 0, description: "20K Coins + Skin", icon: "paintbrush.fill")
        rewards[35] = BattlePassReward(level: 35, isPremium: true, coins: 0, gems: 300, description: "300 Gems", icon: "diamond.fill")
        rewards[40] = BattlePassReward(level: 40, isPremium: true, coins: 0, gems: 400, description: "400 Gems + Turret Skin", icon: "shield.fill")
        rewards[45] = BattlePassReward(level: 45, isPremium: true, coins: 50000, gems: 0, description: "50K Coins", icon: "dollarsign.circle.fill")
        rewards[50] = BattlePassReward(level: 50, isPremium: true, coins: 0, gems: 1000, description: "1000 Gems + Legendary!", icon: "crown.fill")
        
        // Fill gaps with small premium rewards
        for i in 1...50 {
            if rewards[i] == nil {
                rewards[i] = BattlePassReward(level: i, isPremium: true, coins: 200, gems: 0, description: "200 Coins", icon: "dollarsign.circle.fill")
            }
        }
        return rewards
    }()
    
    // MARK: - XP
    
    func addXP(_ amount: Int) {
        currentXP += amount
        Analytics.logEvent("battle_pass_xp", parameters: ["amount": amount, "new_level": currentLevel])
    }
    
    // XP Sources
    func onWaveComplete(wave: Int) {
        addXP(10 + wave) // Base 10 + wave number
    }
    
    func onBossKill() {
        addXP(50)
    }
    
    func onDailyQuestComplete() {
        addXP(100)
    }
    
    // MARK: - Claiming
    
    func canClaimFree(level: Int) -> Bool {
        guard let _ = BattlePassManager.freeRewards[level] else { return false }
        return currentLevel >= level && !claimedFreeLevels.contains(level)
    }
    
    func canClaimPremium(level: Int) -> Bool {
        guard hasPremiumPass else { return false }
        guard let _ = BattlePassManager.premiumRewards[level] else { return false }
        return currentLevel >= level && !claimedPremiumLevels.contains(level)
    }
    
    func claimFreeReward(level: Int, currencyManager: CurrencyManager) -> BattlePassReward? {
        guard canClaimFree(level: level),
              let reward = BattlePassManager.freeRewards[level] else { return nil }
        
        if reward.coins > 0 { currencyManager.addCoins(reward.coins) }
        if reward.gems > 0 { GemManager.shared.addGems(reward.gems, source: .battlePass) }
        
        var claimed = claimedFreeLevels
        claimed.append(level)
        claimedFreeLevels = claimed
        
        return reward
    }
    
    func claimPremiumReward(level: Int, currencyManager: CurrencyManager) -> BattlePassReward? {
        guard canClaimPremium(level: level),
              let reward = BattlePassManager.premiumRewards[level] else { return nil }
        
        if reward.coins > 0 { currencyManager.addCoins(reward.coins) }
        if reward.gems > 0 { GemManager.shared.addGems(reward.gems, source: .battlePass) }
        
        var claimed = claimedPremiumLevels
        claimed.append(level)
        claimedPremiumLevels = claimed
        
        return reward
    }
    
    // MARK: - UI Helpers
    
    func getUnclaimedCount() -> Int {
        var count = 0
        for level in 1...currentLevel {
            if canClaimFree(level: level) { count += 1 }
            if canClaimPremium(level: level) { count += 1 }
        }
        return count
    }
}
