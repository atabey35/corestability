// VisualFeedbackSystem.swift
// CoreStability
// Visual effects for game state

import SpriteKit

final class VisualFeedbackSystem {
    
    weak var parentNode: SKNode?
    
    private var vignetteNode: SKShapeNode?
    
    func setupVignette(size: CGSize) {
        guard let parent = parentNode else { return }
        
        vignetteNode = SKShapeNode(rectOf: size)
        vignetteNode?.fillColor = .clear
        vignetteNode?.strokeColor = .clear
        vignetteNode?.zPosition = 50  // Lower than UI elements (100+)
        vignetteNode?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        vignetteNode?.isUserInteractionEnabled = false  // Don't block touches
        
        if let vignette = vignetteNode {
            parent.addChild(vignette)
        }
    }
    
    func updateVignetteForLoad(_ load: Float) {
        guard let vignette = vignetteNode else { return }
        
        let loadRatio = CGFloat(load / 100.0)  // Max load value
        
        if loadRatio > 0.7 {
            vignette.fillColor = SKColor.red.withAlphaComponent(loadRatio * 0.15)
        } else {
            vignette.fillColor = .clear
        }
    }
    
    func createStabilizationEffect(at position: CGPoint, color: SKColor) {
        guard let parent = parentNode else { return }
        
        let flash = SKShapeNode(circleOfRadius: 15)
        flash.position = position
        flash.fillColor = color
        flash.strokeColor = .clear
        flash.glowWidth = 10
        flash.blendMode = .add
        flash.zPosition = 50
        parent.addChild(flash)
        
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 3.0, duration: 0.4),
                SKAction.fadeOut(withDuration: 0.4)
            ]),
            SKAction.removeFromParent()
        ]))
    }
    
    func createExplosionEffect(at position: CGPoint, color: SKColor, radius: CGFloat) {
        guard let parent = parentNode else { return }
        
        let ring = SKShapeNode(circleOfRadius: 20)
        ring.position = position
        ring.fillColor = .clear
        ring.strokeColor = color
        ring.lineWidth = 4.0
        ring.glowWidth = 8.0
        ring.zPosition = 60
        parent.addChild(ring)
        
        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: radius / 20.0, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))
    }
    
    func screenShake(camera: SKCameraNode?) {
        guard let cam = camera else { return }
        
        let shake = SKAction.sequence([
            SKAction.moveBy(x: 5, y: 3, duration: 0.02),
            SKAction.moveBy(x: -10, y: -6, duration: 0.02),
            SKAction.moveBy(x: 8, y: 4, duration: 0.02),
            SKAction.moveBy(x: -3, y: -1, duration: 0.02)
        ])
        
        cam.run(SKAction.repeat(shake, count: 3))
    }
}
