// CoreNode.swift
// CoreStability
// Central rotating core that the player controls

import SpriteKit

final class CoreNode: SKNode {
    
    // MARK: - Visual Components
    
    private let coreShape: SKShapeNode
    private let glowShape: SKShapeNode
    private let innerRing: SKShapeNode
    private let pulseRing: SKShapeNode
    private let directionIndicator: SKShapeNode
    
    // PROGRESS ARC: Shows chapter completion
    // PSYCHOLOGY: Player sees this filling up = understands the goal
    private let progressArc: SKShapeNode
    private var progressRatio: CGFloat = 0.0
    
    // MARK: - State
    
    private(set) var load: Float = 0.0 {
        didSet { updateVisualState() }
    }
    
    private(set) var currentRotation: CGFloat = 0.0
    
    private let baseColor = GameConstants.Core.baseColor
    private let overloadColor = GameConstants.Core.overloadColor
    
    // MARK: - Initialization
    
    override init() {
        // Core shape
        coreShape = SKShapeNode(circleOfRadius: GameConstants.Core.radius)
        coreShape.fillColor = baseColor.withAlphaComponent(0.8)
        coreShape.strokeColor = baseColor
        coreShape.lineWidth = 3.0
        coreShape.glowWidth = 3.0
        
        // Glow
        glowShape = SKShapeNode(circleOfRadius: GameConstants.Core.glowRadius)
        glowShape.fillColor = baseColor.withAlphaComponent(0.15)
        glowShape.strokeColor = .clear
        glowShape.blendMode = .add
        
        // Inner ring
        innerRing = SKShapeNode(circleOfRadius: GameConstants.Core.radius * 0.6)
        innerRing.fillColor = .clear
        innerRing.strokeColor = baseColor.withAlphaComponent(0.5)
        innerRing.lineWidth = 1.5
        
        // Pulse ring
        pulseRing = SKShapeNode(circleOfRadius: GameConstants.Core.radius + 10)
        pulseRing.fillColor = .clear
        pulseRing.lineWidth = 2.0
        pulseRing.alpha = 0
        
        // Direction indicator
        let path = CGMutablePath()
        let offset = GameConstants.Core.radius + 8.0
        path.move(to: CGPoint(x: offset, y: 0))
        path.addLine(to: CGPoint(x: offset + 12, y: 6))
        path.addLine(to: CGPoint(x: offset + 12, y: -6))
        path.closeSubpath()
        
        directionIndicator = SKShapeNode(path: path)
        directionIndicator.fillColor = baseColor
        directionIndicator.strokeColor = .clear
        directionIndicator.glowWidth = 2.0
        
        // Progress arc - outer ring that fills clockwise
        progressArc = SKShapeNode()
        progressArc.strokeColor = GameConstants.Node.positiveColor
        progressArc.lineWidth = 4.0
        progressArc.lineCap = .round
        progressArc.glowWidth = 3.0
        progressArc.zPosition = 5
        
        super.init()
        
        addChild(glowShape)
        addChild(pulseRing)
        addChild(progressArc)  // Behind core
        addChild(coreShape)
        addChild(innerRing)
        addChild(directionIndicator)
        
        startIdleAnimation()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func startIdleAnimation() {
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 1.5),
            SKAction.scale(to: 1.0, duration: 1.5)
        ])
        glowShape.run(SKAction.repeatForever(pulse))
        
        let rotate = SKAction.rotate(byAngle: -.pi * 2, duration: 8.0)
        innerRing.run(SKAction.repeatForever(rotate))
    }
    
    // MARK: - Update
    
    func update(deltaTime: TimeInterval) {
        zRotation = currentRotation
        
        if load > 0 {
            let decay = GameConstants.Load.baseLoadDecay * Float(deltaTime)
            load = max(0, load - decay)
        }
    }
    
    func setRotation(_ angle: CGFloat) {
        currentRotation = angle
    }
    
    // MARK: - Progress (Chapter Completion)
    
    /// Update progress arc to show chapter completion
    /// PSYCHOLOGY: Player SEES this filling = understands the goal
    func updateProgress(_ progress: Float) {
        let newRatio = CGFloat(min(1.0, max(0.0, progress)))
        
        // Animate smoothly to new progress
        progressRatio = progressRatio + (newRatio - progressRatio) * 0.1
        
        // Create arc path from top, clockwise
        let radius = GameConstants.Core.radius + 20.0
        let startAngle: CGFloat = -.pi / 2  // Top
        let endAngle = startAngle + (.pi * 2 * progressRatio)
        
        let arcPath = CGMutablePath()
        arcPath.addArc(center: .zero, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        
        progressArc.path = arcPath
        
        // Brighten as we get close to completion
        if progressRatio > 0.8 {
            progressArc.strokeColor = SKColor.white
            progressArc.glowWidth = 6.0
        } else {
            progressArc.strokeColor = GameConstants.Node.positiveColor
            progressArc.glowWidth = 3.0
        }
    }
    
    /// Reset progress arc for new chapter
    func resetProgress() {
        progressRatio = 0.0
        progressArc.path = nil
    }
    
    // MARK: - Load
    
    func addLoad(_ amount: Float) {
        load = min(GameConstants.Load.maxLoad, load + amount)
        
        if load >= GameConstants.Load.criticalThreshold {
            triggerCriticalPulse()
        } else if load >= GameConstants.Load.warningThreshold {
            triggerWarningPulse()
        }
    }
    
    func reduceLoad(_ amount: Float) {
        load = max(0, load - amount)
        triggerCalmPulse()
    }
    
    func isOverloaded() -> Bool { load >= GameConstants.Load.maxLoad }
    func isInWarningState() -> Bool { load >= GameConstants.Load.warningThreshold }
    func isInCriticalState() -> Bool { load >= GameConstants.Load.criticalThreshold }
    
    // MARK: - Beam Origin
    
    func getBeamOrigin() -> CGPoint {
        let offset = GameConstants.Core.radius + 10.0
        return CGPoint(
            x: position.x + cos(currentRotation) * offset,
            y: position.y + sin(currentRotation) * offset
        )
    }
    
    func getBeamDirection() -> CGVector {
        return CGVector(dx: cos(currentRotation), dy: sin(currentRotation))
    }
    
    // MARK: - Visual State
    
    private func updateVisualState() {
        let loadRatio = CGFloat(load / GameConstants.Load.maxLoad)
        let color = interpolateColor(from: baseColor, to: overloadColor, ratio: loadRatio)
        
        coreShape.fillColor = color.withAlphaComponent(0.8)
        coreShape.strokeColor = color
        glowShape.fillColor = color.withAlphaComponent(0.15 + loadRatio * 0.2)
        innerRing.strokeColor = color.withAlphaComponent(0.5)
        directionIndicator.fillColor = color
        
        coreShape.glowWidth = 3.0 + loadRatio * 8.0
    }
    
    private func interpolateColor(from: SKColor, to: SKColor, ratio: CGFloat) -> SKColor {
        var fromR: CGFloat = 0, fromG: CGFloat = 0, fromB: CGFloat = 0, fromA: CGFloat = 0
        var toR: CGFloat = 0, toG: CGFloat = 0, toB: CGFloat = 0, toA: CGFloat = 0
        from.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
        to.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)
        let r = max(0, min(1, ratio))
        return SKColor(red: fromR + (toR - fromR) * r, green: fromG + (toG - fromG) * r,
                       blue: fromB + (toB - fromB) * r, alpha: fromA + (toA - fromA) * r)
    }
    
    // MARK: - Pulses
    
    private func triggerWarningPulse() {
        pulseRing.removeAllActions()
        pulseRing.setScale(1.0)
        pulseRing.alpha = 0.8
        pulseRing.strokeColor = .orange
        pulseRing.run(SKAction.group([
            SKAction.scale(to: 2.0, duration: 0.4),
            SKAction.fadeOut(withDuration: 0.4)
        ]))
    }
    
    private func triggerCriticalPulse() {
        pulseRing.removeAllActions()
        pulseRing.setScale(1.0)
        pulseRing.alpha = 1.0
        pulseRing.strokeColor = overloadColor
        pulseRing.run(SKAction.group([
            SKAction.scale(to: 2.5, duration: 0.3),
            SKAction.fadeOut(withDuration: 0.3)
        ]))
    }
    
    private func triggerCalmPulse() {
        pulseRing.removeAllActions()
        pulseRing.setScale(1.0)
        pulseRing.alpha = 0.6
        pulseRing.strokeColor = GameConstants.Node.positiveColor
        pulseRing.run(SKAction.group([
            SKAction.scale(to: 1.8, duration: 0.5),
            SKAction.fadeOut(withDuration: 0.5)
        ]))
    }
    
    // MARK: - Collapse
    
    func triggerCollapse(completion: @escaping () -> Void) {
        removeAllActions()
        glowShape.removeAllActions()
        innerRing.removeAllActions()
        
        let shake = SKAction.sequence([
            SKAction.moveBy(x: 5, y: 0, duration: 0.02),
            SKAction.moveBy(x: -10, y: 0, duration: 0.02),
            SKAction.moveBy(x: 10, y: 0, duration: 0.02),
            SKAction.moveBy(x: -5, y: 0, duration: 0.02)
        ])
        
        let shrink = SKAction.scale(to: 0.0, duration: 1.5)
        shrink.timingMode = .easeIn
        
        run(SKAction.sequence([
            SKAction.repeat(shake, count: 20),
            shrink,
            SKAction.run(completion)
        ]))
    }
}
