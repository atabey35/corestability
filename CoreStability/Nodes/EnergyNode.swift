// EnergyNode.swift
// CoreStability
// Base class for all energy nodes

import SpriteKit

protocol EnergyNodeDelegate: AnyObject {
    func energyNodeDidExplode(_ node: EnergyNode)
    func energyNodeDidStabilize(_ node: EnergyNode)
    func energyNodeStabilityChanged(_ node: EnergyNode)
}

class EnergyNode: SKNode {
    
    enum NodeType: Hashable {
        case normal, volatile, phase, fake
    }
    
    // MARK: - Properties
    
    let nodeId: Int
    let nodeType: NodeType
    let polarity: Int  // 1 = positive, -1 = negative
    
    weak var delegate: EnergyNodeDelegate?
    
    private(set) var stability: Float
    private(set) var isStabilizing: Bool = false
    private(set) var hasExploded: Bool = false
    
    var decayRate: Float = GameConstants.Node.baseDecayRate
    
    // Visual
    let mainShape: SKShapeNode
    let glowShape: SKShapeNode
    let pulseRing: SKShapeNode
    
    var baseColor: SKColor {
        return polarity > 0 ? GameConstants.Node.positiveColor : GameConstants.Node.negativeColor
    }
    
    // MARK: - Initialization
    
    init(id: Int, type: NodeType, polarity: Int) {
        self.nodeId = id
        self.nodeType = type
        self.polarity = polarity
        self.stability = GameConstants.Node.initialStability
        
        // Main shape
        mainShape = SKShapeNode(circleOfRadius: GameConstants.Node.radius)
        mainShape.lineWidth = 2.0
        
        // Glow
        glowShape = SKShapeNode(circleOfRadius: GameConstants.Node.glowRadius)
        glowShape.fillColor = .clear
        glowShape.strokeColor = .clear
        glowShape.glowWidth = 15.0
        glowShape.blendMode = .add
        
        // Pulse ring
        pulseRing = SKShapeNode(circleOfRadius: GameConstants.Node.radius + 5)
        pulseRing.fillColor = .clear
        pulseRing.lineWidth = 2.0
        pulseRing.alpha = 0
        
        super.init()
        
        let nodeColor = baseColor
        mainShape.fillColor = nodeColor.withAlphaComponent(0.3)
        mainShape.strokeColor = nodeColor
        glowShape.strokeColor = nodeColor.withAlphaComponent(0.3)
        pulseRing.strokeColor = nodeColor
        
        addChild(glowShape)
        addChild(mainShape)
        addChild(pulseRing)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Update
    
    func update(deltaTime: TimeInterval, chaosMultiplier: Float) {
        guard !hasExploded else { return }
        
        if !isStabilizing {
            // PASSIVE DECAY: System destabilizes over time
            // PSYCHOLOGY: This answers "why hurry?"
            let decay = decayRate * chaosMultiplier * Float(deltaTime)
            stability -= decay
            
            updateVisualState()
            delegate?.energyNodeStabilityChanged(self)
        }
        
        if stability <= 0 {
            explode()
        }
    }
    
    func updateVisualState() {
        let stabilityRatio = CGFloat(stability / GameConstants.Node.maxStability)
        
        if stability < GameConstants.Node.criticalStability {
            mainShape.strokeColor = GameConstants.Node.unstableColor
            let flash = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.5, duration: 0.1),
                SKAction.fadeAlpha(to: 1.0, duration: 0.1)
            ])
            mainShape.run(flash)
        } else {
            mainShape.strokeColor = baseColor
        }
        
        mainShape.fillColor = baseColor.withAlphaComponent(0.2 + stabilityRatio * 0.4)
    }
    
    // MARK: - Stabilization
    
    func startStabilizing() {
        isStabilizing = true
    }
    
    func applyStabilization(amount: Float) {
        guard isStabilizing && !hasExploded else { return }
        stability = min(GameConstants.Node.maxStability, stability + amount)
        
        if stability >= GameConstants.Node.maxStability {
            completeStabilization()
        }
    }
    
    func interruptStabilization() {
        isStabilizing = false
    }
    
    func completeStabilization() {
        isStabilizing = false
        delegate?.energyNodeDidStabilize(self)
        
        // Victory effect
        let flash = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.3, duration: 0.2),
                SKAction.fadeAlpha(to: 0.0, duration: 0.3)
            ]),
            SKAction.removeFromParent()
        ])
        run(flash)
    }
    
    // MARK: - Explosion
    
    func explode() {
        guard !hasExploded else { return }
        hasExploded = true
        
        delegate?.energyNodeDidExplode(self)
        
        let explosion = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.0, duration: 0.15),
                SKAction.fadeOut(withDuration: 0.15)
            ]),
            SKAction.removeFromParent()
        ])
        run(explosion)
    }
    
    // MARK: - Polarity Check
    
    func matchesPolarity(_ beamPolarity: Int) -> Bool {
        return polarity == beamPolarity
    }
}
