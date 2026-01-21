// Enemy.swift
// Idle Tower Defense
// Advanced enemy types with distinct behaviors and shapes

import SpriteKit

protocol EnemyDelegate: AnyObject {
    func enemyDidFire(_ enemy: Enemy, projectile: Projectile) // Logic handled by ProjectileManager normally, but here we might need a way to spawn simple enemy projectiles
}

class Enemy: SKNode, Poolable {
    
    // MARK: - Types
    
    enum EnemyType {
        case square    // Lv 1-10: Slow, weak, small
        case triangle  // Lv 10-20: Fast, low HP
        case swarmer   // Existing
        case normal    // Existing
        case tank      // Existing
        case ranged    // Lv 20+: Shoots
        case healer    // Support: Heals allies
        case boss      // Existing
        // NEW: Phase 1 enemy types
        case miniBoss  // Every 5 waves: 5x HP, slower
        case splitter  // Splits into 2 on death
        case shielder  // 50% frontal damage reduction
        
        var color: SKColor {
            switch self {
            case .square: return SKColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)    // Blueish
            case .triangle: return SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)  // Yellowish
            case .swarmer: return SKColor(red: 1.0, green: 0.9, blue: 0.2, alpha: 1.0)
            case .normal: return SKColor(red: 1.0, green: 0.28, blue: 0.34, alpha: 1.0)
            case .tank: return SKColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 1.0)
            case .ranged: return SKColor(red: 0.8, green: 0.4, blue: 1.0, alpha: 1.0)
            case .healer: return .green
            case .boss: return SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
            case .miniBoss: return SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)  // Orange
            case .splitter: return SKColor(red: 0.3, green: 1.0, blue: 0.5, alpha: 1.0)  // Bright Green
            case .shielder: return SKColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)  // Shield Blue
            }
        }
        
        var baseHP: CGFloat {
            switch self {
            case .square: return 0.5
            case .triangle: return 0.6
            case .swarmer: return 0.4
            case .normal: return 1.0
            case .tank: return 4.0
            case .ranged: return 0.8
            case .healer: return 2.0
            case .boss: return 75.0  // 3x buff (was 25.0)
            case .miniBoss: return 5.0   // 5x normal
            case .splitter: return 1.5   // Splits into 2
            case .shielder: return 2.5   // Tanky support
            }
        }
        
        var baseSpeed: CGFloat {
            switch self {
            case .square: return 0.6
            case .triangle: return 1.5
            case .swarmer: return 1.8
            case .normal: return 1.0
            case .tank: return 0.5
            case .ranged: return 0.8
            case .healer: return 0.8
            case .boss: return 0.3
            case .miniBoss: return 0.8   // 20% slower than normal
            case .splitter: return 1.1   // Slightly fast
            case .shielder: return 0.7   // Slow, defensive
            }
        }
        
        var size: CGFloat {
            switch self {
            case .square: return 10
            case .triangle: return 10
            case .swarmer: return 8
            case .normal: return 12
            case .tank: return 16
            case .ranged: return 14
            case .healer: return 12
            case .boss: return 30
            case .miniBoss: return 22    // Large, imposing
            case .splitter: return 14    // Medium
            case .shielder: return 16    // Shield bearer
            }
        }
        
        var attackRange: CGFloat {
            switch self {
            case .ranged: return 200
            case .healer: return 150
            case .boss: return 150
            default: return 0
            }
        }
    }
    
    // MARK: - Properties
    
    var enemyId: Int = 0
    var enemyType: EnemyType = .normal
    
    private(set) var maxHP: CGFloat = 10
    private(set) var currentHP: CGFloat = 10
    private(set) var moveSpeed: CGFloat = 50
    private(set) var damage: CGFloat = 5
    private(set) var coinValue: Int = 1
    
    // Slow effect
    private var slowMultiplier: CGFloat = 1.0
    private var slowDuration: TimeInterval = 0
    var isSlowed: Bool { slowMultiplier < 1.0 }
    
    private(set) var isDead: Bool = false
    
    private let shape: SKShapeNode
    private let hpBar: SKShapeNode
    private let hpBarFill: SKShapeNode
    private let glow: SKShapeNode
    
    var targetPosition: CGPoint = .zero
    
    // MARK: - Initialization
    
    override init() {
        // Main Shape
        shape = SKShapeNode()
        shape.lineWidth = 2.0
        
        // Glow
        glow = SKShapeNode()
        glow.lineWidth = 4.0
        glow.strokeColor = .clear
        glow.fillColor = .clear
        glow.blendMode = .add
        
        // HP Bar background
        let barWidth: CGFloat = 20
        let barHeight: CGFloat = 3
        hpBar = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 1)
        hpBar.fillColor = SKColor(white: 0.2, alpha: 0.8)
        hpBar.strokeColor = .clear
        
        // HP Bar fill
        hpBarFill = SKShapeNode(rectOf: CGSize(width: barWidth - 2, height: barHeight - 1), cornerRadius: 1)
        hpBarFill.fillColor = .green
        hpBarFill.strokeColor = .clear
        
        super.init()
        
        addChild(glow)
        addChild(shape)
        addChild(hpBar)
        addChild(hpBarFill)
    }
    
    func setup(id: Int, type: EnemyType, hp: CGFloat, speed: CGFloat, damage: CGFloat, coinValue: Int) {
        self.enemyId = id
        self.enemyType = type
        self.maxHP = hp * type.baseHP
        self.currentHP = self.maxHP
        self.moveSpeed = speed * type.baseSpeed
        self.coinValue = coinValue * (type == .boss ? 50 : (type == .tank ? 3 : 1))
        self.damage = damage * (type == .boss ? 5.0 : (type == .tank ? 2.0 : 1.0))
        
        self.isDead = false
        self.isHidden = false
        self.alpha = 1.0
        self.targetPosition = .zero
        
        // Update visuals
        updateShape()
        
        hpBar.position = CGPoint(x: 0, y: type.size + 15)
        hpBarFill.position = CGPoint(x: 0, y: type.size + 15)
        hpBarFill.xScale = 1.0
        hpBarFill.fillColor = .green
        hpBar.isHidden = false
        hpBarFill.isHidden = false
    }
    
    private func updateShape() {
        shape.removeFromParent()
        glow.removeFromParent()
        removeAllChildren()
        
        addChild(glow)
        addChild(shape) // Re-add base nodes if we cleared, but actually let's reconstruct
        addChild(hpBar)
        addChild(hpBarFill)
        
        let color = enemyType.color
        let size = enemyType.size
        
        // Layer 1: Outer Shape
        let outerShape: SKShapeNode
        switch enemyType {
        case .square, .normal: // Square
            outerShape = SKShapeNode(rectOf: CGSize(width: size*2, height: size*2), cornerRadius: 4)
        case .triangle, .swarmer: // Triangle
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: size))
            path.addLine(to: CGPoint(x: size, y: -size))
            path.addLine(to: CGPoint(x: -size, y: -size))
            path.closeSubpath()
            outerShape = SKShapeNode(path: path)
        case .tank: // Hexagon
            let path = createPolygonPath(radius: size, sides: 6)
            outerShape = SKShapeNode(path: path)
        case .ranged: // Diamond / Octagon
             let path = createPolygonPath(radius: size * 0.8, sides: 8)
             outerShape = SKShapeNode(path: path)
        case .healer: // Pentagon
             let path = createPolygonPath(radius: size, sides: 5)
             outerShape = SKShapeNode(path: path)
             outerShape.zRotation = .pi / 2

        case .boss: // Star
            let path = createStarPath(radius: size * 1.5)
            outerShape = SKShapeNode(path: path)
            
        // NEW: Phase 1 enemy visuals
        case .miniBoss: // Large star with extra glow
            let path = createStarPath(radius: size * 1.2)
            outerShape = SKShapeNode(path: path)
            
        case .splitter: // Diamond that splits
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: size))
            path.addLine(to: CGPoint(x: size, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -size))
            path.addLine(to: CGPoint(x: -size, y: 0))
            path.closeSubpath()
            outerShape = SKShapeNode(path: path)
            
        case .shielder: // Hexagon with shield aura
            let path = createPolygonPath(radius: size, sides: 6)
            outerShape = SKShapeNode(path: path)
        }
        
        outerShape.fillColor = color.withAlphaComponent(0.2)
        outerShape.strokeColor = color
        outerShape.lineWidth = 2
        // Enhanced glow for special enemy types
        switch enemyType {
        case .boss: outerShape.glowWidth = 15
        case .miniBoss: outerShape.glowWidth = 10
        case .shielder: outerShape.glowWidth = 6
        default: outerShape.glowWidth = 4
        }
        
        // Replace 'shape' with this new structure or add to it
        // Since 'shape' is let constant SKShapeNode, we can't replace it easily without changing init.
        // Instead, we'll make 'shape' the container or just add children to self.
        // But logic uses 'shape' for flash actions.
        // Let's remove 'shape' content and add this 'outerShape' as child of 'shape'?
        // No, 'shape' IS an SKShapeNode.
        // We can set shape.path.
        
        shape.path = outerShape.path
        shape.fillColor = outerShape.fillColor
        shape.strokeColor = outerShape.strokeColor
        shape.glowWidth = outerShape.glowWidth
        
        // Glow node sync
        glow.path = shape.path
        glow.strokeColor = color.withAlphaComponent(0.5)
        glow.lineWidth = 4
        
        // Layer 2: Inner Core (Rotating)
        let innerSize = CGSize(width: size * 0.8, height: size * 0.8)
        let innerShape = SKShapeNode(rectOf: innerSize, cornerRadius: 2)
        innerShape.fillColor = color
        innerShape.strokeColor = .white
        innerShape.lineWidth = 1
        innerShape.name = "core"
        addChild(innerShape)
        
        let rotate = SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 2.0))
        innerShape.run(rotate)
        
        // Layer 3: Shield Ring for Shielder type
        if enemyType == .shielder {
            let shieldRing = SKShapeNode(circleOfRadius: size * 1.8)
            shieldRing.strokeColor = SKColor.cyan.withAlphaComponent(0.6)
            shieldRing.lineWidth = 3
            shieldRing.fillColor = .clear
            shieldRing.glowWidth = 4
            shieldRing.name = "shieldRing"
            addChild(shieldRing)
            
            // Pulsing animation
            let pulse = SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.5),
                SKAction.scale(to: 1.0, duration: 0.5)
            ]))
            shieldRing.run(pulse)
        }
    }
    
    private func createStarPath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let points = 8
        for i in 0...points*2 {
            let angle = CGFloat(i) * .pi / CGFloat(points)
            let r = i % 2 == 0 ? radius : radius * 0.5
            let x = cos(angle) * r
            let y = sin(angle) * r
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.closeSubpath()
        return path
    }
    
    private func createPolygonPath(radius: CGFloat, sides: Int) -> CGPath {
        let path = CGMutablePath()
        for i in 0..<sides {
            let angle = CGFloat(i) * (2 * .pi / CGFloat(sides))
            let x = cos(angle) * radius
            let y = sin(angle) * radius
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.closeSubpath()
        return path
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reset() {
        isDead = false
        removeAllActions()
    }
    
    // MARK: - Update
    
    func update(deltaTime: TimeInterval) {
        guard !isDead else { return }
        
        let dx = targetPosition.x - position.x
        let dy = targetPosition.y - position.y
        let distance = sqrt(dx * dx + dy * dy)
        
        // Movement Logic
        var shouldMove = true
        
        // Slow effect timer
        if slowDuration > 0 {
            slowDuration -= deltaTime
            if slowDuration <= 0 {
                slowMultiplier = 1.0
                shape.fillColor = enemyType.color.withAlphaComponent(0.2)
            }
        }
        
        if enemyType == .ranged || enemyType == .boss {
            if distance <= enemyType.attackRange {
                shouldMove = false
            }
        }
        
        if shouldMove && distance > 5 {
            let effectiveSpeed = moveSpeed * slowMultiplier  // Apply slow
            let moveX = (dx / distance) * effectiveSpeed * CGFloat(deltaTime)
            let moveY = (dy / distance) * effectiveSpeed * CGFloat(deltaTime)
            position.x += moveX
            position.y += moveY
            
            // Rotate towards target
            zRotation = atan2(dy, dx) - .pi/2
        } else {
            // Attack logic for ranged
            zRotation = atan2(dy, dx) - .pi/2
            
            if (enemyType == .ranged || enemyType == .boss) {
                fireCooldown -= deltaTime
            }
        }
        
        // Update HP bar
        let hpRatio = currentHP / maxHP
        hpBarFill.xScale = max(0, hpRatio)
        
        if hpRatio > 0.6 { hpBarFill.fillColor = .green }
        else if hpRatio > 0.3 { hpBarFill.fillColor = .yellow }
        else { hpBarFill.fillColor = .red }
    }
    
    // MARK: - Properties (Addition)
    private var fireCooldown: TimeInterval = 0
    private let fireRate: CGFloat = 0.5 // 1 shot every 2 seconds
    
    func canFire() -> Bool {
        return !isDead && (enemyType == .ranged || enemyType == .boss) && fireCooldown <= 0
    }
    
    func fire() -> (damage: CGFloat, position: CGPoint, direction: CGVector, speed: CGFloat)? {
        guard canFire() else { return nil }
        
        fireCooldown = 1.0 / fireRate
        
        let dx = targetPosition.x - position.x
        let dy = targetPosition.y - position.y
        let dist = sqrt(dx * dx + dy * dy)
        let direction = CGVector(dx: dx / dist, dy: dy / dist)
        
        return (
            damage: damage, // Use enemy's damage stat
            position: position,
            direction: direction,
            speed: 300 // Slower than tower projectiles
        )
    }
    
    // MARK: - Damage
    
    /// Returns true if this enemy should split on death (splitter type)
    var shouldSplitOnDeath: Bool {
        return enemyType == .splitter && !isDead
    }
    
    func takeDamage(_ amount: CGFloat, isCritical: Bool = false) {
        if isDead { return }
        
        // Shielder: 50% frontal damage reduction
        var actualDamage = amount
        if enemyType == .shielder {
            actualDamage = amount * 0.5
        }
        
        currentHP -= actualDamage
        if currentHP <= 0 {
            die()
        } else {
            updateHPBar()
            // Flash red
            let flash = SKAction.sequence([
                SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 0.05),
                SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.05)
            ])
            shape.run(flash)
        }
    }
    
    func heal(amount: CGFloat) {
        if isDead { return }
        currentHP = min(currentHP + amount, maxHP)
        updateHPBar()
        
        // Visual
        let flash = SKAction.sequence([
            SKAction.colorize(with: .green, colorBlendFactor: 0.8, duration: 0.1),
            SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.1)
        ])
        shape.run(flash)
    }

    
    private func die() {
        isDead = true
        
        // Record Stat
        GameStats.shared.recordKill(isBoss: enemyType == .boss)
        
        // Play Sound
        AudioManager.shared.playEnemyDeath()
        
        // Death animation
        let explode = SKAction.group([
            SKAction.scale(to: 1.5, duration: 0.1),
            SKAction.fadeOut(withDuration: 0.1)
        ])
        
        run(SKAction.sequence([explode, SKAction.removeFromParent()]))
    }
    
    func distanceTo(_ point: CGPoint) -> CGFloat {
        let dx = point.x - position.x
        let dy = point.y - position.y
        return sqrt(dx * dx + dy * dy)
    }
    
    // MARK: - Slow Effect
    
    func applySlow(multiplier: CGFloat, duration: TimeInterval) {
        slowMultiplier = multiplier
        slowDuration = duration
        
        // Visual feedback - turn blue
        shape.fillColor = SKColor.cyan.withAlphaComponent(0.4)
        
        // Frozen particle effect
        let frost = SKEmitterNode()
        frost.particleBirthRate = 10
        frost.particleLifetime = 0.5
        frost.particleColor = .cyan
        frost.particleSize = CGSize(width: 3, height: 3)
        frost.particleAlpha = 0.8
        frost.particleAlphaSpeed = -1.5
        frost.name = "frost"
        addChild(frost)
        
        // Remove frost after duration
        run(SKAction.sequence([
            SKAction.wait(forDuration: duration),
            SKAction.run { [weak self] in
                self?.childNode(withName: "frost")?.removeFromParent()
            }
        ]))
    }

    
    // MARK: - Helper
    private func updateHPBar() {
        let percent = currentHP / maxHP
        hpBarFill.xScale = max(percent, 0)
        hpBarFill.fillColor = percent > 0.5 ? .green : (percent > 0.2 ? .yellow : .red)
    }
}
