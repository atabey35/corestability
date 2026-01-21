// LeaderboardManager.swift
// CoreStability
// Manages leaderboard rankings and score tracking

import Foundation

struct LeaderboardEntry: Codable, Identifiable {
    let id: String
    let playerName: String
    let score: Int
    let wave: Int
    let chapter: Int
    let timestamp: Date
    var rank: Int = 0
}

enum LeaderboardType: String, CaseIterable {
    case allTime = "All Time"
    case weekly = "Weekly"
    case daily = "Daily"
}

final class LeaderboardManager {
    static let shared = LeaderboardManager()
    
    private let defaults = UserDefaults.standard
    private let playerNameKey = "playerName"
    private let playerIdKey = "playerId"
    private let highScoreKey = "highScore"
    private let highWaveKey = "highWave"
    private let localEntriesKey = "localLeaderboardEntries"
    
    // MARK: - Player Info
    
    var playerId: String {
        if let id = defaults.string(forKey: playerIdKey) {
            return id
        }
        let newId = UUID().uuidString
        defaults.set(newId, forKey: playerIdKey)
        return newId
    }
    
    var playerName: String {
        get { defaults.string(forKey: playerNameKey) ?? "Player\(Int.random(in: 1000...9999))" }
        set { defaults.set(newValue, forKey: playerNameKey) }
    }
    
    var highScore: Int {
        get { defaults.integer(forKey: highScoreKey) }
        set { defaults.set(newValue, forKey: highScoreKey) }
    }
    
    var highWave: Int {
        get { defaults.integer(forKey: highWaveKey) }
        set { defaults.set(newValue, forKey: highWaveKey) }
    }
    
    private init() {}
    
    // MARK: - Score Submission
    
    func submitScore(wave: Int, chapter: Int, coins: Int) {
        let score = calculateScore(wave: wave, chapter: chapter, coins: coins)
        
        // Update local high score
        if score > highScore {
            highScore = score
            highWave = wave
        }
        
        let entry = LeaderboardEntry(
            id: UUID().uuidString,
            playerName: playerName,
            score: score,
            wave: wave,
            chapter: chapter,
            timestamp: Date()
        )
        
        // Save locally (simulating server)
        saveLocalEntry(entry)
        
        // TODO: Submit to Game Center or Firebase
        Analytics.logEvent("leaderboard_submit", parameters: [
            "score": score,
            "wave": wave,
            "chapter": chapter
        ])
    }
    
    private func calculateScore(wave: Int, chapter: Int, coins: Int) -> Int {
        // Score formula: base from waves + chapter bonus + coin bonus
        let waveScore = wave * 100
        let chapterBonus = chapter * 1000
        let coinBonus = coins / 10
        return waveScore + chapterBonus + coinBonus
    }
    
    // MARK: - Local Storage (Simulated Leaderboard)
    
    private func saveLocalEntry(_ entry: LeaderboardEntry) {
        var entries = getLocalEntries()
        
        // Check if player already has entry
        if let index = entries.firstIndex(where: { $0.playerName == entry.playerName }) {
            if entry.score > entries[index].score {
                entries[index] = entry
            }
        } else {
            entries.append(entry)
        }
        
        // Sort by score
        entries.sort { $0.score > $1.score }
        
        // Keep top 100
        if entries.count > 100 {
            entries = Array(entries.prefix(100))
        }
        
        // Assign ranks
        for i in 0..<entries.count {
            entries[i].rank = i + 1
        }
        
        // Save
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: localEntriesKey)
        }
    }
    
    func getLocalEntries() -> [LeaderboardEntry] {
        guard let data = defaults.data(forKey: localEntriesKey),
              let entries = try? JSONDecoder().decode([LeaderboardEntry].self, from: data) else {
            return generateMockEntries()
        }
        return entries
    }
    
    // MARK: - Mock Data (For Demo)
    
    private func generateMockEntries() -> [LeaderboardEntry] {
        let names = ["xXDragonSlayerXx", "TowerMaster99", "WaveDestroyer", "ProGamer2026",
                    "CasualKing", "NoobSlayer", "BossHunter", "GemCollector",
                    "SpeedRunner", "ChapterChamp", "WaveRider", "TurretKing",
                    "SkillMaster", "PerkLord", "ComboKing", "CriticalHit",
                    "RangeBoost", "DamageDealer", "CoinHoarder", "XPFarmer"]
        
        var entries: [LeaderboardEntry] = []
        
        for (index, name) in names.enumerated() {
            let score = 50000 - (index * 2000) + Int.random(in: -500...500)
            let wave = 30 - index + Int.random(in: -5...5)
            let chapter = max(1, min(10, wave / 5))
            
            entries.append(LeaderboardEntry(
                id: UUID().uuidString,
                playerName: name,
                score: max(1000, score),
                wave: max(1, wave),
                chapter: chapter,
                timestamp: Date().addingTimeInterval(TimeInterval(-index * 3600)),
                rank: index + 1
            ))
        }
        
        // Save generated entries
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: localEntriesKey)
        }
        
        return entries
    }
    
    // MARK: - Filtered Leaderboards
    
    func getLeaderboard(type: LeaderboardType) -> [LeaderboardEntry] {
        var entries = getLocalEntries()
        
        let calendar = Calendar.current
        let now = Date()
        
        switch type {
        case .daily:
            entries = entries.filter { calendar.isDateInToday($0.timestamp) }
        case .weekly:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            entries = entries.filter { $0.timestamp >= weekAgo }
        case .allTime:
            break // No filter
        }
        
        // Re-rank
        for i in 0..<entries.count {
            entries[i].rank = i + 1
        }
        
        return entries
    }
    
    func getPlayerRank(type: LeaderboardType = .allTime) -> Int? {
        let entries = getLeaderboard(type: type)
        return entries.first { $0.playerName == playerName }?.rank
    }
    
    // MARK: - Rewards
    
    func claimWeeklyReward() -> Int? {
        guard let rank = getPlayerRank(type: .weekly) else { return nil }
        
        let gems: Int
        switch rank {
        case 1: gems = 500
        case 2: gems = 300
        case 3: gems = 200
        case 4...10: gems = 100
        case 11...50: gems = 50
        case 51...100: gems = 25
        default: gems = 10
        }
        
        GemManager.shared.addGems(gems, source: .achievement)
        return gems
    }
}
