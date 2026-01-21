// VolatileNode.swift
// CoreStability

import SpriteKit

final class VolatileNode: EnergyNode {
    init(id: Int, polarity: Int) {
        super.init(id: id, type: .volatile, polarity: polarity)
        decayRate = GameConstants.Node.baseDecayRate * GameConstants.VolatileNode.decayMultiplier
        
        mainShape.strokeColor = .red
        mainShape.fillColor = SKColor.red.withAlphaComponent(0.3)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
