// GachaManager.swift
// CoreStability
// Manages gacha system for perk acquisition with pity mechanics

import Foundation

enum PerkRarity: String, CaseIterable, Codable {
    case common = "Common"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"
    
    var color: String {
        switch self {
        case .common: return "gray"
        case .rare: return "blue"
        case .epic: return "purple"
        case .legendary: return "gold"
        }
    }
    
    var dropRate: Double {
        switch self {
        case .common: return 0.55     // 55%
        case .rare: return 0.30       // 30%
        case .epic: return 0.12       // 12%
        case .legendary: return 0.03  // 3%
        }
    }
    
    var gemValue: Int {
        switch self {
        case .common: return 5
        case .rare: return 15
        case .epic: return 50
        case .legendary: return 200
        }
    }
}

struct GachaPerk: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let rarity: PerkRarity
    let effect: GachaPerkEffect
    
    var effectDescription: String {
        switch effect {
        case .damageBoost(let percent):
            return "+\(Int(percent * 100))% Damage"
        case .critChance(let percent):
            return "+\(Int(percent * 100))% Crit Chance"
        case .critDamage(let percent):
            return "+\(Int(percent * 100))% Crit Damage"
        case .attackSpeed(let percent):
            return "+\(Int(percent * 100))% Attack Speed"
        case .coinBonus(let percent):
            return "+\(Int(percent * 100))% Coin Bonus"
        case .startingGold(let amount):
            return "+\(amount) Starting Gold"
        case .healthBoost(let percent):
            return "+\(Int(percent * 100))% Max HP"
        case .rangeBoost(let percent):
            return "+\(Int(percent * 100))% Range"
        case .splashDamage(let percent):
            return "+\(Int(percent * 100))% Splash Damage"
        case .penetration(let count):
            return "+\(count) Penetration"
        }
    }
}

enum GachaPerkEffect: Codable {
    case damageBoost(Double)
    case critChance(Double)
    case critDamage(Double)
    case attackSpeed(Double)
    case coinBonus(Double)
    case startingGold(Int)
    case healthBoost(Double)
    case rangeBoost(Double)
    case splashDamage(Double)
    case penetration(Int)
}

final class GachaManager {
    static let shared = GachaManager()
    
    private let defaults = UserDefaults.standard
    private let pullCountKey = "gachaPullCount"
    private let ownedPerksKey = "gachaOwnedPerks"
    private let pityCounterKey = "gachaPityCounter"
    
    // MARK: - Configuration
    
    let singlePullCost = 100   // Gems
    let tenPullCost = 900      // Gems (10% discount)
    let pityThreshold = 50     // Guaranteed Legendary at 50 pulls
    
    // MARK: - Properties
    
    var totalPulls: Int {
        get { defaults.integer(forKey: pullCountKey) }
        set { defaults.set(newValue, forKey: pullCountKey) }
    }
    
    var pityCounter: Int {
        get { defaults.integer(forKey: pityCounterKey) }
        set { defaults.set(newValue, forKey: pityCounterKey) }
    }
    
    // Removed ownedPerksKey - Inventory handles ownership now
    
    private init() {}
    
    // MARK: - Perk Pool (Definitions match InventoryManager IDs)
    
    static var allPerks: [GachaPerk] {
        return [
        // Common Perks
        GachaPerk(id: "dmg_c1", name: "Minor Damage".localized, description: "Slightly increase damage".localized, icon: "flame.fill", rarity: .common, effect: .damageBoost(0.05)),
        GachaPerk(id: "spd_c1", name: "Quick Hands".localized, description: "Slightly faster attacks".localized, icon: "bolt.fill", rarity: .common, effect: .attackSpeed(0.05)),
        GachaPerk(id: "coin_c1", name: "Coin Hunter".localized, description: "Find more coins".localized, icon: "dollarsign.circle", rarity: .common, effect: .coinBonus(0.05)),
        GachaPerk(id: "hp_c1", name: "Tough Skin".localized, description: "More health".localized, icon: "heart.fill", rarity: .common, effect: .healthBoost(0.05)),
        GachaPerk(id: "rng_c1", name: "Keen Eye".localized, description: "Slightly more range".localized, icon: "scope", rarity: .common, effect: .rangeBoost(0.05)),
        
        // Rare Perks
        GachaPerk(id: "dmg_r1", name: "Power Strike".localized, description: "Deal more damage".localized, icon: "flame.fill", rarity: .rare, effect: .damageBoost(0.10)),
        GachaPerk(id: "crit_r1", name: "Lucky Shot".localized, description: "Better crit chance".localized, icon: "star.fill", rarity: .rare, effect: .critChance(0.05)),
        GachaPerk(id: "spd_r1", name: "Rapid Fire".localized, description: "Attack faster".localized, icon: "bolt.fill", rarity: .rare, effect: .attackSpeed(0.10)),
        GachaPerk(id: "coin_r1", name: "Gold Rush".localized, description: "More coins".localized, icon: "dollarsign.circle", rarity: .rare, effect: .coinBonus(0.15)),
        GachaPerk(id: "start_r1", name: "Trust Fund".localized, description: "Start with gold".localized, icon: "banknote", rarity: .rare, effect: .startingGold(500)),
        
        // Epic Perks
        GachaPerk(id: "dmg_e1", name: "Berserker".localized, description: "Major damage boost".localized, icon: "flame.fill", rarity: .epic, effect: .damageBoost(0.20)),
        GachaPerk(id: "crit_e1", name: "Executioner".localized, description: "High crit chance".localized, icon: "star.fill", rarity: .epic, effect: .critChance(0.10)),
        GachaPerk(id: "critdmg_e1", name: "Devastator".localized, description: "Crits hurt more".localized, icon: "burst.fill", rarity: .epic, effect: .critDamage(0.30)),
        GachaPerk(id: "splash_e1", name: "Explosive".localized, description: "Splash damage".localized, icon: "sparkles", rarity: .epic, effect: .splashDamage(0.25)),
        GachaPerk(id: "hp_e1", name: "Iron Will".localized, description: "Massive HP boost".localized, icon: "heart.fill", rarity: .epic, effect: .healthBoost(0.25)),
        
        // Legendary Perks
        GachaPerk(id: "dmg_l1", name: "God Slayer".localized, description: "Legendary damage (3h)".localized, icon: "flame.fill", rarity: .legendary, effect: .damageBoost(0.50)),
        GachaPerk(id: "crit_l1", name: "Destiny's Edge".localized, description: "Ultimate crits (3h)".localized, icon: "star.fill", rarity: .legendary, effect: .critChance(0.20)),
        GachaPerk(id: "pen_l1", name: "Pierce All".localized, description: "Shots penetrate (3h)".localized, icon: "arrowshape.turn.up.right", rarity: .legendary, effect: .penetration(3)),
        GachaPerk(id: "coin_l1", name: "Midas Touch".localized, description: "Double coins (3h)".localized, icon: "dollarsign.circle", rarity: .legendary, effect: .coinBonus(1.0)),
        GachaPerk(id: "all_l1", name: "Ascension".localized, description: "All stats boost (3h)".localized, icon: "crown.fill", rarity: .legendary, effect: .damageBoost(0.25))
        ]
    }
    
