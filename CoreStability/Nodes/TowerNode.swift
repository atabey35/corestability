// TowerNode.swift
// Idle Tower Defense
// Hexagonal tower with auto-targeting and firing

import SpriteKit

final class TowerNode: SKNode {
    
    // MARK: - Visual Components
    
    private let towerSprite: SKSpriteNode
    private var rangeCircle: SKShapeNode
    
    // MARK: - Stats (Upgradeable)
    
    var damage: CGFloat = 13
    var fireRate: CGFloat = 1.0
    var range: CGFloat = 150 {
        didSet {
            let path = CGMutablePath()
            path.addEllipse(in: CGRect(x: -range, y: -range, width: range * 2, height: range * 2))
            rangeCircle.path = path
        }
    }
    var maxHP: CGFloat = 130
    var currentHP: CGFloat = 130
    var hpRegen: CGFloat = 0.5
    var defense: CGFloat = 0
    
    // ...

    // MARK: - State
    
    private var fireCooldown: TimeInterval = 0
    private(set) var currentTarget: Enemy?
    private(set) var rotation: CGFloat = 0
    
    private var uziModeTime: TimeInterval = 0
    var isUziActive: Bool { uziModeTime > 0 }
    
    // MARK: - Colors
    
    private let towerColor = SKColor(red: 0.29, green: 0.56, blue: 0.85, alpha: 1.0)  // #4A90D9
    
    // MARK: - Initialization
    
