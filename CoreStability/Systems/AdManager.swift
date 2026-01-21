// AdManager.swift
// CoreStability
// Manages rewarded ads and ad-based rewards

import Foundation
import GoogleMobileAds
import UIKit

enum AdType: String {
    case rewardedCoinBonus = "rewarded_coin_bonus"
    case rewardedRevive = "rewarded_revive"
    case rewardedDailyGems = "rewarded_daily_gems"
    case rewardedDoubleXP = "rewarded_double_xp"
    case interstitial = "interstitial"
}

protocol AdManagerDelegate: AnyObject {
    func adManager(_ manager: AdManager, didCompleteRewardedAd type: AdType)
    func adManager(_ manager: AdManager, didFailToLoad type: AdType)
}

final class AdManager: NSObject, FullScreenContentDelegate {
    static let shared = AdManager()
    
    weak var delegate: AdManagerDelegate?
    
    private let defaults = UserDefaults.standard
    private let dailyGemAdsKey = "dailyGemAdsWatched"
    private let lastGemAdDateKey = "lastGemAdDate"
    
    // Real Ad Unit ID provided by user
    // Test ID: ca-app-pub-3940256099942544/1712485313
    // Real ID: ca-app-pub-6821199968366776/6956111301
    private let adUnitID = "ca-app-pub-6821199968366776/6956111301"
    // NOTE: If testing on simulator, always use Test ID or add device as test device.
    // For safety in dev builds, I will use the TEST ID.
    // USER: CHANGE THIS TO YOUR REAL ID BEFORE RELEASE
    private let activeAdUnitID = "ca-app-pub-6821199968366776/6956111301" 
    
    private var rewardedAd: RewardedAd?
    
    // Config
    let maxDailyGemAds = 5
    let gemsPerAd = 10
    
    private override init() {
        super.init()
        loadRewardedAd()
    }
    
    func loadRewardedAd() {
        RewardedAd.load(with: activeAdUnitID, request: Request()) { [weak self] ad, error in
            if let error = error {
                print("Failed to load rewarded ad with error: \(error.localizedDescription)")
                return
            }
            self?.rewardedAd = ad
            self?.rewardedAd?.fullScreenContentDelegate = self
            print("Rewarded ad loaded.")
        }
    }
    
    // MARK: - Daily Gem Ads
    
    var dailyGemAdsWatched: Int {
        if let lastDate = defaults.object(forKey: lastGemAdDateKey) as? Date,
           !Calendar.current.isDateInToday(lastDate) {
            defaults.set(0, forKey: dailyGemAdsKey)
        }
        return defaults.integer(forKey: dailyGemAdsKey)
    }
    
    var canWatchGemAd: Bool {
        return dailyGemAdsWatched < maxDailyGemAds
    }
    
    var remainingGemAds: Int {
        return max(0, maxDailyGemAds - dailyGemAdsWatched)
    }
    
    // MARK: - Show Ads
    
    func showRewardedAd(type: AdType, completion: @escaping (Bool) -> Void) {
        // Ensure ad is ready
        guard let ad = rewardedAd else {
            print("Ad wasn't ready")
            loadRewardedAd() // Try loading next one
            delegate?.adManager(self, didFailToLoad: type)
            completion(false)
            return
        }
        
        // Find root VC (iOS 15+ compatible)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            completion(false)
            return
        }
        
        do {
            try ad.canPresent(from: rootVC)
            ad.present(from: rootVC) { [weak self] in
                guard let self = self else { return }
                
                // Reward User
                self.handleRewardedAdComplete(type: type)
                completion(true)
                
                // Preload next ad
                self.rewardedAd = nil
                self.loadRewardedAd()
            }
        } catch {
            print("Ad cannot be presented: \(error)")
            completion(false)
        }
    }
    
    private func handleRewardedAdComplete(type: AdType) {
        switch type {
        case .rewardedDailyGems:
            defaults.set(dailyGemAdsWatched + 1, forKey: dailyGemAdsKey)
            defaults.set(Date(), forKey: lastGemAdDateKey)
            GemManager.shared.addGems(gemsPerAd, source: .rewardedAd)
            
        case .rewardedRevive:
            // Handled by callback in GameScene
            break
            
        default: break
        }
        
        delegate?.adManager(self, didCompleteRewardedAd: type)
    }
    
    // MARK: - FullScreenContentDelegate
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad did fail to present full screen content.")
        loadRewardedAd()
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Ad did dismiss full screen content.")
        loadRewardedAd()
    }
    
    // MARK: - Interstitial Logic (Placeholder)
    
    private var gameOverCount = 0
    private let interstitialFrequency = 3
    
    func onGameOver() {
        gameOverCount += 1
        // Could show interstitial every N game overs if desired
        // For now, just preload the rewarded ad
        if rewardedAd == nil {
            loadRewardedAd()
        }
    }
}

