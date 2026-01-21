// ComboManager.swift
// CoreStability
// Manages kill combos, streak bonuses, and dopamine feedback mechanics

import Foundation
import SpriteKit

protocol ComboManagerDelegate: AnyObject {
    func onComboUpdated(count: Int, bonus: Int)
    func onComboEnded(finalCount: Int)
    func onStreakBonus(multiplier: Double, coins: Int)
    func onPerfectClear(waveNumber: Int, bonusCoins: Int)
}

// Default implementation for optional methods
extension ComboManagerDelegate {
    func onStreakBonus(multiplier: Double, coins: Int) {}
    func onPerfectClear(waveNumber: Int, bonusCoins: Int) {}
}

final class ComboManager {
    static let shared = ComboManager()
    
    // Config
    private let comboTimeout: TimeInterval = 4.0
    
    // State
    private(set) var currentCombo: Int = 0
    private(set) var currentStreak: Int = 0  // Consecutive multi-kills
    private var comboTimer: Timer?
    private var lastKillTime: TimeInterval = 0
    private var killsThisWave: Int = 0
    private var damageTakenThisWave: Bool = false
    
    weak var delegate: ComboManagerDelegate?
    
    private init() {}
    
    // MARK: - Kill Registration
    
    func addKill(at position: CGPoint, on scene: SKScene?, speed: CGFloat = 1.0, isCritical: Bool = false) {
        comboTimer?.invalidate()
        currentCombo += 1
        killsThisWave += 1
        
        // Check for multi-kill streak (kills within 1 second)
        let currentTime = Date().timeIntervalSince1970
        if currentTime - lastKillTime < 1.0 {
            currentStreak += 1
            if currentStreak >= 3 {
                triggerStreakBonus(streak: currentStreak, at: position, on: scene)
            }
        } else {
            currentStreak = 1
        }
        lastKillTime = currentTime
        
        // Show combo text
        if currentCombo > 1, let scene = scene {
            showComboText(count: currentCombo, at: position, on: scene, isCritical: isCritical)
        }
        
        // Critical hit flash
        if isCritical, let scene = scene {
            showCriticalHitEffect(at: position, on: scene)
            AudioManager.shared.playCriticalHit()
        }
        
        // Milestone rewards
        checkMilestones(count: currentCombo)
        
        // Notify delegate
        delegate?.onComboUpdated(count: currentCombo, bonus: calculateBonus(currentCombo))
        
        // Start timeout timer
        let adjustedTimeout = comboTimeout / Double(speed)
        comboTimer = Timer.scheduledTimer(withTimeInterval: adjustedTimeout, repeats: false) { [weak self] _ in
            self?.endCombo()
        }
    }
    
    private func endCombo() {
        guard currentCombo > 0 else { return }
        delegate?.onComboEnded(finalCount: currentCombo)
        currentCombo = 0
        currentStreak = 0
        comboTimer?.invalidate()
        comboTimer = nil
    }
    
    // MARK: - Wave Tracking
    
    func startNewWave() {
        killsThisWave = 0
        damageTakenThisWave = false
    }
    
    func recordDamageTaken() {
        damageTakenThisWave = true
    }
    
    func checkPerfectClear(waveNumber: Int, totalEnemies: Int, on scene: SKScene?) {
        // Perfect Clear: Killed all enemies without taking damage
        if !damageTakenThisWave && killsThisWave >= totalEnemies {
            let bonusCoins = 50 + waveNumber * 10  // Scales with wave
            delegate?.onPerfectClear(waveNumber: waveNumber, bonusCoins: bonusCoins)
            
            if let scene = scene {
                showPerfectClearEffect(on: scene, coins: bonusCoins)
            }
            
            AudioManager.shared.playPerfectClear()
            NotificationCenter.default.post(name: .perfectClear, object: nil, userInfo: ["coins": bonusCoins, "wave": waveNumber])
        }
    }
    
    // MARK: - Streak Bonuses
    
    private func triggerStreakBonus(streak: Int, at position: CGPoint, on scene: SKScene?) {
        let multiplier = 1.0 + Double(streak) * 0.1  // +10% per streak level
        let bonusCoins = streak * 5
        
        delegate?.onStreakBonus(multiplier: multiplier, coins: bonusCoins)
        
        if let scene = scene {
            showStreakText(streak: streak, at: position, on: scene)
        }
        
        NotificationCenter.default.post(name: .streakBonus, object: nil, userInfo: ["coins": bonusCoins, "streak": streak])
    }
    
    // MARK: - Milestones and Rewards
    
    private func checkMilestones(count: Int) {
        if count % 10 == 0 {
            let rawBonus = count * 2
            let bonusCoins = min(rawBonus, 200)
            NotificationCenter.default.post(name: .comboMilestone, object: nil, userInfo: ["coins": bonusCoins, "combo": count])
        }
    }
    
    private func calculateBonus(_ count: Int) -> Int {
        return count / 10
    }
    
    // MARK: - Visual Effects
    
