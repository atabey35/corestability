// InputRouter.swift
// CoreStability
// Separates rotation input from beam input
// CRITICAL: Rotation ALWAYS has priority

import CoreGraphics
import QuartzCore

/// Routes touch input - rotation is NEVER blocked
final class InputRouter {
    
    enum InputMode {
        case idle
        case rotating
        case beaming
    }
    
    private(set) var currentMode: InputMode = .idle
    
    // Rotation ALWAYS works
    var onRotationInput: ((CGPoint) -> Void)?
    
    // Beam only on tap/release
    var onBeamStart: (() -> Void)?
    var onBeamEnd: (() -> Void)?
    
    // Tracking
    private var touchStartPosition: CGPoint?
    private var touchStartTime: TimeInterval = 0
    private var lastTouchPosition: CGPoint?
    private var totalMovement: CGFloat = 0
    
    // Thresholds
    private let rotationThreshold: CGFloat = 5.0
    private let beamTapDuration: TimeInterval = 0.25
    private let beamTapMovement: CGFloat = 20.0
    
    // MARK: - Touch Events
    
    func touchBegan(at position: CGPoint) {
        touchStartPosition = position
        touchStartTime = CACurrentMediaTime()
        lastTouchPosition = position
        totalMovement = 0
        currentMode = .idle
    }
    
    func touchMoved(to position: CGPoint) {
        guard let lastPos = lastTouchPosition else {
            lastTouchPosition = position
            return
        }
        
        let dx = position.x - lastPos.x
        let dy = position.y - lastPos.y
        let movement = sqrt(dx * dx + dy * dy)
        totalMovement += movement
        
        // Rotation is ALWAYS processed
        if totalMovement > rotationThreshold {
            currentMode = .rotating
            onRotationInput?(position)
        }
        
        lastTouchPosition = position
    }
    
    func touchEnded(at position: CGPoint) {
        let duration = CACurrentMediaTime() - touchStartTime
        
        // Quick tap with minimal movement = beam action
        if duration < beamTapDuration && totalMovement < beamTapMovement {
            if currentMode == .beaming {
                onBeamEnd?()
            } else {
                onBeamStart?()
                currentMode = .beaming
            }
        }
        
        // End beam if was beaming
        if currentMode == .beaming {
            onBeamEnd?()
        }
        
        reset()
    }
    
    func touchCancelled() {
        if currentMode == .beaming {
            onBeamEnd?()
        }
        reset()
    }
    
    func reset() {
        currentMode = .idle
        touchStartPosition = nil
        lastTouchPosition = nil
        totalMovement = 0
    }
}