    override init() {
        // Main Tower Sprite
        towerSprite = SKSpriteNode(imageNamed: "TowerSprite")
        // Scale down if the image is too large (assuming 512px or 1024px source, target roughly 60px diameter)
        towerSprite.size = CGSize(width: 60, height: 60) 
        towerSprite.zPosition = 10
        
        // Range circle
        rangeCircle = SKShapeNode(circleOfRadius: range)
        rangeCircle.fillColor = .clear
        rangeCircle.strokeColor = towerColor.withAlphaComponent(0.15)
        rangeCircle.lineWidth = 1.0
        
        super.init()
        
        addChild(rangeCircle)
        addChild(towerSprite)
        
        startIdleAnimation()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func startIdleAnimation() {
        // Gentle "breathing" scale
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 2.0),
            SKAction.scale(to: 0.95, duration: 2.0)
        ])
        towerSprite.run(SKAction.repeatForever(pulse))
        
        // Pulse range circle
        let rangePulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.6, duration: 2.0),
            SKAction.fadeAlpha(to: 0.3, duration: 2.0)
        ])
        rangeCircle.run(SKAction.repeatForever(rangePulse))
    }
    
    // MARK: - Update
    
    func update(deltaTime: TimeInterval, enemies: [Enemy]) {
        // Uzi Mode Timer
        if uziModeTime > 0 {
            uziModeTime -= deltaTime
        }
        
        // HP regen
        if currentHP < maxHP {
            currentHP = min(maxHP, currentHP + hpRegen * CGFloat(deltaTime))
        }
        
        // Fire cooldown
        if fireCooldown > 0 {
            fireCooldown -= deltaTime
        }
        
        // Find target
        currentTarget = findBestTarget(enemies: enemies)
        
        // Aim at target
        if let target = currentTarget {
            let dx = target.position.x - position.x
            let dy = target.position.y - position.y
            let targetAngle = atan2(dy, dx)
            
            // Smooth rotation
            var angleDiff = targetAngle - rotation
            while angleDiff > .pi { angleDiff -= .pi * 2 }
            while angleDiff < -.pi { angleDiff += .pi * 2 }
            
            rotation += angleDiff * 0.2  // Smooth aim
            towerSprite.zRotation = rotation - .pi / 2 // -90 deg adjustment for top-down sprite facing right/up? Assuming sprite faces UP.
        }
    }
    
    private func findBestTarget(enemies: [Enemy]) -> Enemy? {
        var bestTarget: Enemy?
        var bestDistance: CGFloat = .infinity
        
        for enemy in enemies where !enemy.isDead {
            let dx = enemy.position.x - position.x
            let dy = enemy.position.y - position.y
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance <= range && distance < bestDistance {
                bestDistance = distance
                bestTarget = enemy
            }
        }
        
        return bestTarget
    }
    
    // MARK: - Firing
    
    func canFire() -> Bool {
        return fireCooldown <= 0 && currentTarget != nil
    }
    
    func fire() -> (damage: CGFloat, position: CGPoint, direction: CGVector, speed: CGFloat, penetration: Int, explosionRadius: CGFloat)? {
        guard canFire(), let target = currentTarget else { return nil }
        
        // Fire Rate logic (Uzi = 5x speed -> 1/5 cooldown)
        let rate = isUziActive ? fireRate * 5.0 : fireRate
        fireCooldown = 1.0 / rate
        
        // Recoil animation
        let recoil = SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.05),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        towerSprite.run(recoil)
        
        // Calculate firing data
        let dx = target.position.x - position.x
        let dy = target.position.y - position.y
        let dist = hypot(dx, dy)
        let direction = CGVector(dx: dx / dist, dy: dy / dist)
        
        let splashBonus = GachaManager.shared.getBonus("splashDamage")
        return (
            damage: damage,
            position: position,
            direction: direction,
            speed: 600,
            penetration: 1 + GachaManager.shared.penetrationBonus,
            explosionRadius: splashBonus > 0 ? 60 : 0 // Fixed 60 radius if perk active
        )
    }
    
    // MARK: - Damage
    
    func takeDamage(_ amount: CGFloat) {
        // Defense reduction
        let finalDamage = max(1, amount - defense)
        currentHP -= finalDamage
        
        // Flash red
        let flash = SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.8, duration: 0.05),
            SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.1)
        ])
        towerSprite.run(flash)
    }
    
    var isDead: Bool { currentHP <= 0 }
    
    // MARK: - Upgrades
    
    // MARK: - Upgrades & Visuals
    
    func updateRange(newRange: CGFloat) {
        range = newRange
        
        // Remove old circle
        rangeCircle.removeFromParent()
        
        // Create new circle with "Neon" style
        rangeCircle = SKShapeNode(circleOfRadius: range)
        rangeCircle.fillColor = towerColor.withAlphaComponent(0.05)
        rangeCircle.strokeColor = towerColor.withAlphaComponent(0.3)
        rangeCircle.lineWidth = 2.0
        rangeCircle.glowWidth = 5.0
        rangeCircle.zPosition = -1
        addChild(rangeCircle)
        
        // Pulse Effect on Upgrade (Glow)
        let group = SKAction.group([
            SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.2)
            ]),
            SKAction.sequence([
                SKAction.run { self.rangeCircle.strokeColor = .white; self.rangeCircle.glowWidth = 10 },
                SKAction.wait(forDuration: 0.5),
                SKAction.run { 
                    self.rangeCircle.strokeColor = self.towerColor.withAlphaComponent(0.5) // Higher visibility
                    self.rangeCircle.glowWidth = 5.0
                    
                    // Restart Pulse
                    let pulse = SKAction.sequence([
                        SKAction.fadeAlpha(to: 0.6, duration: 2.0),
                        SKAction.fadeAlpha(to: 0.3, duration: 2.0)
                    ])
                    self.rangeCircle.run(SKAction.repeatForever(pulse))
                }
            ])
        ])
        rangeCircle.run(group)
    }

    
    func updateDamage(newDamage: CGFloat) {
        damage = newDamage
        // Visual flash?
        let flash = SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.5, duration: 0.1),
            SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.1)
        ])
        towerSprite.run(flash)
    }
    
    func updateFireRate(newRate: CGFloat) {
        fireRate = newRate
    }
    
    func updateStats(damage: CGFloat, range: CGFloat, fireRate: CGFloat, hp: CGFloat, defense: CGFloat) {
        self.updateDamage(newDamage: damage)
        self.fireRate = fireRate
        self.maxHP = hp
        // If updating range only if changed to avoid spamming visual
        if abs(self.range - range) > 1.0 {
            updateRange(newRange: range)
        }
        self.defense = defense
    }
    
    // MARK: - Active Skills
    
    func activateUziMode(duration: TimeInterval) {
        uziModeTime = duration
        
        // Visual indicator for UZI
        let rapid = SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.05),
            SKAction.scale(to: 1.0, duration: 0.05)
        ]))
        towerSprite.run(rapid, withKey: "uziAnim")
        
        // Glow Color Change
        let colorAction = SKAction.colorize(with: .orange, colorBlendFactor: 0.8, duration: 0.2)
        towerSprite.run(colorAction)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.towerSprite.removeAction(forKey: "uziAnim")
            self?.towerSprite.setScale(1.0) // Reset scale (relative to base size if scaled in init? No, scale is factor 1.0 of current size)
            // Actually, if we set size in init, setScale(1.0) resets to that size.
            
            self?.towerSprite.run(SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.2))
        }
    }
    
    // MARK: - Visual Flair
    
    func applyVisualFlair(activeBuffs: [String]) {
        // Clear previous effects
        childNode(withName: "godSlayerAura")?.removeFromParent()
        childNode(withName: "destinySparkles")?.removeFromParent()
        childNode(withName: "midasAura")?.removeFromParent()
        childNode(withName: "ascensionHalo")?.removeFromParent()
        
        // God Slayer (Damage) - Red/Orange Flamy Aura
        if activeBuffs.contains("dmg_l1") {
            let aura = SKShapeNode(circleOfRadius: 40)
            aura.fillColor = SKColor.red.withAlphaComponent(0.2)
            aura.strokeColor = .orange
            aura.lineWidth = 2
            aura.glowWidth = 10
            aura.zPosition = -1
            aura.name = "godSlayerAura"
            addChild(aura)
            
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 0.5),
                SKAction.scale(to: 1.0, duration: 0.5)
            ])
            aura.run(SKAction.repeatForever(pulse))
        }
        
        // Destiny's Edge (Crit) - Star Sparkles
        if activeBuffs.contains("crit_l1") {
            if let particles = SKEmitterNode(fileNamed: "SparkleParticle") {
                particles.name = "destinySparkles"
                particles.targetNode = self.parent
                particles.particlePositionRange = CGVector(dx: 40, dy: 40)
                particles.zPosition = 1
                addChild(particles)
            } else {
                let sparkles = SKShapeNode(circleOfRadius: 35)
                sparkles.strokeColor = .cyan
                sparkles.lineWidth = 1
                sparkles.name = "destinySparkles"
                addChild(sparkles)
                sparkles.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 2.0)))
            }
        }
        
        // Midas Touch (Gold) - Gold Aura
        if activeBuffs.contains("coin_l1") {
            let goldRing = SKShapeNode(circleOfRadius: 50)
            goldRing.strokeColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
            goldRing.lineWidth = 2
            goldRing.name = "midasAura"
            addChild(goldRing)
            goldRing.run(SKAction.repeatForever(SKAction.rotate(byAngle: -.pi, duration: 5.0)))
        }
        
        // Ascension (All Stats) - Crown/Halo
        if activeBuffs.contains("all_l1") {
            let halo = SKShapeNode(ellipseOf: CGSize(width: 40, height: 10))
            halo.strokeColor = .white
            halo.lineWidth = 2
            halo.glowWidth = 5
            halo.position = CGPoint(x: 0, y: 35)
            halo.name = "ascensionHalo"
            addChild(halo)
            
            let float = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 5, duration: 1.0),
                SKAction.moveBy(x: 0, y: -5, duration: 1.0)
            ])
            halo.run(SKAction.repeatForever(float))
        }
    }
}

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
    var orbitSpeed: CGFloat = 1.0
    
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
        
        // Targeting
        if let target = findTarget(enemies: enemies) {
            // Rotate to face target
            let dx = target.position.x - position.x
            let dy = target.position.y - position.y
            let angle = atan2(dy, dx) - .pi / 2
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
        // Find closest enemy in range (Manual Distance)
        var closest: Enemy?
        var minDstSq: CGFloat = CGFloat.greatestFiniteMagnitude
        let rangeSq = range * range
        
        for enemy in enemies {
            if enemy.isDead { continue }
            let dx = enemy.position.x - self.position.x
            let dy = enemy.position.y - self.position.y
            let distSq = dx*dx + dy*dy
            
            if distSq <= rangeSq {
                if distSq < minDstSq {
                    minDstSq = distSq
                    closest = enemy
                }
            }
        }
        return closest
    }
    
    private func fire(at target: Enemy, manager: ProjectileManager) {
        let dx = target.position.x - self.position.x
        let dy = target.position.y - self.position.y
        let dist = sqrt(dx*dx + dy*dy)
        let dir = CGVector(dx: dx/dist, dy: dy/dist)
        
        manager.spawnProjectile(
            type: .player,
            damage: damage,
            position: self.position,
            direction: dir,
            speed: 600,
            maxDistance: range + 50,
            penetration: 1,
            explosionRadius: 0
        )
        
        // Visual kickback
        let kick = SKAction.sequence([
            SKAction.moveBy(x: 0, y: -3, duration: 0.05),
            SKAction.moveBy(x: 0, y: 3, duration: 0.05)
        ])
        barrel.run(kick)
    }
}
