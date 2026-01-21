// ProjectileManager.swift
// Idle Tower Defense
// Manages all active projectiles using Object Pooling

import SpriteKit

protocol ProjectileManagerDelegate: AnyObject {
    func projectileManager(_ manager: ProjectileManager, didHitEnemy enemy: Enemy, withDamage damage: CGFloat, isCritical: Bool)
}

final class ProjectileManager {
    
    weak var delegate: ProjectileManagerDelegate?
    weak var parentNode: SKNode?
    
    private var activeProjectiles: [Projectile] = []
    private var projectilePool: EntityPool<Projectile>!
    
    // Critical hit chance (upgradeable)
    var critChance: CGFloat = 0.1
    var critMultiplier: CGFloat = 2.0
    
    init() {
        projectilePool = EntityPool(initialSize: 50) {
            return Projectile()
        }
    }
    
    func spawnProjectile(type: Projectile.ProjectileType, damage: CGFloat, position: CGPoint, direction: CGVector, speed: CGFloat, maxDistance: CGFloat = 600, penetration: Int = 1, explosionRadius: CGFloat = 0, isRocket: Bool = false) {
        guard let parent = parentNode else { return }
        
        let projectile = projectilePool.get()
        let hasPierceAll = InventoryManager.shared.hasActiveBuff(id: "pen_l1")
        
        projectile.setup(
            type: type,
            damage: damage,
            position: position,
            direction: direction,
            speed: speed,
            maxDistance: maxDistance,
            penetration: penetration,
            explosionRadius: explosionRadius,
            hasTrail: hasPierceAll && type == .player,
            isRocket: isRocket
        )
        
        parent.addChild(projectile)
        activeProjectiles.append(projectile)
    }
    
    func update(deltaTime: TimeInterval, enemies: [Enemy], tower: TowerNode?) {
        for projectile in activeProjectiles where projectile.isActive {
            projectile.update(deltaTime: deltaTime)
            
            // Check hits
            if let result = projectile.checkCollision(enemies: enemies, tower: tower) {
                switch result {
                case .enemy(let enemy):
                    // Primary damage
                    let isCritical = CGFloat.random(in: 0...1) < critChance
                    let damage = isCritical ? projectile.damage * critMultiplier : projectile.damage
                    
                    enemy.takeDamage(damage, isCritical: isCritical)
                    delegate?.projectileManager(self, didHitEnemy: enemy, withDamage: damage, isCritical: isCritical)
                    
                    // Splash Damage
                    if projectile.explosionRadius > 0 {
                        createSplashDamage(at: enemy.position, radius: projectile.explosionRadius, damage: damage * 0.5, enemies: enemies)
                    }
                    
                    // Penetration
                    projectile.penetration -= 1
                    if projectile.penetration <= 0 {
                        projectile.deactivate()
                    }
                    
                case .tower(let towerNode):
                    towerNode.takeDamage(projectile.damage)
                    projectile.deactivate()
                }
            }
        }
        
        // Clean up inactive projectiles
        var i = 0
        while i < activeProjectiles.count {
            let projectile = activeProjectiles[i]
            if !projectile.isActive {
                projectilePool.returnToPool(projectile)
                activeProjectiles.remove(at: i)
            } else {
                i += 1
            }
        }
    }
    
    private func createSplashDamage(at position: CGPoint, radius: CGFloat, damage: CGFloat, enemies: [Enemy]) {
        let radiusSq = radius * radius
        for enemy in enemies where !enemy.isDead {
            let dx = enemy.position.x - position.x
            let dy = enemy.position.y - position.y
            if dx*dx + dy*dy <= radiusSq {
                enemy.takeDamage(damage)
            }
        }
        // Visuals would go here (e.g. shockwave)
    }
    
    func reset() {
        projectilePool.returnAll(activeProjectiles)
        activeProjectiles.removeAll()
    }
}
