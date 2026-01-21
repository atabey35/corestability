// DailyQuestManager.swift
// CoreStability
// Manages daily quests for player retention

import Foundation

enum QuestType: String, Codable {
    case killEnemies = "kill_enemies"
    case completeWaves = "complete_waves"
    case killBosses = "kill_bosses"
    case useSkill = "use_skill"
    case reachCombo = "reach_combo"
    case earnCoins = "earn_coins"
}

struct DailyQuest: Codable {
    let id: String
    let type: QuestType
    let description: String
    let target: Int
    var progress: Int
    let coinReward: Int
    let gemReward: Int
    let xpReward: Int
    
    var isComplete: Bool {
        return progress >= target
    }
    
    var progressText: String {
        return "\(min(progress, target))/\(target)"
    }
}

final class DailyQuestManager {
    static let shared = DailyQuestManager()
    
    private let defaults = UserDefaults.standard
    private let questsKey = "dailyQuests"
    private let lastRefreshKey = "dailyQuestsLastRefresh"
    private let claimedKey = "dailyQuestsClaimed"
    
    private(set) var quests: [DailyQuest] = []
    
    var claimedQuestIDs: Set<String> {
        get { Set(defaults.array(forKey: claimedKey) as? [String] ?? []) }
        set { defaults.set(Array(newValue), forKey: claimedKey) }
    }
    
    private init() {
        loadOrRefreshQuests()
    }
    
    // MARK: - Quest Generation
    
    private func loadOrRefreshQuests() {
        // Check if we need to refresh (new day)
        if let lastRefresh = defaults.object(forKey: lastRefreshKey) as? Date,
           Calendar.current.isDateInToday(lastRefresh) {
            // Load saved quests
            if let data = defaults.data(forKey: questsKey),
               let saved = try? JSONDecoder().decode([DailyQuest].self, from: data) {
                quests = saved
                return
            }
        }
        
        // Generate new quests
        generateNewQuests()
    }
    
    private func generateNewQuests() {
        quests = [
            generateQuest(difficulty: .easy),
            generateQuest(difficulty: .medium),
            generateQuest(difficulty: .hard)
        ]
        
        // Clear claimed
        claimedQuestIDs = []
        
        // Save
        saveQuests()
        defaults.set(Date(), forKey: lastRefreshKey)
    }
    
    private enum Difficulty {
        case easy, medium, hard
    }
    
    private func generateQuest(difficulty: Difficulty) -> DailyQuest {
        let id = UUID().uuidString
        
        switch difficulty {
        case .easy:
            let options: [(QuestType, String, Int)] = [
                (.killEnemies, "Kill 50 enemies", 50),
                (.completeWaves, "Complete 5 waves", 5),
                (.earnCoins, "Earn 500 coins", 500)
            ]
            let choice = options.randomElement()!
            return DailyQuest(id: id, type: choice.0, description: choice.1, target: choice.2,
                            progress: 0, coinReward: 500, gemReward: 5, xpReward: 50)
            
        case .medium:
            let options: [(QuestType, String, Int)] = [
                (.killEnemies, "Kill 200 enemies", 200),
                (.completeWaves, "Complete 15 waves", 15),
                (.killBosses, "Kill 2 bosses", 2),
                (.reachCombo, "Reach 20 combo", 20)
            ]
            let choice = options.randomElement()!
            return DailyQuest(id: id, type: choice.0, description: choice.1, target: choice.2,
                            progress: 0, coinReward: 1500, gemReward: 15, xpReward: 100)
            
        case .hard:
            let options: [(QuestType, String, Int)] = [
                (.killEnemies, "Kill 500 enemies", 500),
                (.completeWaves, "Complete 30 waves", 30),
                (.killBosses, "Kill 5 bosses", 5),
                (.reachCombo, "Reach 50 combo", 50)
            ]
            let choice = options.randomElement()!
            return DailyQuest(id: id, type: choice.0, description: choice.1, target: choice.2,
                            progress: 0, coinReward: 3000, gemReward: 30, xpReward: 200)
        }
    }
    
    // MARK: - Progress Tracking
    
    func trackKill(isBoss: Bool) {
        updateProgress(type: .killEnemies, amount: 1)
        if isBoss {
            updateProgress(type: .killBosses, amount: 1)
        }
    }
    
    func trackWaveComplete() {
        updateProgress(type: .completeWaves, amount: 1)
    }
    
    func trackCombo(_ combo: Int) {
        // Only update if this is a new high for the quest
        for i in 0..<quests.count {
            if quests[i].type == .reachCombo && combo > quests[i].progress {
                quests[i].progress = combo
            }
        }
        saveQuests()
    }
    
    func trackCoinsEarned(_ amount: Int) {
        updateProgress(type: .earnCoins, amount: amount)
    }
    
    func trackSkillUsed() {
        updateProgress(type: .useSkill, amount: 1)
    }
    
    private func updateProgress(type: QuestType, amount: Int) {
        for i in 0..<quests.count {
            if quests[i].type == type {
                quests[i].progress += amount
            }
        }
        saveQuests()
    }
    
    private func saveQuests() {
        if let data = try? JSONEncoder().encode(quests) {
            defaults.set(data, forKey: questsKey)
        }
    }
    
    // MARK: - Claiming
    
    func canClaim(quest: DailyQuest) -> Bool {
        return quest.isComplete && !claimedQuestIDs.contains(quest.id)
    }
    
    func claimReward(questID: String, currencyManager: CurrencyManager) -> DailyQuest? {
        guard let quest = quests.first(where: { $0.id == questID }),
              canClaim(quest: quest) else { return nil }
        
        // Award rewards
        if quest.coinReward > 0 { currencyManager.addCoins(quest.coinReward) }
        if quest.gemReward > 0 { GemManager.shared.addGems(quest.gemReward, source: .event) }
        if quest.xpReward > 0 { BattlePassManager.shared.onDailyQuestComplete() }
        
        // Mark claimed
        var claimed = claimedQuestIDs
        claimed.insert(questID)
        claimedQuestIDs = claimed
        
        return quest
    }
    
    // MARK: - UI Helpers
    
    func getUnclaimedCompleteCount() -> Int {
        return quests.filter { canClaim(quest: $0) }.count
    }
    
    func refreshIfNeeded() {
        loadOrRefreshQuests()
    }
}
