//
//  InventoryManager.swift
//  CoreStability
//
//  Created by Agent on 2026-01-03.
//

import Foundation

enum ItemType: String, Codable {
    case potion     // Stat boost (Damage, Speed, HP)
    case scroll     // Utility (XP, Coin)
    case artifact   // Unique Mechanics (Legendary effects)
}

struct InventoryItem: Codable, Equatable {
    let id: String
    let name: String
    let type: ItemType
    let rarity: GachaRarity // Using GachaRarity from GachaManager or redefined here? Let's use string for now or map it.
    let description: String
    let duration: TimeInterval
    
    // Visuals
    let icon: String // SF Symbol or Emoji
}

// Helper for Rarity to avoid circular or complex deps if GachaManager isn't ready
enum ItemRarity: String, Codable {
    case common = "Common"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"
}

class InventoryManager {
    static let shared = InventoryManager()
    
    // Storage Keys
    private let kInventory = "CS_Inventory_V1"
    private let kActiveBuffs = "CS_ActiveBuffs_V1"
    
    // iCloud Key-Value Store for cross-device sync
    private let iCloud = NSUbiquitousKeyValueStore.default
    private let iCloudInventoryKey = "iCloud_Inventory_V1"
    
    // State
    // ItemID -> Quantity
    private(set) var inventory: [String: Int] = [:]
    
    // ItemID -> ExpirationTime
    private(set) var activeBuffs: [String: Date] = [:]
    
    // Definitions (Hardcoded for now, could be JSON)
    private var itemDefinitions: [String: InventoryItem] = [:]
    
    private init() {
        setupDefinitions()
        
        // Listen for iCloud changes from other devices
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloud
        )
        
        // Start iCloud sync
        iCloud.synchronize()
        
        loadData()
        
