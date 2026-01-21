// UpgradeManager.swift
// CoreStability
// Manages upgrades, costs, and skill unlocks with PERSISTENT storage

import Foundation
import CoreGraphics

enum UpgradeType: String {
    case damage
    case fireRate
    case range
    case health
    case defense
}

enum SkillType: String {
    case uzi
    case rocket
    case freeze
    case laser   // NEW: Continuous beam damage
    case shield  // NEW: Invulnerability
    case emp
}

enum WeaponType: String, CaseIterable {
    case pistol = "Pistol"
    case shotgun = "Shotgun"
    case sniper = "Sniper"
    case railgun = "Railgun"
}

enum TurretType: String, CaseIterable {
    case sentry = "Sentry"
    case missile = "Missile"
}

enum TargetPriority: String, CaseIterable {
    case closest = "CLOSEST"
    case lowestHP = "LOW HP"
    case highestHP = "HIGH HP"
    case rangedFirst = "RANGED"
}

final class UpgradeManager {
    
    static let shared = UpgradeManager()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - UserDefaults Keys
    private let kDamageLevel = "upgrade_damageLevel"
    private let kFireRateLevel = "upgrade_fireRateLevel"
    private let kRangeLevel = "upgrade_rangeLevel"
    private let kHealthLevel = "upgrade_healthLevel"
    private let kDefenseLevel = "upgrade_defenseLevel"
    
    private let kUziUnlocked = "upgrade_uziUnlocked"
    private let kRocketUnlocked = "upgrade_rocketUnlocked"
    private let kFreezeUnlocked = "upgrade_freezeUnlocked"
    private let kLaserUnlocked = "upgrade_laserUnlocked"
    private let kShieldUnlocked = "upgrade_shieldUnlocked"
    private let kEmpUnlocked = "upgrade_empUnlocked"
    
    private let kUnlockedWeapons = "upgrade_unlockedWeapons"
    private let kActiveWeapon = "upgrade_activeWeapon"
    private let kBladeUnlocked = "upgrade_bladeUnlocked"
    private let kWeaponRentals = "upgrade_weaponRentals"
    private let kTurretSlotsUnlocked = "upgrade_turretSlotsUnlocked"
    
    // MARK: - Upgrade Levels (Persisted)
    var damageLevel: Int {
        get { max(1, defaults.integer(forKey: kDamageLevel)) }
        set { defaults.set(newValue, forKey: kDamageLevel) }
    }
    
    var fireRateLevel: Int {
        get { max(1, defaults.integer(forKey: kFireRateLevel)) }
        set { defaults.set(newValue, forKey: kFireRateLevel) }
    }
    
    var rangeLevel: Int {
        get { max(1, defaults.integer(forKey: kRangeLevel)) }
        set { defaults.set(newValue, forKey: kRangeLevel) }
    }
    
    var healthLevel: Int {
        get { max(1, defaults.integer(forKey: kHealthLevel)) }
        set { defaults.set(newValue, forKey: kHealthLevel) }
    }
    
    var defenseLevel: Int {
        get { max(1, defaults.integer(forKey: kDefenseLevel)) }
        set { defaults.set(newValue, forKey: kDefenseLevel) }
    }
    
    // MARK: - Skill Unlocks (Persisted)
    var isUziUnlocked: Bool {
        get { defaults.bool(forKey: kUziUnlocked) }
        set { defaults.set(newValue, forKey: kUziUnlocked) }
    }
    
    var isRocketUnlocked: Bool {
        get { defaults.bool(forKey: kRocketUnlocked) }
        set { defaults.set(newValue, forKey: kRocketUnlocked) }
    }
    
    var isFreezeUnlocked: Bool {
        get { defaults.bool(forKey: kFreezeUnlocked) }
        set { defaults.set(newValue, forKey: kFreezeUnlocked) }
    }
    
    var isLaserUnlocked: Bool {
        get { defaults.bool(forKey: kLaserUnlocked) }
        set { defaults.set(newValue, forKey: kLaserUnlocked) }
    }
    
    var isShieldUnlocked: Bool {
        get { defaults.bool(forKey: kShieldUnlocked) }
        set { defaults.set(newValue, forKey: kShieldUnlocked) }
    }
    
    var isEmpUnlocked: Bool {
        get { defaults.bool(forKey: kEmpUnlocked) }
        set { defaults.set(newValue, forKey: kEmpUnlocked) }
    }
    
    // MARK: - Weapon Unlocks (Persisted)
    var unlockedWeapons: Set<WeaponType> {
        get {
            if let savedArray = defaults.stringArray(forKey: kUnlockedWeapons) {
                let weapons = savedArray.compactMap { WeaponType(rawValue: $0) }
                return weapons.isEmpty ? [.pistol] : Set(weapons)
            }
            return [.pistol]
        }
        set {
            let array = newValue.map { $0.rawValue }
            defaults.set(array, forKey: kUnlockedWeapons)
        }
    }
    
