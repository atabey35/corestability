// RotationController.swift
// CoreStability
// JOYSTICK-STYLE rotation: Touch anywhere, drag to rotate
// PSYCHOLOGY: Feels like turning a knob - instant and effortless

import CoreGraphics
import QuartzCore
import SpriteKit

/// Joystick-style rotation controller
/// Touch anywhere on screen, drag horizontally = instant rotation
/// VERY HIGH SENSITIVITY for effortless control
final class RotationController {
    
    // MARK: - State
    
    private(set) var angularVelocity: CGFloat = 0
    private(set) var rotation: CGFloat = 0
    
    // MARK: - Configuration (JOYSTICK FEEL)
    
    /// VERY HIGH SENSITIVITY: Small movement = big rotation
    /// 0.08 means 50 pixels = full 90 degree rotation
    var sensitivity: CGFloat = 0.08
    
    /// Light damping
    var damping: CGFloat = 0.85
    
    /// Max velocity
    var maxVelocity: CGFloat = 30.0
    
    // MARK: - Screen
    
    var screenCenter: CGPoint = .zero
    var screenSize: CGSize = .zero
    
    // MARK: - Touch State
    
    private var isTouching: Bool = false
    private var lastTouchX: CGFloat = 0
    private var velocityBuffer: [CGFloat] = []
    
    // MARK: - Update
    
    func update(deltaTime: TimeInterval) {
        guard deltaTime > 0 && deltaTime < 0.5 else { return }
        
        if !isTouching {
            angularVelocity *= damping
            if abs(angularVelocity) < 0.01 {
                angularVelocity = 0
            }
            rotation += angularVelocity * CGFloat(deltaTime)
        }
        
        while rotation < 0 { rotation += .pi * 2 }
        while rotation >= .pi * 2 { rotation -= .pi * 2 }
    }
    
    // MARK: - Touch Input
    
    func touchBegan(at position: CGPoint) {
        isTouching = true
        lastTouchX = position.x
        velocityBuffer.removeAll()
        angularVelocity = 0
    }
    
    /// JOYSTICK ROTATION: Drag anywhere = rotate
    /// Right = clockwise, Left = counter-clockwise
    func touchMoved(to position: CGPoint) {
        guard isTouching else { return }
        
        let deltaX = position.x - lastTouchX
        
        // INSTANT ROTATION: No delay, high gain
        // Negative so right drag = clockwise visual
        let rotationDelta = -deltaX * sensitivity
        
        // Apply IMMEDIATELY
        rotation += rotationDelta
        
        // Track for momentum
        velocityBuffer.append(rotationDelta)
        if velocityBuffer.count > 3 {
            velocityBuffer.removeFirst()
        }
        
        lastTouchX = position.x
    }
    
    func touchEnded() {
        isTouching = false
        
        if velocityBuffer.count >= 2 {
            let avg = velocityBuffer.reduce(0, +) / CGFloat(velocityBuffer.count)
            angularVelocity = avg * 15
            angularVelocity = max(-maxVelocity, min(maxVelocity, angularVelocity))
        }
        
        velocityBuffer.removeAll()
    }
    
    // MARK: - Control
    
    func stop() {
        angularVelocity = 0
    }
    
    func reset() {
        rotation = 0
        angularVelocity = 0
        isTouching = false
        velocityBuffer.removeAll()
    }
    
    func applyImpulse(_ impulse: CGFloat) {
        angularVelocity += impulse
        angularVelocity = max(-maxVelocity, min(maxVelocity, angularVelocity))
    }
}