        // Timer to auto-cleanup expired buffs every minute
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.cleanupExpiredBuffs()
        }
    }
    
    // MARK: - iCloud Sync
    
    @objc private func iCloudDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let changeReason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
            return
        }
        
        if changeReason == NSUbiquitousKeyValueStoreServerChange ||
           changeReason == NSUbiquitousKeyValueStoreInitialSyncChange {
            mergeWithiCloud()
        }
    }
    
    private func mergeWithiCloud() {
        // Get iCloud inventory
        guard let iCloudData = iCloud.dictionary(forKey: iCloudInventoryKey) as? [String: Int] else {
            // No iCloud data, just sync local to cloud
            syncToiCloud()
            return
        }
        
        // Merge: for each item, use the MAX count (prevents accidental loss)
        var merged = inventory
        for (itemId, cloudCount) in iCloudData {
            let localCount = merged[itemId] ?? 0
            merged[itemId] = max(localCount, cloudCount)
        }
        
        if merged != inventory {
            inventory = merged
            UserDefaults.standard.set(inventory, forKey: kInventory)
            print("[InventoryManager] Merged inventory from iCloud")
        }
        
        syncToiCloud()
    }
    
    private func syncToiCloud() {
        iCloud.set(inventory, forKey: iCloudInventoryKey)
        iCloud.synchronize()
    }
    
    // MARK: - Setup
    
    private func setupDefinitions() {
        // --- LEGENDARY (3 Hours) ---
        define(id: "dmg_l1", name: "God Slayer".localized, type: .potion, rarity: .legendary, desc: "+50% DMG (3h)".localized, icon: "🔥", hours: 3)
        define(id: "crit_l1", name: "Destiny's Edge".localized, type: .potion, rarity: .legendary, desc: "+20% Crit (3h)".localized, icon: "⭐", hours: 3)
        define(id: "pen_l1", name: "Pierce All".localized, type: .potion, rarity: .legendary, desc: "Penetration +3 (3h)".localized, icon: "🏹", hours: 3)
        define(id: "coin_l1", name: "Midas Touch".localized, type: .potion, rarity: .legendary, desc: "+100% Coins (3h)".localized, icon: "💰", hours: 3)
        define(id: "all_l1", name: "Ascension".localized, type: .potion, rarity: .legendary, desc: "+25% All Stats (3h)".localized, icon: "👑", hours: 3)
        
        // --- EPIC (1 Hour) ---
        define(id: "dmg_e1", name: "Berserker".localized, type: .potion, rarity: .epic, desc: "+20% Damage (1h)".localized, icon: "😡", hours: 1)
        define(id: "crit_e1", name: "Executioner".localized, type: .potion, rarity: .epic, desc: "+10% Crit Rate (1h)".localized, icon: "🎯", hours: 1)
        define(id: "critdmg_e1", name: "Devastator".localized, type: .potion, rarity: .epic, desc: "+30% Crit DMG (1h)".localized, icon: "💥", hours: 1)
        define(id: "splash_e1", name: "Explosive".localized, type: .potion, rarity: .epic, desc: "+25% Splash (1h)".localized, icon: "💣", hours: 1)
        define(id: "hp_e1", name: "Iron Will".localized, type: .potion, rarity: .epic, desc: "+25% Health (1h)".localized, icon: "🛡️", hours: 1)
        
        // --- RARE (30 Minutes) ---
        define(id: "dmg_r1", name: "Power Strike".localized, type: .potion, rarity: .rare, desc: "+10% Damage (30m)".localized, icon: "⚔️", minutes: 30)
        define(id: "crit_r1", name: "Lucky Shot".localized, type: .potion, rarity: .rare, desc: "+5% Crit (30m)".localized, icon: "🤞", minutes: 30)
        define(id: "spd_r1", name: "Rapid Fire".localized, type: .potion, rarity: .rare, desc: "+10% Attack Speed (30m)".localized, icon: "⚡", minutes: 30)
        define(id: "coin_r1", name: "Gold Rush".localized, type: .potion, rarity: .rare, desc: "+15% Coins (30m)".localized, icon: "🪙", minutes: 30)
        define(id: "start_r1", name: "Trust Fund".localized, type: .scroll, rarity: .rare, desc: "+500 Start Gold (30m)".localized, icon: "📜", minutes: 30)
        
        // --- COMMON (15 Minutes) ---
        define(id: "dmg_c1", name: "Minor Damage".localized, type: .potion, rarity: .common, desc: "+5% Damage (15m)".localized, icon: "🗡️", minutes: 15)
        define(id: "spd_c1", name: "Quick Hands".localized, type: .potion, rarity: .common, desc: "+5% Attack Speed (15m)".localized, icon: "✋", minutes: 15)
        define(id: "coin_c1", name: "Coin Hunter".localized, type: .potion, rarity: .common, desc: "+5% Coins (15m)".localized, icon: "🔍", minutes: 15)
        define(id: "hp_c1", name: "Tough Skin".localized, type: .potion, rarity: .common, desc: "+5% Health (15m)".localized, icon: "🧱", minutes: 15)
        define(id: "rng_c1", name: "Keen Eye".localized, type: .potion, rarity: .common, desc: "+5% Range (15m)".localized, icon: "👁️", minutes: 15)
    }
    
    private func define(id: String, name: String, type: ItemType, rarity: ItemRarity, desc: String, icon: String, hours: Double = 0, minutes: Double = 0) {
        let duration = (hours * 3600) + (minutes * 60)
        // Map ItemRarity to matching Gacha Logic later if needed
        let item = InventoryItem(id: id, name: name, type: type, rarity: rarity.rawValue, description: desc, duration: duration, icon: icon) 
        // Note: Rarity struct in item is simplified, we store definition.
        itemDefinitions[id] = item
    }
    
    // MARK: - Public API
    
    func getItemDetails(id: String) -> InventoryItem? {
        return itemDefinitions[id]
    }
    
    func addItem(id: String, amount: Int = 1) {
        inventory[id, default: 0] += amount
        saveData()
    }
    
    func useItem(id: String) -> Bool {
        guard let count = inventory[id], count > 0 else { return false }
        guard let item = itemDefinitions[id] else { return false }
        
        // Consume 1
        inventory[id] = count - 1
        if inventory[id] == 0 {
            inventory.removeValue(forKey: id)
        }
        
        // Add/Extend Duration
        let now = Date()
        let currentExpiry = activeBuffs[id] ?? now
        // If expired, start from now. If active, add to remaining time.
        let effectiveStart = (currentExpiry > now) ? currentExpiry : now
        let newExpiry = effectiveStart.addingTimeInterval(item.duration)
        
        activeBuffs[id] = newExpiry
        saveData()
        
        NotificationCenter.default.post(name: .buffsUpdated, object: nil)
        return true
    }
    
    func getActiveBuffIDs() -> [String] {
        cleanupExpiredBuffs(notify: false) // Read-only access shouldn't trigger recursive notifications broadly
        return Array(activeBuffs.keys)
    }
    
    func hasActiveBuff(id: String) -> Bool {
        guard let expiry = activeBuffs[id] else { return false }
        return expiry > Date()
    }
    
    func getRemainingTime(id: String) -> TimeInterval {
        guard let expiry = activeBuffs[id] else { return 0 }
        return max(0, expiry.timeIntervalSinceNow)
    }
    
    // MARK: - Internal
    
    private func cleanupExpiredBuffs(notify: Bool = true) {
        let now = Date()
        var changed = false
        for (id, expiry) in activeBuffs {
            if expiry < now {
                activeBuffs.removeValue(forKey: id)
                changed = true
            }
        }
        if changed {
            saveData()
            if notify {
                NotificationCenter.default.post(name: .buffsUpdated, object: nil)
            }
        }
    }
    
    // MARK: - Persistence
    
    private func loadData() {
        if let data = UserDefaults.standard.dictionary(forKey: kInventory) as? [String: Int] {
            inventory = data
        }
        
        if let buffData = UserDefaults.standard.dictionary(forKey: kActiveBuffs) as? [String: Date] {
            activeBuffs = buffData
        }
        
        // Initial cleanup - Silent to avoid init-recursion
        cleanupExpiredBuffs(notify: false)
    }
    
    private func saveData() {
        UserDefaults.standard.set(inventory, forKey: kInventory)
        UserDefaults.standard.set(activeBuffs, forKey: kActiveBuffs)
        syncToiCloud()
    }
}

extension Notification.Name {
    static let buffsUpdated = Notification.Name("CS_BuffsUpdated")
}

// Temporary for compilation compatibility with GachaManager's rarity if needed, 
// using GachaRarity inside Item definition but creating a standalone Enum for cleaner separation first.
typealias GachaRarity = String // Placeholder if we don't import GachaManager's enum directly
