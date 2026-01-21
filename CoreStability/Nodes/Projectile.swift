// Projectile.swift
// Idle Tower Defense
// Bullet with trail effect

import SpriteKit

final class Projectile: SKNode, Poolable {
    
    enum ProjectileType {
        case player
        case enemy
    }
    
    enum CollisionResult {
        case enemy(Enemy)
        case tower(TowerNode)
    }
    
    // MARK: - Properties
    
    var projectileType: ProjectileType = .player
    var damage: CGFloat = 0
    var moveSpeed: CGFloat = 0
    var direction: CGVector = .zero
    
    // Weapon properties
    var penetration: Int = 1
    var explosionRadius: CGFloat = 0
    private var hitTargets: Set<SKNode> = [] // Track hit nodes (Enemies/Tower)
    
    private(set) var isActive: Bool = true
    private var traveledDistance: CGFloat = 0
    private var maxDistance: CGFloat = 600
    
    private let bulletShape: SKShapeNode
    private var trailPoints: [CGPoint] = []
    private let trailNode: SKShapeNode
    private let maxTrailLength: Int = 8
    
    // NEW: Sprite for Rocket
    private var spriteNode: SKSpriteNode!
    private var isRocket: Bool = false
    
    // MARK: - Initialization
    
    override init() {
        // Bullet shape - small bright circle
        bulletShape = SKShapeNode(circleOfRadius: 4)
        bulletShape.lineWidth = 1.0
        bulletShape.glowWidth = 6.0
        
        // Trail
        trailNode = SKShapeNode()
        trailNode.lineWidth = 2.0
        trailNode.lineCap = .round
        trailNode.blendMode = .add
        
        super.init()
        
        addChild(trailNode)
        addChild(bulletShape)
        
        // Initialize Rocket Sprite (Hidden by default)
        spriteNode = SKSpriteNode(imageNamed: "RocketSprite")
        spriteNode.isHidden = true
        spriteNode.zPosition = 5
        addChild(spriteNode)
    }
    
    func setup(type: ProjectileType, damage: CGFloat, position: CGPoint, direction: CGVector, speed: CGFloat, maxDistance: CGFloat = 600, penetration: Int = 1, explosionRadius: CGFloat = 0, hasTrail: Bool = false, isRocket: Bool = false) {
        self.projectileType = type
        self.damage = damage
        self.position = position
        self.direction = direction
        self.moveSpeed = speed
        self.maxDistance = maxDistance
        self.penetration = penetration
        self.explosionRadius = explosionRadius
        self.isRocket = isRocket
        
        self.isActive = true
        self.traveledDistance = 0
        self.isHidden = false
        self.alpha = 1.0
        self.hitTargets.removeAll()
        
        // Visuals based on type and stats
        if isRocket {
            // Rocket Mode
            bulletShape.isHidden = true
            trailNode.isHidden = false // Keep trail for rocket
            trailNode.strokeColor = .cyan
            
            spriteNode.isHidden = false
            spriteNode.texture = SKTexture(imageNamed: "RocketSprite")
            spriteNode.xScale = 0.6 // Adjust size as needed
            spriteNode.yScale = 0.6
            
            // Rotate sprite to face direction
            let angle = atan2(direction.dy, direction.dx)
            spriteNode.zRotation = angle
            
        } else if type == .player {
            // Standard Projectile Mode (Sprite)
            bulletShape.isHidden = true
            trailNode.isHidden = false
            
            spriteNode.isHidden = false
            spriteNode.texture = SKTexture(imageNamed: "ProjectileSprite")
            // Re-calc angle
            let angle = atan2(direction.dy, direction.dx)
            spriteNode.zRotation = angle
            
            if hasTrail { // Pierce All Legendary Visual
                spriteNode.color = .cyan
                spriteNode.colorBlendFactor = 0.0 // True colors
                trailNode.strokeColor = .cyan
                spriteNode.xScale = 0.5; spriteNode.yScale = 0.5
            } else if explosionRadius > 0 { // Plasma
                spriteNode.color = .blue
                spriteNode.colorBlendFactor = 0.3
                trailNode.strokeColor = .cyan
                spriteNode.xScale = 0.8; spriteNode.yScale = 0.8
            } else if penetration > 1 { // Railgun
                spriteNode.color = .magenta
                spriteNode.colorBlendFactor = 0.5
                trailNode.strokeColor = .magenta
                spriteNode.xScale = 0.4; spriteNode.yScale = 0.6
            } else { // Normal
                spriteNode.color = .white
                spriteNode.colorBlendFactor = 0.0
                trailNode.strokeColor = SKColor(red: 0.29, green: 0.56, blue: 0.85, alpha: 0.6)
                spriteNode.xScale = 0.4; spriteNode.yScale = 0.4
            }
        } else {
            // Enemy Projectile (Red/Yellow)
            spriteNode.isHidden = true // Or use a different sprite for enemies?
            bulletShape.isHidden = false
            trailNode.isHidden = false
            
            bulletShape.fillColor = .red
            bulletShape.strokeColor = .yellow
            trailNode.strokeColor = SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.6)
            bulletShape.xScale = 1.0; bulletShape.yScale = 1.0
        }
        
