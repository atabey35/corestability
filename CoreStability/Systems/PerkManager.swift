// PerkManager.swift
// CoreStability
// Manages roguelite card selection and active buffs

import Foundation

enum PerkType: String, CaseIterable {
    case damageBoost = "Damage Boost"
    case critMaster = "Crit Master"
    case wealth = "Wealth Generation"
    case rapidFire = "Rapid Fire"
    case explosiveAmmo = "Explosive Ammo"
    case sniper = "Sniper Training"
    case vitality = "Vitality"

    case teslaChain = "Tesla Chain"
    // NEW: Phase 3 perks
    case chainLightning = "Chain Lightning"  // Lightning chains to 2 enemies
    case lifesteal = "Lifesteal"             // Heal 5% of damage dealt
    case thorns = "Thorns"                   // Reflect 10% damage
    case berserker = "Berserker"             // +2% damage per 10% HP lost
    // CURSED PERKS (Risk/Reward)
    case glassCannon = "Glass Cannon"        // +100% Damage, -50% Max HP
    case bloodMoney = "Blood Money"          // +50% Coins, -20% Max HP
    case overcharge = "Overcharge"           // +100% Fire Rate, tower takes 1 DPS
    // NEW: Legendary Perks
    case orbitalStrike = "Orbital Strike"    // Laser from sky
    case timeWarp = "Time Warp"              // Slows enemies
    case blackHole = "Black Hole"            // Vortex
}

struct Perk {
    let type: PerkType
    let name: String
    let description: String
    let icon: String // SF Symbol Name
    
    // Multipliers or additives
    var value: CGFloat
}

final class PerkManager {
    static let shared = PerkManager()
    
    private init() {}
    
    private(set) var activePerks: [PerkType: Int] = [:]
    
    // Multipliers calculated from active perks
    // Multipliers calculated from active perks + Consumable Items (GachaManager)
    
    var damageMultiplier: CGFloat {
        let count = activePerks[.damageBoost] ?? 0
        let rogueMult = 1.0 + (CGFloat(count) * 0.15) // +15% per stack
        let gachaMult = CGFloat(GachaManager.shared.damageMultiplier)
        return rogueMult * gachaMult
    }
    
    var critChanceBonus: CGFloat {
        let count = activePerks[.critMaster] ?? 0
        let rogueBonus = CGFloat(count) * 0.05 // +5% per stack
        let gachaBonus = CGFloat(GachaManager.shared.critChanceBonus)
        return rogueBonus + gachaBonus
    }
    
    var coinMultiplier: Double {
        let count = activePerks[.wealth] ?? 0
        let rogueMult = 1.0 + (Double(count) * 0.20) // +20% coins
        let gachaMult = GachaManager.shared.coinMultiplier
        return rogueMult * gachaMult
    }
    
    var attackSpeedMultiplier: CGFloat {
        let count = activePerks[.rapidFire] ?? 0
        // Fix: Was 1.0 - x (Cooldown reduction), but GameScene uses it as FireRate multiplier.
        // Should be 1.0 + x (Speed increase).
        let rogueMult = 1.0 + (CGFloat(count) * 0.05) // +5% speed
        let gachaMult = CGFloat(GachaManager.shared.attackSpeedMultiplier)
        let overchargeMult = overchargeFireRateBonus
        return (rogueMult + overchargeMult) * gachaMult
    }
    
    var explosionChance: CGFloat {
        let count = activePerks[.explosiveAmmo] ?? 0
        return CGFloat(count) * 0.10 // 10% chance
        // Note: Consumable 'Explosive' is handled directly in TowerNode/ProjectileManager via explosionRadius
    }
    
    var rangeMultiplier: CGFloat {
        let count = activePerks[.sniper] ?? 0
        let rogueMult = 1.0 + (CGFloat(count) * 0.10) // +10% range
        let gachaMult = CGFloat(GachaManager.shared.rangeMultiplier)
        return rogueMult * gachaMult
    }
    
