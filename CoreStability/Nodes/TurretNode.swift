// TurretNode.swift
// CoreStability
// Autonomous orbiting turret

import SpriteKit

class TurretNode: SKNode {
    
    // Components
    private var base: SKShapeNode!
    private var barrel: SKShapeNode!
    
    // Stats
    var range: CGFloat = 120
    var damage: CGFloat = 5
    var fireRate: TimeInterval = 0.8
    private var lastFireTime: TimeInterval = 0
    
    // Orbit
    var orbitRadius: CGFloat = 60
    var orbitAngle: CGFloat = 0
    var orbitSpeed: CGFloat = 1.0 // Radians per second
    
    override init() {
        super.init()
        setupVisuals()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupVisuals() {
        // Base - Small Hexagon
        base = SKShapeNode(rectOf: CGSize(width: 20, height: 20), cornerRadius: 4)
        base.fillColor = .cyan
        base.strokeColor = .white
        base.lineWidth = 1
        addChild(base)
        
        // Barrel
        barrel = SKShapeNode(rectOf: CGSize(width: 8, height: 20))
        barrel.fillColor = .darkGray
        barrel.position = CGPoint(x: 0, y: 10)
        base.addChild(barrel)
    }
    
    func update(deltaTime: TimeInterval, center: CGPoint, enemies: [Enemy], projectileManager: ProjectileManager) {
        // Orbit Logic
        orbitAngle += orbitSpeed * CGFloat(deltaTime)
        self.position = CGPoint(
            x: center.x + cos(orbitAngle) * orbitRadius,
            y: center.y + sin(orbitAngle) * orbitRadius
        )
        
        // Rotate base to face outward (or target)
        // For now, let's just make it spin with orbit or look at enemy
        
        // Targeting
        if let target = findTarget(enemies: enemies) {
            // Rotate to face target
            let angle = atan2(target.position.y - position.y, target.position.x - position.x) - .pi / 2
            base.zRotation = angle
            
            // Fire
            lastFireTime += deltaTime
            if lastFireTime >= fireRate {
                fire(at: target, manager: projectileManager)
                lastFireTime = 0
            }
        } else {
            // Idle rotation (tangent to orbit)
             base.zRotation = orbitAngle - .pi / 2
        }
    }
    
    private func findTarget(enemies: [Enemy]) -> Enemy? {
        // Find closest enemy in range
        return enemies
            .filter { !$0.isDead && $0.position.distance(to: self.position) <= range }
            .min(by: { $0.position.distance(to: self.position) < $1.position.distance(to: self.position) })
    }
    
    private func fire(at target: Enemy, manager: ProjectileManager) {
        // Simple projectile
        // We can use a specialized 'turret' projectile type or generic
        let direction = (target.position - self.position).normalized()
        manager.spawnProjectile(from: self.position, direction: direction.toCGVector(), damage: damage, isExplosive: false, freezeDuration: 0)
        
        // Visual kickback
        let kick = SKAction.sequence([
            SKAction.moveBy(x: 0, y: -3, duration: 0.05),
            SKAction.moveBy(x: 0, y: 3, duration: 0.05)
        ])
        barrel.run(kick)
    }
}
