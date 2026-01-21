// WaveModifier.swift
// CoreStability
// Random modifiers that change wave characteristics

import Foundation

enum WaveModifier: String, CaseIterable {
    case normal = "NORMAL"
    case swarm = "SWARM"       // 2x enemies, 0.5x HP
    case tank = "TANK"         // 0.5x enemies, 2x HP
    case speed = "SPEED"       // 1.5x speed, +50% coins
    case armored = "ARMORED"   // Enemies have +5 defense
    case elite = "ELITE"       // All enemies are stronger variants
    
    var emoji: String {
        switch self {
        case .normal: return "📦"
        case .swarm: return "🐜"
        case .tank: return "🦣"
        case .speed: return "⚡"
        case .armored: return "🔒"
        case .elite: return "💀"
        }
    }
    
    var color: String {
        switch self {
        case .normal: return "white"
        case .swarm: return "yellow"
        case .tank: return "blue"
        case .speed: return "orange"
        case .armored: return "gray"
        case .elite: return "purple"
        }
    }
    
    // Multipliers
    var enemyCountMultiplier: Float {
        switch self {
        case .swarm: return 2.0
        case .tank: return 0.5
        case .elite: return 0.7
        default: return 1.0
        }
    }
    
    var enemyHPMultiplier: Float {
        switch self {
        case .swarm: return 0.5
        case .tank: return 2.0
        case .elite: return 1.5
        default: return 1.0
        }
    }
    
    var enemySpeedMultiplier: Float {
        switch self {
        case .speed: return 1.5
        default: return 1.0
        }
    }
    
    var coinMultiplier: Float {
        switch self {
        case .speed: return 1.5
        case .elite: return 2.0
        default: return 1.0
        }
    }
    
    var armorBonus: Float {
        switch self {
        case .armored: return 5.0
        default: return 0.0
        }
    }
    
    // Roll random modifier (weighted)
    static func random(forWave wave: Int) -> WaveModifier {
        // Normal is more common early, special modifiers appear later
        if wave < 5 { return .normal }
        
        let roll = Int.random(in: 1...100)
        
        if wave >= 20 && roll <= 10 { return .elite }
        if roll <= 25 { return .swarm }
        if roll <= 45 { return .tank }
        if roll <= 60 { return .speed }
        if roll <= 75 { return .armored }
        return .normal
    }
}