    private func showComboText(count: Int, at position: CGPoint, on scene: SKScene, isCritical: Bool = false) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = isCritical ? "\(count)x CRITICAL!" : "\(count)x COMBO!"
        label.fontSize = 24 + CGFloat(min(count, 50) / 2)
        
        if isCritical {
            label.fontColor = .magenta
        } else if count < 10 {
            label.fontColor = .yellow
        } else if count < 30 {
            label.fontColor = .orange
        } else {
            label.fontColor = .red
        }
        
        label.position = position
        label.zPosition = 500
        scene.addChild(label)
        
        // Enhanced animation with scale pop
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let moveUp = SKAction.moveBy(x: 0, y: 60, duration: 0.8)
        let fadeOut = SKAction.fadeOut(withDuration: 0.8)
        let group = SKAction.group([moveUp, fadeOut])
        
        label.run(SKAction.sequence([scaleUp, scaleDown, group, SKAction.removeFromParent()]))
        
        // Screen shake on high combos
        if count > 20 && count % 5 == 0 {
            shakeCamera(on: scene, intensity: CGFloat(count) / 20)
        }
    }
    
    private func showCriticalHitEffect(at position: CGPoint, on scene: SKScene) {
        // Flash burst effect
        let flash = SKShapeNode(circleOfRadius: 30)
        flash.fillColor = .white
        flash.strokeColor = .clear
        flash.glowWidth = 20
        flash.position = position
        flash.zPosition = 450
        flash.alpha = 0.8
        scene.addChild(flash)
        
        let expand = SKAction.scale(to: 3.0, duration: 0.15)
        let fade = SKAction.fadeOut(withDuration: 0.15)
        flash.run(SKAction.sequence([SKAction.group([expand, fade]), SKAction.removeFromParent()]))
        
        // Particle burst
        if let emitter = SKEmitterNode(fileNamed: "Spark") {
            emitter.position = position
            emitter.zPosition = 451
            emitter.particleLifetime = 0.3
            scene.addChild(emitter)
            emitter.run(SKAction.sequence([SKAction.wait(forDuration: 0.5), SKAction.removeFromParent()]))
        }
    }
    
    private func showStreakText(streak: Int, at position: CGPoint, on scene: SKScene) {
        let streakNames = ["", "", "", "TRIPLE KILL!", "QUAD KILL!", "PENTA KILL!", "MEGA KILL!", "ULTRA KILL!", "MONSTER KILL!"]
        let text = streak < streakNames.count ? streakNames[streak] : "GODLIKE!"
        
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = 32
        label.fontColor = streak >= 5 ? .magenta : .cyan
        label.position = CGPoint(x: scene.size.width / 2, y: scene.size.height * 0.6)
        label.zPosition = 550
        label.alpha = 0
        scene.addChild(label)
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.1)
        let wait = SKAction.wait(forDuration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        label.run(SKAction.sequence([fadeIn, wait, fadeOut, SKAction.removeFromParent()]))
    }
    
    private func showPerfectClearEffect(on scene: SKScene, coins: Int) {
        // Banner
        let banner = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        banner.text = "⭐ PERFECT CLEAR! +\(coins) 💰"
        banner.fontSize = 36
        banner.fontColor = .yellow
        banner.position = CGPoint(x: scene.size.width / 2, y: scene.size.height * 0.5)
        banner.zPosition = 600
        banner.setScale(0)
        scene.addChild(banner)
        
        let scaleIn = SKAction.scale(to: 1.2, duration: 0.2)
        let scaleNormal = SKAction.scale(to: 1.0, duration: 0.1)
        let wait = SKAction.wait(forDuration: 1.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        banner.run(SKAction.sequence([scaleIn, scaleNormal, wait, fadeOut, SKAction.removeFromParent()]))
        
        // Golden particles
        let gold = SKShapeNode(circleOfRadius: 150)
        gold.fillColor = .clear
        gold.strokeColor = .yellow
        gold.glowWidth = 30
        gold.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        gold.zPosition = 590
        gold.alpha = 0.5
        scene.addChild(gold)
        
        gold.run(SKAction.sequence([
            SKAction.group([SKAction.scale(to: 2.0, duration: 0.5), SKAction.fadeOut(withDuration: 0.5)]),
            SKAction.removeFromParent()
        ]))
    }
    
    private func shakeCamera(on scene: SKScene, intensity: CGFloat) {
        guard let cam = scene.camera else { return }
        let clampedIntensity = min(intensity, 10)
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -clampedIntensity, y: 0, duration: 0.03),
            SKAction.moveBy(x: clampedIntensity * 2, y: 0, duration: 0.03),
            SKAction.moveBy(x: -clampedIntensity, y: 0, duration: 0.03)
        ])
        cam.run(shake)
    }
    
    func reset() {
        currentCombo = 0
        currentStreak = 0
        killsThisWave = 0
        damageTakenThisWave = false
        comboTimer?.invalidate()
        comboTimer = nil
    }
}

extension Notification.Name {
    static let comboMilestone = Notification.Name("comboMilestone")
    static let streakBonus = Notification.Name("streakBonus")
    static let perfectClear = Notification.Name("perfectClear")
}