        // Reset trail
        trailPoints.removeAll()
        trailNode.path = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reset() {
        isActive = false
        traveledDistance = 0
        trailPoints.removeAll()
        trailNode.path = nil
        hitTargets.removeAll()
        removeAllActions()
    }
    
    // MARK: - Update
    
    func update(deltaTime: TimeInterval) {
        guard isActive else { return }
        
        // Store current position for trail
        trailPoints.append(position)
        if trailPoints.count > maxTrailLength {
            trailPoints.removeFirst()
        }
        
        // Move
        let moveDistance = moveSpeed * CGFloat(deltaTime)
        position.x += direction.dx * moveDistance
        position.y += direction.dy * moveDistance
        traveledDistance += moveDistance
        
        // Update trail
        updateTrail()
        
        // Check max distance
        if traveledDistance >= maxDistance {
            deactivate()
        }
    }
    
    private func updateTrail() {
        guard trailPoints.count >= 2 else { return }
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: trailPoints[0].x - position.x, y: trailPoints[0].y - position.y))
        
        for i in 1..<trailPoints.count {
            let point = CGPoint(x: trailPoints[i].x - position.x, y: trailPoints[i].y - position.y)
            path.addLine(to: point)
        }
        
        trailNode.path = path
    }
    
    // MARK: - Collision
    
    func checkCollision(enemies: [Enemy], tower: TowerNode?) -> CollisionResult? {
        guard isActive else { return nil }
        
        if projectileType == .player {
            // Check enemies
            for enemy in enemies where !enemy.isDead {
                if hitTargets.contains(enemy) { continue }
                
                let dx = enemy.position.x - position.x
                let dy = enemy.position.y - position.y
                let distSq = dx*dx + dy*dy
                // Radius sum approx: Proj(4) + Enemy(12-20) approx 20. 20^2=400
                if distSq < 400 {
                    hitTargets.insert(enemy)
                    return .enemy(enemy)
                }
            }
        } else if projectileType == .enemy {
            // Check tower
            guard let tower = tower else { return nil }
            if hitTargets.contains(tower) { return nil }
            
            // Tower is approx radius 25
            let dx = tower.position.x - position.x
            let dy = tower.position.y - position.y
            let distSq = dx*dx + dy*dy
            if distSq < 900 { // 30^2
                hitTargets.insert(tower)
                return .tower(tower)
            }
        }
        
        return nil
    }
    
    func deactivate() {
        isActive = false
        
        let fade = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.1),
            SKAction.removeFromParent()
        ])
        run(fade)
    }
}
