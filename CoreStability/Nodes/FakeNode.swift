// FakeNode.swift
// CoreStability

import SpriteKit

final class FakeNode: EnergyNode {
    init(id: Int, polarity: Int) {
        super.init(id: id, type: .fake, polarity: polarity)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func matchesPolarity(_ beamPolarity: Int) -> Bool {
        return false  // Fake nodes never match
    }
    
    override func explode() {
        // Fake nodes just disappear without damage
        let fade = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ])
        run(fade)
    }
}
