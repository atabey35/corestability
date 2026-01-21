// ChaosSystem.swift
// CoreStability
// Hidden chaos affecting game difficulty
// REDESIGNED: Passive increase + decay from stabilization
// PSYCHOLOGY: Answers "why hurry?" and "why be careful?"

import Foundation
import QuartzCore

/// Manages the chaos system
/// WHY HURRY: System destabilizes passively over time
/// WHY CAREFUL: Panic actions amplify chaos
/// WHY IMPROVE: Correct stabilization is the only way to reduce chaos
final class ChaosSystem {
    
    // MARK: - Properties
    
    var chaosCap: Float = GameConstants.Chaos.maxChaos
    
    private(set) var chaosLevel: Float = 0.0 {
        didSet {
            chaosLevel = max(0, min(chaosCap, chaosLevel))
        }
    }
    
    // Smoothed for visual feedback
    private var displayChaos: Float = 0.0
    
    // Tracking panic (rapid wrong actions)
    private var recentWrongActions: Int = 0
    private var wrongActionTimer: TimeInterval = 0
    private let wrongActionWindow: TimeInterval = 3.0
    
    // MARK: - Computed Properties
    
    var smoothedChaos: Float { displayChaos }
    
    /// Multiplier for node decay (higher chaos = faster node decay)
    var decayRateMultiplier: Float {
        let normalized = displayChaos / GameConstants.Chaos.maxChaos
        return 1.0 + normalized * (GameConstants.Chaos.decayRateMultiplierMax - 1.0)
    }
    
    var isCritical: Bool { chaosLevel > chaosCap * 0.7 }
    
    // MARK: - Update
    
    func update(deltaTime: TimeInterval, unstableNodeCount: Int) {
        let dt = Float(deltaTime)
        
        // PASSIVE INCREASE: Chaos grows over time no matter what
        // PSYCHOLOGY: This creates urgency - you can't just wait
        let passiveIncrease = GameConstants.Chaos.passiveIncrease * dt
        chaosLevel += passiveIncrease
        
        // Additional chaos from unstable nodes
        let unstableIncrease = GameConstants.Chaos.unstableNodeIncrease * Float(unstableNodeCount) * dt
        chaosLevel += unstableIncrease
        
        // Panic amplification
        if recentWrongActions > 2 {
            chaosLevel += Float(recentWrongActions - 2) * 0.5 * dt
        }
        
        // Wrong action timer decay
        wrongActionTimer += deltaTime
        if wrongActionTimer > wrongActionWindow {
            recentWrongActions = max(0, recentWrongActions - 1)
            wrongActionTimer = 0
        }
        
        // Smooth display value
        displayChaos += (chaosLevel - displayChaos) * 0.05
    }
    
    // MARK: - Events
    
    /// Called on explosion - chaos spikes
    func onExplosion() {
        chaosLevel += GameConstants.Chaos.explosionIncrease
        recentWrongActions += 1
        wrongActionTimer = 0
    }
    
    /// Called on CORRECT stabilization - chaos DECAYS
    /// PSYCHOLOGY: This is the ONLY way to reduce chaos
    func onStabilization() {
        // Significant chaos reduction - reward for correct action
        chaosLevel -= GameConstants.Chaos.explosionIncrease * 0.8
        recentWrongActions = max(0, recentWrongActions - 1)
    }
    
    /// Called on wrong polarity attempt (near miss)
    func onWrongAction() {
        chaosLevel += GameConstants.Chaos.rapidActionIncrease
        recentWrongActions += 1
        wrongActionTimer = 0
    }
    
    // MARK: - Reset
    
    func reset() {
        chaosLevel = 0
        displayChaos = 0
        recentWrongActions = 0
        wrongActionTimer = 0
    }
    
    func configureForChapter(decayModifier: Float) {
        // Chapter modifies how quickly chaos recovers (if it can)
    }
}
