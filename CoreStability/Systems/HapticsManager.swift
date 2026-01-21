// HapticsManager.swift
// CoreStability
// Haptic feedback - TUNED to avoid overwhelming
// PSYCHOLOGY: Warning ≠ punishment

import UIKit

final class HapticsManager {
    
    static let shared = HapticsManager()
    
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    
    private var isEnabled: Bool = true
    private var lastHapticTime: TimeInterval = 0
    private let minimumInterval: TimeInterval = 0.1
    
    // Critical cooldown to prevent spam
    private var lastCriticalTime: TimeInterval = 0
    private let criticalCooldown: TimeInterval = 2.0
    
    private init() {
        prepareAll()
    }
    
    private func prepareAll() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        notification.prepare()
    }
    
    // MARK: - Events
    
    func onStabilization() {
        guard canTrigger() else { return }
        lightImpact.impactOccurred(intensity: 0.6)
        recordHaptic()
    }
    
    func onBeamLocked() {
        guard canTrigger() else { return }
        lightImpact.impactOccurred(intensity: 0.4)
        recordHaptic()
    }
    
    func onExplosion() {
        guard canTrigger() else { return }
        heavyImpact.impactOccurred(intensity: 1.0)
        recordHaptic()
    }
    
    /// Critical state - ONE controlled pulse, not spam
    func onCriticalState() {
        guard isEnabled else { return }
        
        let now = CACurrentMediaTime()
        if now - lastCriticalTime < criticalCooldown { return }
        
        lastCriticalTime = now
        mediumImpact.impactOccurred(intensity: 0.7)
        prepareAll()
    }
    
    func onDeath() {
        guard canTrigger() else { return }
        heavyImpact.impactOccurred(intensity: 1.0)
        recordHaptic()
    }
    
    func onChapterComplete() {
        guard canTrigger() else { return }
        notification.notificationOccurred(.success)
        recordHaptic()
    }
    
    func onVictory() {
        guard isEnabled else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) { [weak self] in
            self?.lightImpact.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.mediumImpact.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.heavyImpact.impactOccurred()
        }
    }
    
    private func canTrigger() -> Bool {
        guard isEnabled else { return false }
        return CACurrentMediaTime() - lastHapticTime >= minimumInterval
    }
    
    private func recordHaptic() {
        lastHapticTime = CACurrentMediaTime()
        prepareAll()
    }
}
