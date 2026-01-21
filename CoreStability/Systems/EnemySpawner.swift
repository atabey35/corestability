// EnemySpawner.swift
// Idle Tower Defense
// Wave-based enemy spawning using Object Pooling

import SpriteKit

protocol EnemySpawnerDelegate: AnyObject {
    func enemySpawner(_ spawner: EnemySpawner, didSpawnEnemy enemy: Enemy)
}

final class EnemySpawner {
    
    weak var delegate: EnemySpawnerDelegate?
    weak var parentNode: SKNode?
    
    var screenSize: CGSize = .zero
    var targetPosition: CGPoint = .zero  // Tower position
    
    private var activeEnemies: [Enemy] = []
    
    func getAllEnemies() -> [Enemy] {
        return activeEnemies
    }
    
    private var enemyPool: EntityPool<Enemy>!
    
    private var nextEnemyId: Int = 0
    
    // Wave config
    private var enemiesToSpawn: Int = 0
    private var spawnedThisWave: Int = 0
    private var spawnCooldown: TimeInterval = 0
    private var spawnInterval: TimeInterval = 1.0
    
    // Scaling
    var baseHP: CGFloat = 10
    var baseSpeed: CGFloat = 50
    var baseDamage: CGFloat = 10
    var baseCoinValue: Int = 1
    
    init() {
        enemyPool = EntityPool(initialSize: 20) {
            return Enemy()
        }
    }
    
    private var currentWave: Int = 0
    
    // MARK: - Wave Control
    
    func startWave(wave: Int, enemyCount: Int, spawnInterval: TimeInterval) {
        self.currentWave = wave
        self.enemiesToSpawn = enemyCount
        self.spawnedThisWave = 0
        self.spawnInterval = spawnInterval
        self.spawnCooldown = 0.5
    }
    
    func isWaveComplete() -> Bool {
        return spawnedThisWave >= enemiesToSpawn && activeEnemies.isEmpty
    }
    
    // MARK: - Update
    
    func update(deltaTime: TimeInterval) {
        // Spawn enemies
        if spawnedThisWave < enemiesToSpawn {
            spawnCooldown -= deltaTime
            if spawnCooldown <= 0 {
                // Boss wave detection (every 10th wave)
                let isBossWave = currentWave > 0 && currentWave % 10 == 0
                // Mini-boss wave detection (every 5th wave except boss waves)
                let isMiniBossWave = currentWave > 0 && currentWave % 5 == 0 && !isBossWave
                
                let isLastEnemy = spawnedThisWave == enemiesToSpawn - 1
                let shouldSpawnBoss = isBossWave && isLastEnemy
                let shouldSpawnMiniBoss = isMiniBossWave && isLastEnemy
                
                spawnEnemy(isBoss: shouldSpawnBoss, isMiniBoss: shouldSpawnMiniBoss)
                spawnCooldown = spawnInterval
            }
        }
        
        // Update enemies
        for enemy in activeEnemies where !enemy.isDead {
            enemy.update(deltaTime: deltaTime)
        }
        
        // Clean up dead enemies
        var i = 0
        while i < activeEnemies.count {
            let enemy = activeEnemies[i]
            // If dead and internal die animation finished (removed from parent)
            // Or we can explicitly return to pool when they 'die' logic completes
            // Currently Enemy removes itself from parent on die().
            // Ideally ProjectileManager or GameScene handles the "kill" logic, but Enemy has self-managed death for now.
            // Let's rely on parent checking.
            
            if enemy.parent == nil && enemy.isDead {
                enemyPool.returnToPool(enemy)
                activeEnemies.remove(at: i)
            } else {
                i += 1
            }
        }
    }
    
