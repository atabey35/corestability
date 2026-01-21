// GameConstants.swift
// CoreStability
// Centralized constants for tunable gameplay

import CoreGraphics
import SpriteKit

enum GameConstants {
    
    // MARK: - Core Settings
    enum Core {
        static let radius: CGFloat = 40.0
        static let glowRadius: CGFloat = 60.0
        static let baseColor = SKColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        static let overloadColor = SKColor(red: 1.0, green: 0.2, blue: 0.1, alpha: 1.0)
    }
    
    // MARK: - Load System
    enum Load {
        static let warningThreshold: Float = 70.0
        static let criticalThreshold: Float = 85.0
        static let maxLoad: Float = 100.0
        static let loadPerUnstableNode: Float = 2.0
        static let loadDecayOnStabilize: Float = 15.0
        static let baseLoadDecay: Float = 0.5
    }
    
    // MARK: - Beam
    enum Beam {
        static let width: CGFloat = 3.0
        static let glowWidth: CGFloat = 12.0
        static let extensionSpeed: CGFloat = 800.0
        static let maxLength: CGFloat = 500.0
        static let positiveColor = SKColor(red: 0.2, green: 1.0, blue: 0.4, alpha: 1.0)
        static let negativeColor = SKColor(red: 1.0, green: 0.3, blue: 0.8, alpha: 1.0)
        static let lockDistance: CGFloat = 30.0
        static let stabilizationRate: Float = 25.0
    }
    
    // MARK: - Node
    enum Node {
        static let radius: CGFloat = 25.0
        static let glowRadius: CGFloat = 40.0
        static let minSpawnDistance: CGFloat = 150.0
        static let maxSpawnDistance: CGFloat = 280.0
        static let baseDecayRate: Float = 3.0
        static let initialStability: Float = 80.0
        static let maxStability: Float = 100.0
        static let criticalStability: Float = 30.0
        static let positiveColor = SKColor(red: 0.2, green: 1.0, blue: 0.4, alpha: 1.0)
        static let negativeColor = SKColor(red: 1.0, green: 0.3, blue: 0.8, alpha: 1.0)
        static let unstableColor = SKColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
    }
    
    // MARK: - Volatile Node
    enum VolatileNode {
        static let explosionRadius: CGFloat = 120.0
        static let chainReactionDelay: TimeInterval = 0.15
        static let decayMultiplier: Float = 1.5
    }
    
    // MARK: - Phase Node
    enum PhaseNode {
        static let phaseInterval: TimeInterval = 3.0
        static let warningDuration: TimeInterval = 0.5
    }
    
    // MARK: - Chaos
    enum Chaos {
        static let maxChaos: Float = 100.0
        static let explosionIncrease: Float = 15.0
        static let rapidActionIncrease: Float = 5.0
        static let unstableNodeIncrease: Float = 0.5
        static let naturalDecay: Float = 1.0
        static let passiveIncrease: Float = 0.3  // Per second
        static let decayRateMultiplierMax: Float = 3.0
        static let precisionLossMax: Float = 0.3
    }
    
    // MARK: - Difficulty
    enum Difficulty {
        static let baseSpawnInterval: TimeInterval = 4.0
        static let minSpawnInterval: TimeInterval = 1.5
        static let spawnAcceleration: Float = 0.02
        static let volatileChance: Float = 0.15
        static let phaseChance: Float = 0.10
        static let fakeChance: Float = 0.08
    }
    
    // MARK: - Visual
    enum Visual {
        static let screenShakeIntensity: CGFloat = 8.0
        static let screenShakeDuration: TimeInterval = 0.3
        static let pulseFrequency: TimeInterval = 1.5
        static let collapseAnimationDuration: TimeInterval = 1.5
    }
    
    // MARK: - Game Over
    enum GameOver {
        static let simultaneousExplosionLimit: Int = 3
        static let explosionWindowDuration: TimeInterval = 0.5
    }
    
    // MARK: - Performance
    enum Performance {
        static let maxActiveNodes: Int = 8
    }
}
