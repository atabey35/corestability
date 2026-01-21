// GemManager.swift
// CoreStability
// Manages premium currency (Gems) for monetization with iCloud sync

import Foundation

final class GemManager {
    static let shared = GemManager()
    
    private let defaults = UserDefaults.standard
    private let gemsKey = "playerGems"
    
    // iCloud Key-Value Store for cross-device sync
    private let iCloud = NSUbiquitousKeyValueStore.default
    private let iCloudGemsKey = "iCloud_playerGems"
    
    // MARK: - Gem Balance (with iCloud sync)
    
    var gems: Int {
        get { defaults.integer(forKey: gemsKey) }
        set { 
            defaults.set(newValue, forKey: gemsKey)
            syncToiCloud(newValue)
            NotificationCenter.default.post(name: .gemsDidChange, object: nil)
        }
    }
    
    private init() {
        // Listen for iCloud changes from other devices
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloud
        )
        
        // Start iCloud sync
        iCloud.synchronize()
        
        // First time bonus
        if !defaults.bool(forKey: "gemManagerInitialized") {
            gems = 100 // Starter gems
            defaults.set(true, forKey: "gemManagerInitialized")
        } else {
            // Merge local and iCloud data - use the higher value
            mergeWithiCloud()
        }
    }
    
    // MARK: - iCloud Sync
    
    private func syncToiCloud(_ value: Int) {
        iCloud.set(value, forKey: iCloudGemsKey)
        iCloud.synchronize()
    }
    
    private func mergeWithiCloud() {
        let localGems = defaults.integer(forKey: gemsKey)
        let iCloudGems = Int(iCloud.longLong(forKey: iCloudGemsKey))
        
        // Use the higher value to prevent accidental data loss
        let mergedValue = max(localGems, iCloudGems)
        
        if mergedValue != localGems {
            defaults.set(mergedValue, forKey: gemsKey)
            NotificationCenter.default.post(name: .gemsDidChange, object: nil)
            print("[GemManager] Restored \(mergedValue - localGems) gems from iCloud")
        }
        
        // Ensure iCloud has the latest
        if mergedValue != iCloudGems {
            syncToiCloud(mergedValue)
        }
    }
    
    @objc private func iCloudDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let changeReason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
            return
        }
        
        // Handle external changes (from another device)
        if changeReason == NSUbiquitousKeyValueStoreServerChange ||
           changeReason == NSUbiquitousKeyValueStoreInitialSyncChange {
            mergeWithiCloud()
        }
    }
    
    // MARK: - Transactions
    
    func addGems(_ amount: Int, source: GemSource) {
        gems += amount
        Analytics.logGemEarned(amount: amount, source: source)
    }
    
    func spendGems(_ amount: Int, purpose: GemPurpose) -> Bool {
        guard gems >= amount else { return false }
        gems -= amount
        Analytics.logGemSpent(amount: amount, purpose: purpose)
        return true
    }
    
    func canAfford(_ amount: Int) -> Bool {
        return gems >= amount
    }
    
    // MARK: - Manual Sync (for Settings screen)
    
    func forceSync() {
        iCloud.synchronize()
        mergeWithiCloud()
    }
    
    // MARK: - IAP Products
    
    static let gemPackages: [(id: String, gems: Int, bonus: Int, price: String)] = [
        ("com.corestability.gems.80", 80, 0, "$0.99"),
        ("com.corestability.gems.500", 500, 100, "$4.99"),
        ("com.corestability.gems.1200", 1200, 280, "$9.99"),
        ("com.corestability.gems.3500", 3500, 900, "$24.99"),
        ("com.corestability.gems.8000", 8000, 2400, "$49.99"),
        ("com.corestability.gems.20000", 20000, 8000, "$99.99")
    ]
}

// MARK: - Enums

enum GemSource: String {
    case purchase = "iap"
    case dailyLogin = "daily_login"
    case achievement = "achievement"
    case rewardedAd = "rewarded_ad"
    case battlePass = "battle_pass"
    case event = "event"
    case admin = "admin" // For testing
}

enum GemPurpose: String {
    case gachaPull = "gacha_pull"
    case battlePass = "battle_pass"
    case revive = "revive"
    case booster = "booster"
    case cosmetic = "cosmetic"
}

// MARK: - Notification

extension Notification.Name {
    static let gemsDidChange = Notification.Name("gemsDidChange")
}

// MARK: - Analytics Placeholder

struct Analytics {
    static func logGemEarned(amount: Int, source: GemSource) {
        print("[Analytics] Gem Earned: \(amount) from \(source.rawValue)")
        // TODO: Firebase Analytics integration
    }
    
    static func logGemSpent(amount: Int, purpose: GemPurpose) {
        print("[Analytics] Gem Spent: \(amount) for \(purpose.rawValue)")
        // TODO: Firebase Analytics integration
    }
    
    static func logEvent(_ name: String, parameters: [String: Any]) {
        print("[Analytics] Event: \(name) - \(parameters)")
        // TODO: Firebase Analytics integration
    }
}
