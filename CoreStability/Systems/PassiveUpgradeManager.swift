// PassiveUpgradeManager.swift
// CoreStability
// Manages permanent passive bonuses

import Foundation

struct PassiveUpgrade {
    let type: PassiveType
    let name: String
    let icon: String
    let description: String
    let cost: Int
    var purchased: Bool = false
}

enum PassiveType: String, CaseIterable {
    case criticalMaster = "critical"
    case coinMagnet = "coin"
    case regeneration = "regen"
    case piercing = "pierce"
    case multiShot = "multi"
    case lifeSteal = "lifesteal"
}

final class PassiveUpgradeManager {
    
    // Passive levels (0 = not purchased)
    var criticalLevel: Int = 0      // +5% crit per level
    var coinMagnetLevel: Int = 0    // +15% coins per level
    var regenLevel: Int = 0         // +0.5 HP/s per level
    var piercingLevel: Int = 0      // +10% pierce chance per level
    var multiShotLevel: Int = 0     // +10% multi-shot chance
    var lifeStealLevel: Int = 0     // +2% lifesteal per level
    
    // Max levels
    let maxLevel = 5
    
    // Calculated bonuses
    var criticalChance: Float { Float(criticalLevel) * 0.05 }
    var coinBonus: Float { 1.0 + Float(coinMagnetLevel) * 0.15 }
    var hpRegenBonus: Float { Float(regenLevel) * 0.5 }
    var pierceChance: Float { Float(piercingLevel) * 0.10 }
    var multiShotChance: Float { Float(multiShotLevel) * 0.10 }
    var lifeStealPercent: Float { Float(lifeStealLevel) * 0.02 }
    
    // Costs (exponential)
    func getCost(for type: PassiveType) -> Int {
        let level = getLevel(for: type)
        guard level < maxLevel else { return 99999 }
        
        let baseCost: Int
        switch type {
        case .criticalMaster: baseCost = 200
        case .coinMagnet: baseCost = 150
        case .regeneration: baseCost = 180
        case .piercing: baseCost = 250
        case .multiShot: baseCost = 300
        case .lifeSteal: baseCost = 350
        }
        
        return baseCost * (level + 1)
    }
    
    func getLevel(for type: PassiveType) -> Int {
        switch type {
        case .criticalMaster: return criticalLevel
        case .coinMagnet: return coinMagnetLevel
        case .regeneration: return regenLevel
        case .piercing: return piercingLevel
        case .multiShot: return multiShotLevel
        case .lifeSteal: return lifeStealLevel
        }
    }
    
    func purchase(_ type: PassiveType, currency: CurrencyManager) -> Bool {
        let cost = getCost(for: type)
        let level = getLevel(for: type)
        
        guard level < maxLevel else { return false }
        guard currency.spendCoins(cost) else { return false }
        
        switch type {
        case .criticalMaster: criticalLevel += 1
        case .coinMagnet: coinMagnetLevel += 1
        case .regeneration: regenLevel += 1
        case .piercing: piercingLevel += 1
        case .multiShot: multiShotLevel += 1
        case .lifeSteal: lifeStealLevel += 1
        }
        
        return true
    }
    
    // Get all passives for display
    func getAllPassives() -> [(type: PassiveType, name: String, icon: String, level: Int, cost: Int)] {
        return [
            (.criticalMaster, "Critical", "💥", criticalLevel, getCost(for: .criticalMaster)),
            (.coinMagnet, "Coins", "💰", coinMagnetLevel, getCost(for: .coinMagnet)),
            (.regeneration, "Regen", "❤️", regenLevel, getCost(for: .regeneration)),
            (.piercing, "Pierce", "🎯", piercingLevel, getCost(for: .piercing)),
            (.multiShot, "Multi", "🔱", multiShotLevel, getCost(for: .multiShot)),
            (.lifeSteal, "Steal", "🧛", lifeStealLevel, getCost(for: .lifeSteal))
        ]
    }
}