    var activeWeapon: WeaponType {
        get {
            if let saved = defaults.string(forKey: kActiveWeapon),
               let weapon = WeaponType(rawValue: saved) {
                return weapon
            }
            return .pistol
        }
        set {
            defaults.set(newValue.rawValue, forKey: kActiveWeapon)
        }
    }
    
    var isBladeUnlocked: Bool {
        get { defaults.bool(forKey: kBladeUnlocked) }
        set { defaults.set(newValue, forKey: kBladeUnlocked) }
    }
    
    // MARK: - Weapon Rentals (Persisted)
    var weaponRentals: [WeaponType: Date] {
        get {
            guard let data = defaults.data(forKey: kWeaponRentals),
                  let dict = try? JSONDecoder().decode([String: Date].self, from: data) else {
                return [:]
            }
            var result: [WeaponType: Date] = [:]
            for (key, value) in dict {
                if let weapon = WeaponType(rawValue: key) {
                    result[weapon] = value
                }
            }
            return result
        }
        set {
            var dict: [String: Date] = [:]
            for (key, value) in newValue {
                dict[key.rawValue] = value
            }
            if let data = try? JSONEncoder().encode(dict) {
                defaults.set(data, forKey: kWeaponRentals)
            }
        }
    }
    
    // Alias for ShopUI compatibility
    var rentedWeapons: [WeaponType: Date] {
        return weaponRentals
    }
    
    // MARK: - Turret System (Persisted)
    var maxTurrets: Int = 4
    
    var turretSlotsUnlocked: Int {
        get { max(1, defaults.integer(forKey: kTurretSlotsUnlocked)) }
        set { defaults.set(newValue, forKey: kTurretSlotsUnlocked) }
    }
    
    var turretCount: Int {
        return turretSlotsUnlocked
    }
    
    // MARK: - Init
    private init() {
        // Initialize default values if first launch
        if defaults.object(forKey: kDamageLevel) == nil {
            defaults.set(1, forKey: kDamageLevel)
            defaults.set(1, forKey: kFireRateLevel)
            defaults.set(1, forKey: kRangeLevel)
            defaults.set(1, forKey: kHealthLevel)
            defaults.set(1, forKey: kDefenseLevel)
            defaults.set(1, forKey: kTurretSlotsUnlocked)
            defaults.set([WeaponType.pistol.rawValue], forKey: kUnlockedWeapons)
            defaults.set(WeaponType.pistol.rawValue, forKey: kActiveWeapon)
        }
    }
    
    // MARK: - Rental Time Helper
    
    func getRentalTimeRemaining(_ type: WeaponType) -> String? {
        guard let expiration = weaponRentals[type] else { return nil }
        let now = Date()
        guard expiration > now else {
            var rentals = weaponRentals
            rentals.removeValue(forKey: type)
            weaponRentals = rentals
            
            var weapons = unlockedWeapons
            weapons.remove(type)
            unlockedWeapons = weapons
            return nil
        }
        
        let diff = expiration.timeIntervalSince(now)
        let days = Int(diff / 86400)
        let hours = Int((diff.truncatingRemainder(dividingBy: 86400)) / 3600)
        
        if days > 0 {
            return "\(days)d \(hours)h"
        } else {
            return "\(hours)h"
        }
    }
    
    // MARK: - Base Stats & Scaling
    func getDamage(base: CGFloat) -> CGFloat {
        return base * (1.0 + CGFloat(damageLevel - 1) * 0.2) // +20% per level
    }
    
    func getFireRate(base: CGFloat) -> CGFloat {
        return base * (1.0 + CGFloat(fireRateLevel - 1) * 0.1) // +10% per level
    }
    
    func getRange(base: CGFloat) -> CGFloat {
        return base * (1.0 + CGFloat(rangeLevel - 1) * 0.1) // +10% per level
    }
    
    func getMaxHP(base: CGFloat) -> CGFloat {
        return base * (1.0 + CGFloat(healthLevel - 1) * 0.2) // +20% per level
    }
    
    func getDefense() -> CGFloat {
        return CGFloat(defenseLevel - 1) * 2.0 // +2 flat defense per level
    }
    
    // MARK: - Costs
    func getCost(for type: UpgradeType) -> Int {
        switch type {
        case .damage: return 10 * Int(pow(1.35, Double(damageLevel - 1)))
        case .fireRate: return 20 * Int(pow(1.35, Double(fireRateLevel - 1)))
        case .range: return 15 * Int(pow(1.35, Double(rangeLevel - 1)))
        case .health: return 10 * Int(pow(1.35, Double(healthLevel - 1)))
        case .defense: return 15 * Int(pow(1.35, Double(defenseLevel - 1)))
        }
    }
    