    var maxHPMultiplier: CGFloat {
        let count = activePerks[.vitality] ?? 0
        let rogueMult = 1.0 + (CGFloat(count) * 0.20) // +20% HP
        let gachaMult = CGFloat(GachaManager.shared.healthMultiplier)
        return rogueMult * gachaMult
    }
    
    var teslaChainCount: Int {
        return activePerks[.teslaChain] ?? 0
    }
    
    // NEW: Phase 3 Perk Properties
    
    var chainLightningBounces: Int {
        let count = activePerks[.chainLightning] ?? 0
        return count * 2  // 2 bounces per stack
    }
    
    var lifestealPercent: CGFloat {
        let count = activePerks[.lifesteal] ?? 0
        return CGFloat(count) * 0.05  // 5% per stack
    }
    
    var thornsDamagePercent: CGFloat {
        let count = activePerks[.thorns] ?? 0
        return CGFloat(count) * 0.10  // 10% per stack
    }
    
    var berserkerDamageBonus: CGFloat {
        let count = activePerks[.berserker] ?? 0
        return CGFloat(count) * 0.02  // 2% per 10% HP lost, per stack
    }
    
    // CURSED PERK PROPERTIES
    
    var hasGlassCannon: Bool {
        return (activePerks[.glassCannon] ?? 0) > 0
    }
    
    var glassCannonDamageBonus: CGFloat {
        return hasGlassCannon ? 1.0 : 0.0  // +100% damage
    }
    
    var glassCannonHPPenalty: CGFloat {
        return hasGlassCannon ? 0.5 : 1.0  // 50% HP reduction
    }
    
    var hasBloodMoney: Bool {
        return (activePerks[.bloodMoney] ?? 0) > 0
    }
    
    var bloodMoneyCoinBonus: Double {
        return hasBloodMoney ? 0.5 : 0.0  // +50% coins
    }
    
    var bloodMoneyHPPenalty: CGFloat {
        return hasBloodMoney ? 0.8 : 1.0  // 20% HP reduction
    }
    
    var hasOvercharge: Bool {
        return (activePerks[.overcharge] ?? 0) > 0
    }
    
    var overchargeFireRateBonus: CGFloat {
        return hasOvercharge ? 1.0 : 0.0  // +100% fire rate
    }
    
    var overchargeDPS: CGFloat {
        return hasOvercharge ? 1.0 : 0.0  // 1 damage per second to tower
    }
    
    // LEGENDARY EFFECTS
    var orbitalStrikeLevel: Int { return activePerks[.orbitalStrike] ?? 0 }
    var timeWarpLevel: Int { return activePerks[.timeWarp] ?? 0 }
    var blackHoleLevel: Int { return activePerks[.blackHole] ?? 0 }
    
    // MARK: - Synergy System
    
    /// Check if specific synergy is active
    func hasSynergy(_ synergyType: SynergyType) -> Bool {
        switch synergyType {
        case .thunderStorm:
            // Chain Lightning + Rapid Fire = Stun enemies for 0.5s
            return (activePerks[.chainLightning] ?? 0) > 0 && (activePerks[.rapidFire] ?? 0) > 0
        case .vampireKing:
            // Lifesteal + Berserker = Double lifesteal at low HP
            return (activePerks[.lifesteal] ?? 0) > 0 && (activePerks[.berserker] ?? 0) > 0
        case .fortressOfThorns:
            // Thorns + Vitality = Thorns damage doubled
            return (activePerks[.thorns] ?? 0) > 0 && (activePerks[.vitality] ?? 0) > 0
        }
    }
    
    var activeSynergies: [SynergyType] {
        return SynergyType.allCases.filter { hasSynergy($0) }
    }
    
    // MARK: - Logic
    
    func addPerk(_ type: PerkType) {
        activePerks[type, default: 0] += 1
    }
    
    func getRandomPerks(count: Int) -> [Perk] {
        var options: [Perk] = []
        var types = PerkType.allCases.shuffled()
        
        for _ in 0..<min(count, types.count) {
            let type = types.removeLast()
            options.append(createPerk(for: type))
        }
        
        return options
    }
    
