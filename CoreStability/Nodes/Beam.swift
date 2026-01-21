// Beam.swift
// CoreStability
// Energy beam - SIMPLE: Shoots towards touch point, updates in real-time

import SpriteKit

final class Beam: SKNode {
    
    let beamId: Int
    let polarity: Int
    let stateMachine: StateMachine<BeamState>
    
    private(set) var currentLength: CGFloat = 0
    private(set) var targetLength: CGFloat = 0
    
    /// Direction can be updated while extending
    var direction: CGVector = .zero {
        didSet { updateVisuals() }
    }
    
    weak var connectedNode: EnergyNode?
    
    private let beamLine: SKShapeNode
    private let glowLine: SKShapeNode
    private let tipGlow: SKShapeNode
    private let beamColor: SKColor
    
    init(id: Int, polarity: Int) {
        self.beamId = id
        self.polarity = polarity
        self.stateMachine = StateMachine(initialState: .inactive)
        
        beamColor = polarity > 0 ? GameConstants.Beam.positiveColor : GameConstants.Beam.negativeColor
        
        beamLine = SKShapeNode()
        beamLine.strokeColor = beamColor
        beamLine.lineWidth = GameConstants.Beam.width
        beamLine.lineCap = .round
        
        glowLine = SKShapeNode()
        glowLine.strokeColor = beamColor.withAlphaComponent(0.3)
        glowLine.lineWidth = GameConstants.Beam.glowWidth
        glowLine.lineCap = .round
        glowLine.blendMode = .add
        
        tipGlow = SKShapeNode(circleOfRadius: 10)
        tipGlow.fillColor = beamColor
        tipGlow.strokeColor = .clear
        tipGlow.glowWidth = 8.0
        tipGlow.blendMode = .add
        
        super.init()
        
        addChild(glowLine)
        addChild(beamLine)
        addChild(tipGlow)
        
        // Pulse animation
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.4, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2)
        ])
        tipGlow.run(SKAction.repeatForever(pulse))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Update
    
    func update(deltaTime: TimeInterval) {
        switch stateMachine.currentState {
        case .extending:
            let ext = GameConstants.Beam.extensionSpeed * CGFloat(deltaTime)
            currentLength = min(currentLength + ext, targetLength)
            if currentLength >= GameConstants.Beam.maxLength {
                stateMachine.transition(to: .retracting)
            }
            
        case .retracting:
            let ret = GameConstants.Beam.extensionSpeed * 2.0 * CGFloat(deltaTime)
            currentLength = max(0, currentLength - ret)
            if currentLength <= 0 {
                stateMachine.transition(to: .inactive)
            }
            
        case .stabilizing:
            let intensity = 0.7 + 0.3 * sin(stateMachine.timeInCurrentState * 8)
            beamLine.alpha = CGFloat(intensity)
            
        default:
            break
        }
        
        updateVisuals()
    }
    
    private func updateVisuals() {
        let endPoint = CGPoint(x: direction.dx * currentLength, y: direction.dy * currentLength)
        
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: endPoint)
        
        beamLine.path = path
        glowLine.path = path
        tipGlow.position = endPoint
        tipGlow.isHidden = currentLength < 10
    }
    
    // MARK: - Control
    
    func startExtending(towards target: CGPoint, from origin: CGPoint) {
        guard stateMachine.transition(to: .extending) else { return }
        
        self.position = origin
        
        let dx = target.x - origin.x
        let dy = target.y - origin.y
        let dist = sqrt(dx * dx + dy * dy)
        
        if dist > 0 {
            direction = CGVector(dx: dx / dist, dy: dy / dist)
        }
        
        targetLength = GameConstants.Beam.maxLength
        currentLength = 0
    }
    
    /// Update direction while extending (follow finger)
    func updateTarget(_ target: CGPoint, from origin: CGPoint) {
        guard stateMachine.currentState == .extending else { return }
        
        let dx = target.x - origin.x
        let dy = target.y - origin.y
        let dist = sqrt(dx * dx + dy * dy)
        
        if dist > 10 {
            direction = CGVector(dx: dx / dist, dy: dy / dist)
        }
    }
    
    func startRetracting() {
        if stateMachine.currentState == .extending {
            stateMachine.transition(to: .retracting)
        }
        connectedNode?.interruptStabilization()
        connectedNode = nil
    }
    
    func lockToNode(_ node: EnergyNode, from origin: CGPoint) {
        guard stateMachine.transition(to: .locked) else { return }
        connectedNode = node
        
        let dx = node.position.x - origin.x
        let dy = node.position.y - origin.y
        currentLength = sqrt(dx * dx + dy * dy)
        direction = CGVector(dx: dx / currentLength, dy: dy / currentLength)
        
        // Flash effect
        let flash = SKAction.sequence([
            SKAction.run { [weak self] in self?.beamLine.strokeColor = .white },
            SKAction.wait(forDuration: 0.1),
            SKAction.run { [weak self] in self?.beamLine.strokeColor = self?.beamColor ?? .green }
        ])
        run(flash)
        
        updateVisuals()
    }
    
    func startStabilizing() {
        stateMachine.transition(to: .stabilizing)
    }
    
    func getTipPosition() -> CGPoint {
        return CGPoint(
            x: position.x + direction.dx * currentLength,
            y: position.y + direction.dy * currentLength
        )
    }
    
    var isActive: Bool { stateMachine.currentState != .inactive }
    var isLocked: Bool { stateMachine.currentState == .locked || stateMachine.currentState == .stabilizing }
    var isExtending: Bool { stateMachine.currentState == .extending }
    
    func fadeOut(completion: @escaping () -> Void) {
        run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.run(completion)
        ]))
    }
}
