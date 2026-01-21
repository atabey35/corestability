// ParticleEffects.swift
// CoreStability
// Particle effects for explosions and stabilization

import SpriteKit

enum ParticleEffects {
    
    static func createExplosionEmitter(color: SKColor) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        
        emitter.particleBirthRate = 100
        emitter.numParticlesToEmit = 30
        emitter.particleLifetime = 0.5
        emitter.particleLifetimeRange = 0.2
        
        emitter.particleSpeed = 150
        emitter.particleSpeedRange = 50
        emitter.emissionAngleRange = .pi * 2
        
        emitter.particleScale = 0.3
        emitter.particleScaleRange = 0.2
        emitter.particleScaleSpeed = -0.4
        
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -2.0
        
        emitter.particleColor = color
        emitter.particleBlendMode = .add
        
        emitter.targetNode = nil
        
        return emitter
    }
    
    static func createStabilizationEmitter(color: SKColor) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        
        emitter.particleBirthRate = 50
        emitter.numParticlesToEmit = 20
        emitter.particleLifetime = 0.8
        
        emitter.particleSpeed = 80
        emitter.particleSpeedRange = 30
        emitter.emissionAngleRange = .pi * 2
        
        emitter.particleScale = 0.2
        emitter.particleScaleSpeed = -0.2
        
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -1.0
        
        emitter.particleColor = color
        emitter.particleBlendMode = .add
        
        return emitter
    }
    
    static func addTemporaryEmitter(_ emitter: SKEmitterNode, to parent: SKNode, at position: CGPoint) {
        emitter.position = position
        emitter.zPosition = 50
        parent.addChild(emitter)
        
        let lifetime = max(emitter.particleLifetime + emitter.particleLifetimeRange, 1.0)
        emitter.run(SKAction.sequence([
            SKAction.wait(forDuration: TimeInterval(lifetime)),
            SKAction.removeFromParent()
        ]))
    }
}
