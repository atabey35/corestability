// DeathSequenceController.swift
// CoreStability
// Handles death animation and reset

import SpriteKit
import QuartzCore

protocol DeathSequenceDelegate: AnyObject {
    func deathSequenceDidComplete(_ controller: DeathSequenceController)
    func deathSequenceRequestsBeamRetraction(_ controller: DeathSequenceController)
    func deathSequenceRequestsNodeImplosion(_ controller: DeathSequenceController, toPoint center: CGPoint)
}

final class DeathSequenceController {
    
    weak var delegate: DeathSequenceDelegate?
    weak var parentNode: SKNode?
    
    private(set) var isActive: Bool = false
    
    private var sequenceStartTime: TimeInterval = 0
    private var currentPhase: Int = 0
    private var corePosition: CGPoint = .zero
    
    private let phaseDurations: [TimeInterval] = [0.3, 0.5, 1.5, 0.5]
    
    func trigger(corePosition: CGPoint) {
        isActive = true
        sequenceStartTime = CACurrentMediaTime()
        currentPhase = 0
        self.corePosition = corePosition
        
        executePhase(0)
    }
    
    func update(deltaTime: TimeInterval) {
        guard isActive else { return }
        
        let elapsed = CACurrentMediaTime() - sequenceStartTime
        
        var totalPhaseTime: TimeInterval = 0
        for (index, duration) in phaseDurations.enumerated() {
            totalPhaseTime += duration
            
            if elapsed < totalPhaseTime && currentPhase < index {
                currentPhase = index
                executePhase(index)
                break
            }
        }
        
        let totalDuration = phaseDurations.reduce(0, +)
        if elapsed >= totalDuration {
            complete()
        }
    }
    
    private func executePhase(_ phase: Int) {
        switch phase {
        case 0:
            delegate?.deathSequenceRequestsBeamRetraction(self)
        case 1:
            delegate?.deathSequenceRequestsNodeImplosion(self, toPoint: corePosition)
        case 2:
            // Core collapse (handled externally)
            break
        case 3:
            // Fade
            break
        default:
            break
        }
    }
    
    private func complete() {
        isActive = false
        currentPhase = 0
        delegate?.deathSequenceDidComplete(self)
    }
    
    func createNodeImplosionEffect(from position: CGPoint, to center: CGPoint) {
        guard let parent = parentNode else { return }
        
        let particle = SKShapeNode(circleOfRadius: 5)
        particle.position = position
        particle.fillColor = .white
        particle.strokeColor = .clear
        particle.glowWidth = 3.0
        particle.blendMode = .add
        parent.addChild(particle)
        
        let moveToCenter = SKAction.move(to: center, duration: 0.5)
        moveToCenter.timingMode = .easeIn
        
        particle.run(SKAction.sequence([
            moveToCenter,
            SKAction.fadeOut(withDuration: 0.1),
            SKAction.removeFromParent()
        ]))
    }
    
    func reset() {
        isActive = false
        currentPhase = 0
    }
}