    func getSkillCost(for type: SkillType) -> Int {
        switch type {
        case .uzi: return 500
        case .rocket: return 1000
        case .freeze: return 750
        case .laser: return 1200
        case .shield: return 1500
        case .emp: return 2000
        }
    }
    
    func getWeaponCost(for type: WeaponType) -> Int {
        return 0 // TEST MODE: All weapons free
    }
    
    func getTurretCost() -> Int {
        return 0 // TEST MODE: Free turrets
    }
    
    // MARK: - Actions
    func purchaseUpgrade(_ type: UpgradeType, currency: CurrencyManager) -> Bool {
        let cost = getCost(for: type)
        if currency.coins >= cost {
            if currency.spendCoins(cost) {
                switch type {
                case .damage: damageLevel += 1
                case .fireRate: fireRateLevel += 1
                case .range: rangeLevel += 1
                case .health: healthLevel += 1
                case .defense: defenseLevel += 1
                }
                return true
            }
        }
        return false
    }
    
    func purchaseSkill(_ type: SkillType, currency: CurrencyManager) -> Bool {
        let cost = getSkillCost(for: type)
        guard currency.coins >= cost else { return false }
        
        switch type {
        case .uzi:
            if !isUziUnlocked && currency.spendCoins(cost) {
                isUziUnlocked = true
                return true
            }
        case .rocket:
            if !isRocketUnlocked && currency.spendCoins(cost) {
                isRocketUnlocked = true
                return true
            }
        case .freeze:
            if !isFreezeUnlocked && currency.spendCoins(cost) {
                isFreezeUnlocked = true
                return true
            }
        case .laser:
            if !isLaserUnlocked && currency.spendCoins(cost) {
                isLaserUnlocked = true
                return true
            }
        case .shield:
            if !isShieldUnlocked && currency.spendCoins(cost) {
                isShieldUnlocked = true
                return true
            }
        case .emp:
            if !isEmpUnlocked && currency.spendCoins(cost) {
                isEmpUnlocked = true
                return true
            }
        }
        return false
    }

    
    func purchaseWeapon(_ type: WeaponType, currency: CurrencyManager) -> Bool {
        guard !unlockedWeapons.contains(type) else {
            // Already unlocked, just equip
            activeWeapon = type
            return true 
        }
        
        let cost = getWeaponCost(for: type)
        if currency.spendCoins(cost) {
            var weapons = unlockedWeapons
            weapons.insert(type)
            unlockedWeapons = weapons
            activeWeapon = type
            return true
        }
        return false
    }
    
    func equipWeapon(_ type: WeaponType) {
        if unlockedWeapons.contains(type) {
            activeWeapon = type
        }
    }
    
    func purchaseTurret(currency: CurrencyManager) -> Bool {
        guard turretCount < maxTurrets else { return false }
        let cost = getTurretCost()
        
        if currency.spendCoins(cost) {
            turretSlotsUnlocked += 1
            return true
        }
        return false
    }
    
    // MARK: - Rental & Permanent Unlock (IAP)
    
    func rentWeapon(_ type: WeaponType, days: Int) {
        let expirationDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        var rentals = weaponRentals
        rentals[type] = expirationDate
        weaponRentals = rentals
        
        var weapons = unlockedWeapons
        weapons.insert(type)
        unlockedWeapons = weapons
    }
    
    func unlockWeaponPermanently(_ type: WeaponType) {
        var weapons = unlockedWeapons
        weapons.insert(type)
        unlockedWeapons = weapons
        
        var rentals = weaponRentals
        rentals.removeValue(forKey: type)
        weaponRentals = rentals
    }
    
    func isWeaponRented(_ type: WeaponType) -> Bool {
        guard let expiration = weaponRentals[type] else { return false }
        return Date() < expiration
    }
    
    func isUnlocked(weapon: WeaponType) -> Bool {
        return unlockedWeapons.contains(weapon)
    }
    
    // MARK: - Reset (for testing)
    func resetAllProgress() {
        defaults.removeObject(forKey: kDamageLevel)
        defaults.removeObject(forKey: kFireRateLevel)
        defaults.removeObject(forKey: kRangeLevel)
        defaults.removeObject(forKey: kHealthLevel)
        defaults.removeObject(forKey: kDefenseLevel)
        defaults.removeObject(forKey: kUziUnlocked)
        defaults.removeObject(forKey: kRocketUnlocked)
        defaults.removeObject(forKey: kFreezeUnlocked)
        defaults.removeObject(forKey: kLaserUnlocked)
        defaults.removeObject(forKey: kShieldUnlocked)
        defaults.removeObject(forKey: kEmpUnlocked)
        defaults.removeObject(forKey: kUnlockedWeapons)
        defaults.removeObject(forKey: kActiveWeapon)
        defaults.removeObject(forKey: kBladeUnlocked)
        defaults.removeObject(forKey: kWeaponRentals)
        defaults.removeObject(forKey: kTurretSlotsUnlocked)
    }
}