    private func createPerk(for type: PerkType) -> Perk {
        switch type {
        case .damageBoost:
            return Perk(type: .damageBoost, name: "Heavy Caliber".localized, description: "+15% Damage".localized, icon: "flame.fill", value: 0.15)
        case .critMaster:
            return Perk(type: .critMaster, name: "Lethal Precision".localized, description: "+5% Critical Chance".localized, icon: "star.fill", value: 0.05)
        case .wealth:
            return Perk(type: .wealth, name: "Golden Touch".localized, description: "+20% Coin Value".localized, icon: "dollarsign.circle.fill", value: 0.20)
        case .rapidFire:
            return Perk(type: .rapidFire, name: "Overclock".localized, description: "+5% Fire Rate".localized, icon: "bolt.fill", value: 0.05)
        case .explosiveAmmo:
            return Perk(type: .explosiveAmmo, name: "Volatile Rounds".localized, description: "10% Chance to Explode".localized, icon: "burst.fill", value: 0.10)
        case .sniper:
            return Perk(type: .sniper, name: "Long Barrel".localized, description: "+10% Range".localized, icon: "scope", value: 0.10)
        case .vitality:
            return Perk(type: .vitality, name: "Reinforced Hulk".localized, description: "+20% Max HP".localized, icon: "heart.fill", value: 0.20)
        case .teslaChain:
            return Perk(type: .teslaChain, name: "Tesla Chain".localized, description: "Lightning chains to enemies".localized, icon: "bolt.circle.fill", value: 0.0)
        // NEW: Phase 3 perks
        case .chainLightning:
            return Perk(type: .chainLightning, name: "Chain Lightning".localized, description: "Hits chain to 2 enemies".localized, icon: "bolt.horizontal.icloud.fill", value: 0.0)
        case .lifesteal:
            return Perk(type: .lifesteal, name: "Vampire Touch".localized, description: "Heal 5% of damage dealt".localized, icon: "heart.circle.fill", value: 0.05)
        case .thorns:
            return Perk(type: .thorns, name: "Iron Thorns".localized, description: "Reflect 10% damage".localized, icon: "arrow.uturn.left.circle.fill", value: 0.10)
        case .berserker:
            return Perk(type: .berserker, name: "Berserker Rage".localized, description: "+2% damage per 10% HP lost".localized, icon: "flame.circle.fill", value: 0.02)
        // CURSED PERKS
        case .glassCannon:
            return Perk(type: .glassCannon, name: "⚠️ Glass Cannon".localized, description: "+100% Damage, -50% HP".localized, icon: "exclamationmark.triangle.fill", value: 1.0)
        case .bloodMoney:
            return Perk(type: .bloodMoney, name: "⚠️ Blood Money".localized, description: "+50% Coins, -20% HP".localized, icon: "banknote.fill", value: 0.5)
        case .overcharge:
            return Perk(type: .overcharge, name: "⚠️ Overcharge".localized, description: "+100% Fire Rate, 1 DPS to tower".localized, icon: "bolt.batteryblock.fill", value: 1.0)
        // LEGENDARY
        case .orbitalStrike:
            return Perk(type: .orbitalStrike, name: "Orbital Strike".localized, description: "Calls down a laser every 5s".localized, icon: "sun.max.fill", value: 0)
        case .timeWarp:
            return Perk(type: .timeWarp, name: "Time Warp".localized, description: "Freezes time every 10s".localized, icon: "clock.arrow.circlepath", value: 0)
        case .blackHole:
            return Perk(type: .blackHole, name: "Black Hole".localized, description: "5% Chance to spawn vortex".localized, icon: "tornado", value: 0)
        }
    }
    
    func reset() {
        activePerks.removeAll()
    }
}

// MARK: - Synergy Types

enum SynergyType: String, CaseIterable {
    case thunderStorm = "Thunder Storm"      // Chain Lightning + Rapid Fire
    case vampireKing = "Vampire King"        // Lifesteal + Berserker
    case fortressOfThorns = "Fortress of Thorns"  // Thorns + Vitality
}
