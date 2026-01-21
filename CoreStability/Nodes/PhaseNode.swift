// PhaseNode.swift
// CoreStability

import SpriteKit

final class PhaseNode: EnergyNode {
    private var phaseTimer: TimeInterval = 0
    private var isPhasing: Bool = false
    
    init(id: Int, polarity: Int) {
        super.init(id: id, type: .phase, polarity: polarity)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update(deltaTime: TimeInterval, chaosMultiplier: Float) {
        phaseTimer += deltaTime
        
        if phaseTimer >= GameConstants.PhaseNode.phaseInterval {
            phaseTimer = 0
            togglePhase()
        }
        
        super.update(deltaTime: deltaTime, chaosMultiplier: chaosMultiplier)
    }
    
    private func togglePhase() {
        isPhasing = !isPhasing
        alpha = isPhasing ? 0.3 : 1.0
    }
    
    override func matchesPolarity(_ beamPolarity: Int) -> Bool {
        if isPhasing { return false }
        return super.matchesPolarity(beamPolarity)
    }
}