    private func spawnEnemy(isBoss: Bool = false, isMiniBoss: Bool = false) {
        guard let parent = parentNode else { return }
        
        let type: Enemy.EnemyType
        
        if isBoss {
            type = .boss
        } else if isMiniBoss {
            type = .miniBoss
        } else {
            // S-Curve Spawn Logic (Phase 1)
            // Wave 1-10: Squares, some Healers
            // Wave 11-20: Triangles, more variety
            // Wave 21-30: Add Splitters, Shielders
            // Wave 31-50: Full chaos
            
            if currentWave <= 10 {
                // Tutorial Phase: Easy enemies
                let roll = Int.random(in: 0..<100)
                if currentWave >= 5 && roll < 10 {
                    type = .healer
                } else {
                    type = .square
                }
            } else if currentWave <= 20 {
                // Ramp Up: Fast enemies, introduce specialists
                let roll = Int.random(in: 0..<100)
                if currentWave >= 15 && roll < 10 { type = .splitter }
                else if currentWave >= 15 && roll < 18 { type = .shielder }
                else if roll < 30 { type = .healer }
                else { type = .triangle }
            } else if currentWave <= 35 {
                // Core Challenge: Mixed bag with specialists
                let roll = Int.random(in: 0..<100)
                if roll < 15 { type = .splitter }
                else if roll < 25 { type = .shielder }
                else if roll < 40 { type = .ranged }
                else if roll < 55 { type = .triangle }
                else if roll < 70 { type = .tank }
                else if roll < 80 { type = .healer }
                else { type = .normal }
            } else {
                // Epic Endgame: Maximum variety
                let roll = Int.random(in: 0..<100)
                if roll < 20 { type = .splitter }
                else if roll < 35 { type = .shielder }
                else if roll < 50 { type = .ranged }
                else if roll < 60 { type = .tank }
                else if roll < 75 { type = .triangle }
                else if roll < 85 { type = .healer }
                else { type = .swarmer }
            }
        }
        
        let enemy = enemyPool.get()
        enemy.setup(
            id: nextEnemyId,
            type: type,
            hp: baseHP,
            speed: baseSpeed,
            damage: baseDamage,
            coinValue: baseCoinValue
        )
        nextEnemyId += 1
        
        // Spawn from random edge
        enemy.position = randomEdgePosition()
        enemy.targetPosition = targetPosition
        
        parent.addChild(enemy)
        activeEnemies.append(enemy)
        spawnedThisWave += 1
        
        delegate?.enemySpawner(self, didSpawnEnemy: enemy)
    }
    
    /// Spawn split enemies when a Splitter dies
    func spawnSplitEnemies(at position: CGPoint, count: Int = 2) {
        guard let parent = parentNode else { return }
        
        for i in 0..<count {
            let splitEnemy = enemyPool.get()
            splitEnemy.setup(
                id: nextEnemyId,
                type: .swarmer,  // Splitter children are fast swarmers
                hp: baseHP * 0.3,  // 30% of parent HP
                speed: baseSpeed * 1.5,  // 50% faster
                damage: baseDamage * 0.4,  // 40% damage
                coinValue: 1
            )
            nextEnemyId += 1
            
            // Offset positions slightly
            let angle = CGFloat(i) * (.pi * 2.0 / CGFloat(count))
            let offset: CGFloat = 20
            splitEnemy.position = CGPoint(
                x: position.x + cos(angle) * offset,
                y: position.y + sin(angle) * offset
            )
            splitEnemy.targetPosition = targetPosition
            
            parent.addChild(splitEnemy)
            activeEnemies.append(splitEnemy)
        }
    }
    
    private func randomEdgePosition() -> CGPoint {
        let edge = Int.random(in: 0..<4)
        let padding: CGFloat = 50
        
        switch edge {
        case 0: // Top
            return CGPoint(x: CGFloat.random(in: 0...screenSize.width), y: screenSize.height + padding)
        case 1: // Bottom
            return CGPoint(x: CGFloat.random(in: 0...screenSize.width), y: -padding)
        case 2: // Left
            return CGPoint(x: -padding, y: CGFloat.random(in: 0...screenSize.height))
        default: // Right
            return CGPoint(x: screenSize.width + padding, y: CGFloat.random(in: 0...screenSize.height))
        }
    }
    
    // MARK: - Access
    
    func getEnemies() -> [Enemy] {
        return activeEnemies
    }
    
    func getAliveCount() -> Int {
        return activeEnemies.count
    }
    
    func reset() {
        enemyPool.returnAll(activeEnemies)
        activeEnemies.removeAll()
        nextEnemyId = 0
        enemiesToSpawn = 0
        spawnedThisWave = 0
    }
    
    /// Clears all active enemies without resetting wave state (used for revive)
    func clearEnemies() {
        for enemy in activeEnemies {
            enemy.removeFromParent()
        }
        enemyPool.returnAll(activeEnemies)
        activeEnemies.removeAll()
    }
}
