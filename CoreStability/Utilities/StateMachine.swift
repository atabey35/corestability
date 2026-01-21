// StateMachine.swift
// CoreStability

import Foundation
import QuartzCore

class StateMachine<State: Hashable> {
    private(set) var currentState: State
    private var stateEntryTime: TimeInterval = 0
    
    var timeInCurrentState: TimeInterval {
        return CACurrentMediaTime() - stateEntryTime
    }
    
    init(initialState: State) {
        self.currentState = initialState
        self.stateEntryTime = CACurrentMediaTime()
    }
    
    @discardableResult
    func transition(to newState: State) -> Bool {
        guard newState != currentState else { return false }
        currentState = newState
        stateEntryTime = CACurrentMediaTime()
        return true
    }
    
    func forceState(_ state: State) {
        currentState = state
        stateEntryTime = CACurrentMediaTime()
    }
}

// Game states
enum GameState: Hashable {
    case starting, playing, paused, collapsing, resetting
}

// Beam states
enum BeamState: Hashable {
    case inactive, extending, locked, stabilizing, retracting
}
