// DifficultyController.swift
// CoreStability
// Per-chapter difficulty scaling

import Foundation

final class DifficultyController {
    
    private(set) var currentSpawnInterval: TimeInterval
    private var elapsedTime: TimeInterval = 0
    private(set) var stabilizedCount: Int = 0
    private(set) var explodedCount: Int = 0
    
    init() {
        currentSpawnInterval = GameConstants.Difficulty.baseSpawnInterval
    }
    
    func update(deltaTime: TimeInterval) {
        elapsedTime += deltaTime
        
        // Gradually decrease spawn interval
        let acceleration = Double(GameConstants.Difficulty.spawnAcceleration) * elapsedTime
        currentSpawnInterval = max(
            GameConstants.Difficulty.minSpawnInterval,
            GameConstants.Difficulty.baseSpawnInterval - acceleration
        )
    }
    
    func onNodeStabilized() {
        stabilizedCount += 1
    }
    
    func onNodeExploded() {
        explodedCount += 1
    }
    
    func reset() {
        currentSpawnInterval = GameConstants.Difficulty.baseSpawnInterval
        elapsedTime = 0
        stabilizedCount = 0
        explodedCount = 0
    }
    
    func configureForChapter(_ config: ChapterConfiguration) {
        // Apply chapter modifiers
        currentSpawnInterval = GameConstants.Difficulty.baseSpawnInterval / Double(config.systemDecayModifier)
    }
}
