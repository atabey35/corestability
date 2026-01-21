// ClanManager.swift
// CoreStability
// Manages clan/guild system with bonuses and progression

import Foundation

struct Clan: Codable {
    let id: String
    var name: String
    var tag: String  // 3-4 letter tag
    var level: Int
    var experience: Int
    var memberIDs: [String]
    var leaderID: String
    var createdAt: Date
    
    var maxMembers: Int {
        return 10 + (level * 2) // Starts at 10, +2 per level
    }
    
    var xpForNextLevel: Int {
        return level * 1000
    }
}

struct ClanBonus {
    let name: String
    let description: String
    let value: Double
}

final class ClanManager {
    static let shared = ClanManager()
    
    private let defaults = UserDefaults.standard
    private let clanKey = "playerClan"
    private let clanDataKey = "clanData"
    private let lastContributionKey = "lastClanContribution"
    
    // MARK: - Current Clan
    
    var currentClan: Clan? {
        get {
            guard let data = defaults.data(forKey: clanKey),
                  let clan = try? JSONDecoder().decode(Clan.self, from: data) else {
                return nil
            }
            return clan
        }
        set {
            if let clan = newValue,
               let data = try? JSONEncoder().encode(clan) {
                defaults.set(data, forKey: clanKey)
            } else {
                defaults.removeObject(forKey: clanKey)
            }
        }
    }
    
    var isInClan: Bool {
        return currentClan != nil
    }
    
    private init() {}
    
    // MARK: - Clan Bonuses (Based on Level)
    
    func getClanBonuses() -> [ClanBonus] {
        guard let clan = currentClan else { return [] }
        
        var bonuses: [ClanBonus] = []
        
        // Base bonus
        bonuses.append(ClanBonus(
            name: "Clan Spirit",
            description: "+5% Coin Bonus",
            value: 0.05
        ))
        
        // Level-based bonuses
        if clan.level >= 2 {
            bonuses.append(ClanBonus(
                name: "Shared Wisdom",
                description: "+5% XP Bonus",
                value: 0.05
            ))
        }
        
        if clan.level >= 3 {
            bonuses.append(ClanBonus(
                name: "War Veterans",
                description: "+3% Damage",
                value: 0.03
            ))
        }
        
        if clan.level >= 5 {
            bonuses.append(ClanBonus(
                name: "United Front",
                description: "+5% HP",
                value: 0.05
            ))
        }
        
        if clan.level >= 7 {
            bonuses.append(ClanBonus(
                name: "Elite Training",
                description: "+5% Attack Speed",
                value: 0.05
            ))
        }
        
        if clan.level >= 10 {
            bonuses.append(ClanBonus(
                name: "Legendary Guild",
                description: "+10% All Stats",
                value: 0.10
            ))
        }
        
        return bonuses
    }
    
    // Computed bonuses for game integration
    var coinBonus: Double {
        guard isInClan else { return 0 }
        return 0.05 + (currentClan!.level >= 10 ? 0.10 : 0)
    }
    
    var damageBonus: Double {
        guard isInClan, let clan = currentClan else { return 0 }
        var bonus = 0.0
        if clan.level >= 3 { bonus += 0.03 }
        if clan.level >= 10 { bonus += 0.10 }
        return bonus
    }
    
    var hpBonus: Double {
        guard isInClan, let clan = currentClan else { return 0 }
        var bonus = 0.0
        if clan.level >= 5 { bonus += 0.05 }
        if clan.level >= 10 { bonus += 0.10 }
        return bonus
    }
    
    var attackSpeedBonus: Double {
        guard isInClan, let clan = currentClan else { return 0 }
        var bonus = 0.0
        if clan.level >= 7 { bonus += 0.05 }
        if clan.level >= 10 { bonus += 0.10 }
        return bonus
    }
    
    // MARK: - Clan Actions
    
    func createClan(name: String, tag: String) -> Bool {
        guard !isInClan else { return false }
        guard name.count >= 3 && name.count <= 20 else { return false }
        guard tag.count >= 2 && tag.count <= 4 else { return false }
        
        // Cost to create clan
        let createCost = 500
        guard GemManager.shared.spendGems(createCost, purpose: .booster) else { return false }
        
        let playerId = LeaderboardManager.shared.playerId
        
        let clan = Clan(
            id: UUID().uuidString,
            name: name,
            tag: tag.uppercased(),
            level: 1,
            experience: 0,
            memberIDs: [playerId],
            leaderID: playerId,
            createdAt: Date()
        )
        
        currentClan = clan
        
        Analytics.logEvent("clan_create", parameters: ["name": name])
        return true
    }
    
    func joinClan(_ clan: Clan) -> Bool {
        guard !isInClan else { return false }
        guard clan.memberIDs.count < clan.maxMembers else { return false }
        
        var updatedClan = clan
        updatedClan.memberIDs.append(LeaderboardManager.shared.playerId)
        currentClan = updatedClan
        
        Analytics.logEvent("clan_join", parameters: ["clanId": clan.id])
        return true
    }
    
    func leaveClan() -> Bool {
        guard isInClan else { return false }
        
        let clanId = currentClan?.id ?? ""
        currentClan = nil
        
        Analytics.logEvent("clan_leave", parameters: ["clanId": clanId])
        return true
    }
    
    // MARK: - Clan XP & Contribution
    
    func contributeXP(wave: Int) {
        guard var clan = currentClan else { return }
        
        // XP from wave completion
        let xp = wave * 5
        clan.experience += xp
        
        // Level up check
        while clan.experience >= clan.xpForNextLevel && clan.level < 10 {
            clan.experience -= clan.xpForNextLevel
            clan.level += 1
            
            Analytics.logEvent("clan_levelup", parameters: ["level": clan.level])
        }
        
        currentClan = clan
    }
    
    func contributeGems(_ amount: Int) -> Bool {
        guard var clan = currentClan else { return false }
        guard GemManager.shared.spendGems(amount, purpose: .booster) else { return false }
        
        // 1 gem = 10 XP
        let xp = amount * 10
        clan.experience += xp
        
        // Level up check
        while clan.experience >= clan.xpForNextLevel && clan.level < 10 {
            clan.experience -= clan.xpForNextLevel
            clan.level += 1
        }
        
        currentClan = clan
        
        Analytics.logEvent("clan_donate", parameters: ["gems": amount, "xp": xp])
        return true
    }
    
    // MARK: - Mock Clans (For Demo)
    
    func getAvailableClans() -> [Clan] {
        let clanNames = [
            ("Dragon Warriors", "DRG"),
            ("Night Owls", "NIT"),
            ("Elite Gamers", "ELT"),
            ("Wave Masters", "WAV"),
            ("Tower Legends", "TWR")
        ]
        
        return clanNames.enumerated().map { index, nameTag in
            Clan(
                id: "mock_\(index)",
                name: nameTag.0,
                tag: nameTag.1,
                level: Int.random(in: 1...8),
                experience: Int.random(in: 0...500),
                memberIDs: (0..<Int.random(in: 5...15)).map { "player_\($0)" },
                leaderID: "leader_\(index)",
                createdAt: Date().addingTimeInterval(TimeInterval(-index * 86400 * 7))
            )
        }
    }
}
