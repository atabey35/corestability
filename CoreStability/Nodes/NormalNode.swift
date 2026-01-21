// NormalNode.swift
// CoreStability

import SpriteKit

final class NormalNode: EnergyNode {
    init(id: Int, polarity: Int) {
        super.init(id: id, type: .normal, polarity: polarity)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
