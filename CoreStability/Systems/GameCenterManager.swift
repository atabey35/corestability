// GameCenterManager.swift
// CoreStability
// Manages Game Center authentication, leaderboards, and achievements

import GameKit

final class GameCenterManager: NSObject {
    static let shared = GameCenterManager()
    
    // MARK: - Leaderboard IDs (Configure in App Store Connect)
    
    struct LeaderboardID {
        static let highScore = "com.corestability.leaderboard.highscore"
        static let highWave = "com.corestability.leaderboard.highwave"
        static let weeklyScore = "com.corestability.leaderboard.weekly"
    }
    
    // MARK: - Achievement IDs
    
    struct AchievementID {
        static let firstWave = "com.corestability.achievement.firstwave"
        static let wave10 = "com.corestability.achievement.wave10"
        static let wave25 = "com.corestability.achievement.wave25"
        static let wave50 = "com.corestability.achievement.wave50"
        static let bossSlayer = "com.corestability.achievement.bossslayer"
        static let combo20 = "com.corestability.achievement.combo20"
    }
    
    // MARK: - Properties
    
    var isAuthenticated: Bool {
        return GKLocalPlayer.local.isAuthenticated
    }
    
    var localPlayerName: String {
        return GKLocalPlayer.local.displayName
    }
    
    private var authenticationViewController: UIViewController?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Authentication
    
    func authenticatePlayer(presentingViewController: UIViewController, completion: @escaping (Bool, Error?) -> Void) {
        let player = GKLocalPlayer.local
        
        player.authenticateHandler = { [weak self] viewController, error in
            if let vc = viewController {
                // Need to show login UI
                self?.authenticationViewController = vc
                presentingViewController.present(vc, animated: true)
                completion(false, nil)
            } else if player.isAuthenticated {
                // Successfully authenticated
                print("[GameCenter] Authenticated as: \(player.displayName)")
                
                // Update LeaderboardManager with Game Center name
                LeaderboardManager.shared.playerName = player.displayName
                
                completion(true, nil)
            } else if let error = error {
                // Authentication failed
                print("[GameCenter] Auth failed: \(error.localizedDescription)")
                completion(false, error)
            } else {
                completion(false, nil)
            }
        }
    }
    
    // MARK: - Submit Score
    
    func submitScore(_ score: Int, leaderboardID: String = LeaderboardID.highScore) {
        guard isAuthenticated else {
            print("[GameCenter] Not authenticated, score not submitted")
            return
        }
        
        GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [leaderboardID]
        ) { error in
            if let error = error {
                print("[GameCenter] Score submit failed: \(error.localizedDescription)")
            } else {
                print("[GameCenter] Score \(score) submitted to \(leaderboardID)")
            }
        }
    }
    
    func submitWave(_ wave: Int) {
        submitScore(wave, leaderboardID: LeaderboardID.highWave)
    }
    
    func submitGameOver(score: Int, wave: Int) {
        submitScore(score, leaderboardID: LeaderboardID.highScore)
        submitScore(score, leaderboardID: LeaderboardID.weeklyScore)
        submitWave(wave)
    }
    
    // MARK: - Load Leaderboard
    
    func loadLeaderboard(
        leaderboardID: String = LeaderboardID.highScore,
        timeScope: GKLeaderboard.TimeScope = .allTime,
        range: NSRange = NSRange(location: 1, length: 100),
        completion: @escaping ([GKLeaderboard.Entry]?, GKLeaderboard.Entry?, Error?) -> Void
    ) {
        guard isAuthenticated else {
            completion(nil, nil, nil)
            return
        }
        
        GKLeaderboard.loadLeaderboards(IDs: [leaderboardID]) { leaderboards, error in
            guard let leaderboard = leaderboards?.first, error == nil else {
                completion(nil, nil, error)
                return
            }
            
            leaderboard.loadEntries(for: .global, timeScope: timeScope, range: range) { localEntry, entries, totalCount, error in
                completion(entries, localEntry, error)
            }
        }
    }
    
    func loadFriendsLeaderboard(
        leaderboardID: String = LeaderboardID.highScore,
        completion: @escaping ([GKLeaderboard.Entry]?, Error?) -> Void
    ) {
        guard isAuthenticated else {
            completion(nil, nil)
            return
        }
        
        GKLeaderboard.loadLeaderboards(IDs: [leaderboardID]) { leaderboards, error in
            guard let leaderboard = leaderboards?.first, error == nil else {
                completion(nil, error)
                return
            }
            
            leaderboard.loadEntries(for: .friendsOnly, timeScope: .allTime, range: NSRange(location: 1, length: 100)) { _, entries, _, error in
                completion(entries, error)
            }
        }
    }
    
    // MARK: - Show Game Center UI
    
    func showLeaderboard(from viewController: UIViewController, leaderboardID: String = LeaderboardID.highScore) {
        if !isAuthenticated {
            print("[GameCenter] Not authenticated. Attempting login...")
            authenticatePlayer(presentingViewController: viewController) { [weak self] success, _ in
                if success {
                    // Recursive call now that we are authenticated
                    self?.showLeaderboard(from: viewController, leaderboardID: leaderboardID)
                }
            }
            return
        }
        
        let gcVC = GKGameCenterViewController(leaderboardID: leaderboardID, playerScope: .global, timeScope: .allTime)
        gcVC.gameCenterDelegate = self
        viewController.present(gcVC, animated: true)
    }
    
    func showAchievements(from viewController: UIViewController) {
        guard isAuthenticated else { return }
        
        let gcVC = GKGameCenterViewController(state: .achievements)
        gcVC.gameCenterDelegate = self
        viewController.present(gcVC, animated: true)
    }
    
    func showGameCenter(from viewController: UIViewController) {
        guard isAuthenticated else { return }
        
        let gcVC = GKGameCenterViewController(state: .default)
        gcVC.gameCenterDelegate = self
        viewController.present(gcVC, animated: true)
    }
    
    // MARK: - Achievements
    
    func reportAchievement(_ identifier: String, percentComplete: Double = 100.0) {
        guard isAuthenticated else { return }
        
        let achievement = GKAchievement(identifier: identifier)
        achievement.percentComplete = percentComplete
        achievement.showsCompletionBanner = true
        
        GKAchievement.report([achievement]) { error in
            if let error = error {
                print("[GameCenter] Achievement report failed: \(error.localizedDescription)")
            } else {
                print("[GameCenter] Achievement reported: \(identifier)")
            }
        }
    }
    
    // Game-specific achievement tracking
    func checkWaveAchievements(wave: Int) {
        if wave >= 1 { reportAchievement(AchievementID.firstWave) }
        if wave >= 10 { reportAchievement(AchievementID.wave10) }
        if wave >= 25 { reportAchievement(AchievementID.wave25) }
        if wave >= 50 { reportAchievement(AchievementID.wave50) }
    }
    
    func checkComboAchievement(combo: Int) {
        if combo >= 20 { reportAchievement(AchievementID.combo20) }
    }
    
    func reportBossKill() {
        reportAchievement(AchievementID.bossSlayer)
    }
}

// MARK: - GKGameCenterControllerDelegate

extension GameCenterManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
