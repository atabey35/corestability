// CurrencyManager.swift
// Idle Tower Defense
// Manages coins earned from killing enemies

import Foundation

protocol CurrencyManagerDelegate: AnyObject {
    func currencyManager(_ manager: CurrencyManager, didUpdateCoins coins: Int)
}

final class CurrencyManager {
    static let shared = CurrencyManager()
    
    weak var delegate: CurrencyManagerDelegate?
    
    private let defaults = UserDefaults.standard
    private let coinsKey = "playerCoins"
    
    var coins: Int = 0 {
        didSet {
            delegate?.currencyManager(self, didUpdateCoins: coins)
            save()
        }
    }
    
    private(set) var totalEarned: Int = 0
    
    init() {
        self.coins = defaults.integer(forKey: coinsKey)
    }
    
    func addCoins(_ amount: Int) {
        coins += amount
        totalEarned += amount
        // saved via didSet
    }
    
    func spendCoins(_ amount: Int) -> Bool {
        if coins >= amount {
            coins -= amount
            // saved via didSet
            return true
        }
        return false
    }
    
    private func save() {
        defaults.set(coins, forKey: coinsKey)
    }

    func reset() {
        // Coins are not reset on death, supports cumulative progression
        // Only totalEarned might be relevant for session stats, but for now we keep it simple
    }
}
