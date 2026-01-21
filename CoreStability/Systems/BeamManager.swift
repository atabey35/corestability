// BeamManager.swift
// CoreStability
// SIMPLIFIED: Touch = shoot towards that point
// No rotation needed - core points automatically

import SpriteKit

protocol BeamManagerDelegate: AnyObject {
    func beamManager(_ manager: BeamManager, didLockBeam beam: Beam, toNode node: EnergyNode)
    func beamManager(_ manager: BeamManager, beamCausedExplosion beam: Beam, node: EnergyNode)
    func beamManager(_ manager: BeamManager, didStabilizeNode node: EnergyNode, withBeam beam: Beam)
}

final class BeamManager {
    
    weak var delegate: BeamManagerDelegate?
    weak var parentNode: SKNode?
    
    private(set) var activeBeam: Beam?
    private(set) var lockedBeams: [Beam] = []
    
    private var nextBeamId: Int = 0
    private(set) var currentPolarity: Int = 1
    
    var isInputEnabled: Bool = true
    
    // MARK: - Core Reference
    
    var coreNode: CoreNode?
    
    // MARK: - DIRECT TOUCH BEAM
    
    /// Touch somewhere = shoot beam towards that point
    func shootTowards(_ touchPoint: CGPoint) {
        guard isInputEnabled, activeBeam == nil, let core = coreNode, let parent = parentNode else { return }
        
        // Origin is core center
        let origin = core.position
        
        // Calculate direction
        let dx = touchPoint.x - origin.x
        let dy = touchPoint.y - origin.y
        let distance = sqrt(dx * dx + dy * dy)
        
        // Ignore taps on core itself
        guard distance > GameConstants.Core.radius else { return }
        
        // Point core towards target
        let angle = atan2(dy, dx)
        core.setRotation(angle)
        
        // Create beam
        let beam = Beam(id: nextBeamId, polarity: currentPolarity)
        nextBeamId += 1
        
        // Start from core edge
        let edgeOffset = GameConstants.Core.radius + 5
        let beamOrigin = CGPoint(
            x: origin.x + (dx / distance) * edgeOffset,
            y: origin.y + (dy / distance) * edgeOffset
        )
        
        beam.startExtending(towards: touchPoint, from: beamOrigin)
        parent.addChild(beam)
        activeBeam = beam
    }
    
    /// Follow finger while beam is extending
    func updateTarget(_ touchPoint: CGPoint) {
        guard let beam = activeBeam, let core = coreNode, beam.isExtending else { return }
        
        let origin = core.position
        let dx = touchPoint.x - origin.x
        let dy = touchPoint.y - origin.y
        let distance = sqrt(dx * dx + dy * dy)
        
        guard distance > GameConstants.Core.radius else { return }
        
        // Point core towards new target
        let angle = atan2(dy, dx)
        core.setRotation(angle)
        
        // Update beam direction
        let edgeOffset = GameConstants.Core.radius + 5
        let beamOrigin = CGPoint(
            x: origin.x + (dx / distance) * edgeOffset,
            y: origin.y + (dy / distance) * edgeOffset
        )
        
        beam.position = beamOrigin
        beam.updateTarget(touchPoint, from: beamOrigin)
    }
    
    /// Release touch = end beam
    func endBeam() {
        guard let beam = activeBeam else { return }
        
        if beam.isLocked {
            lockedBeams.append(beam)
            beam.startStabilizing()
        } else {
            beam.startRetracting()
        }
        
        activeBeam = nil
    }
    
    // MARK: - Update
    
    func update(deltaTime: TimeInterval, nodes: [EnergyNode]) {
        // Update active beam
        if let beam = activeBeam {
            beam.update(deltaTime: deltaTime)
            checkBeamNodeIntersection(beam, nodes: nodes)
        }
        
        // Update locked beams
        for beam in lockedBeams where beam.isActive {
            beam.update(deltaTime: deltaTime)
            
            if let node = beam.connectedNode, !node.hasExploded {
                let amount = GameConstants.Beam.stabilizationRate * Float(deltaTime)
                node.applyStabilization(amount: amount)
                
                if node.stability >= GameConstants.Node.maxStability {
                    delegate?.beamManager(self, didStabilizeNode: node, withBeam: beam)
                    beam.fadeOut { [weak beam] in beam?.removeFromParent() }
                }
            }
        }
        
        // Clean up
        lockedBeams.removeAll { !$0.isActive }
    }
    
    private func checkBeamNodeIntersection(_ beam: Beam, nodes: [EnergyNode]) {
        guard beam.isExtending, let core = coreNode else { return }
        
        let tipPos = beam.getTipPosition()
        
        for node in nodes where !node.hasExploded && !node.isStabilizing {
            let dx = tipPos.x - node.position.x
            let dy = tipPos.y - node.position.y
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance < GameConstants.Beam.lockDistance {
                // Check polarity
                if node.matchesPolarity(beam.polarity) {
                    // CORRECT: Lock and stabilize
                    beam.lockToNode(node, from: core.position)
                    node.startStabilizing()
                    delegate?.beamManager(self, didLockBeam: beam, toNode: node)
                } else {
                    // WRONG: Explosion
                    delegate?.beamManager(self, beamCausedExplosion: beam, node: node)
                }
                break
            }
        }
    }
    
    // MARK: - Polarity
    
    func togglePolarity() {
        currentPolarity = -currentPolarity
    }
    
    // MARK: - Reset
    
    func reset() {
        activeBeam?.removeFromParent()
        activeBeam = nil
        
        for beam in lockedBeams {
            beam.removeFromParent()
        }
        lockedBeams.removeAll()
        
        nextBeamId = 0
        currentPolarity = 1
        isInputEnabled = true
    }
    
    func removeAllBeams() {
        activeBeam?.removeFromParent()
        activeBeam = nil
        
        for beam in lockedBeams {
            beam.removeFromParent()
        }
        lockedBeams.removeAll()
    }
    
    func disableInput() {
        isInputEnabled = false
    }
}