    // MARK: - Pull Logic
    
    func canPull(count: Int) -> Bool {
        let cost = count == 10 ? tenPullCost : singlePullCost * count
        return GemManager.shared.canAfford(cost)
    }
    
    func pull(count: Int) -> [GachaPerk]? {
        let cost = count == 10 ? tenPullCost : singlePullCost * count
        
        guard GemManager.shared.spendGems(cost, purpose: .gachaPull) else {
            return nil
        }
        
        var results: [GachaPerk] = []
        
        for i in 0..<count {
            pityCounter += 1
            totalPulls += 1
            
            let rarity: PerkRarity
            
            // Pity system - guaranteed legendary
            if pityCounter >= pityThreshold {
                rarity = .legendary
                pityCounter = 0
            }
            // 10-pull guarantee: At least one Rare+ in position 10
            else if count == 10 && i == 9 && results.allSatisfy({ $0.rarity == .common }) {
                rarity = rollRarity(guaranteeRare: true)
            }
            else {
                rarity = rollRarity(guaranteeRare: false)
            }
            
            // Reset pity on legendary
            if rarity == .legendary {
                pityCounter = 0
            }
            
            // Get random perk of this rarity
            let perksOfRarity = GachaManager.allPerks.filter { $0.rarity == rarity }
            if let perk = perksOfRarity.randomElement() {
                results.append(perk)
                
                // Add to Inventory instead of Owned List
                InventoryManager.shared.addItem(id: perk.id, amount: 1)
            }
        }
        
        Analytics.logEvent("gacha_pull", parameters: [
            "count": count,
            "legendaries": results.filter { $0.rarity == .legendary }.count
        ])
        
        return results
    }
    
    private func rollRarity(guaranteeRare: Bool) -> PerkRarity {
        let roll = Double.random(in: 0...1)
        var cumulative = 0.0
        
        for rarity in PerkRarity.allCases {
            // Skip common if guarantee rare
            if guaranteeRare && rarity == .common { continue }
            
            cumulative += rarity.dropRate
            if roll <= cumulative {
                return rarity
            }
        }
        
        return guaranteeRare ? .rare : .common
    }
    
    // MARK: - Legacy / Helper Accessors (Mapped to Inventory)
    // Note: These now check for ACTIVE BUFFS, not ownership
    
    func getBonus(_ key: String) -> Double {
        var total = 0.0
        
        // Iterate through all active buffs in InventoryManager
        for buffId in InventoryManager.shared.getActiveBuffIDs() {
            // Find corresponding GachaPerk definition
            if let perk = GachaManager.allPerks.first(where: { $0.id == buffId }) {
                switch perk.effect {
                case .damageBoost(let val) where key == "damage": total += val
                case .critChance(let val) where key == "critChance": total += val
                case .critDamage(let val) where key == "critDamage": total += val
                case .attackSpeed(let val) where key == "attackSpeed": total += val
                case .coinBonus(let val) where key == "coinBonus": total += val
                case .healthBoost(let val) where key == "healthBoost": total += val
                case .rangeBoost(let val) where key == "rangeBoost": total += val
                case .splashDamage(let val) where key == "splashDamage": total += val
                case .startingGold(let val) where key == "startingGold": total += Double(val)
                case .penetration(let val) where key == "penetration": total += Double(val)
                default: break
                }
            }
        }
        return total
    }
    
    // Convenience properties used by GameScene/TowerNode
    var damageMultiplier: Double { 1.0 + getBonus("damage") }
    var critChanceBonus: Double { getBonus("critChance") }
    var critDamageBonus: Double { getBonus("critDamage") }
    var attackSpeedMultiplier: Double { 1.0 + getBonus("attackSpeed") }
    var coinMultiplier: Double { 1.0 + getBonus("coinBonus") }
    var healthMultiplier: Double { 1.0 + getBonus("healthBoost") }
    var rangeMultiplier: Double { 1.0 + getBonus("rangeBoost") }
    var startingGold: Int { Int(getBonus("startingGold")) }
    var penetrationBonus: Int { Int(getBonus("penetration")) }
    
    var pullsUntilPity: Int {
        return max(0, pityThreshold - pityCounter)
    }
}
