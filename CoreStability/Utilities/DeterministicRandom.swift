// DeterministicRandom.swift
// CoreStability

import Foundation

struct DeterministicRandom {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed == 0 ? 1 : seed
    }
    
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
    
    mutating func nextFloat() -> Float {
        return Float(next() % 1000000) / 1000000.0
    }
    
    mutating func nextCGFloat() -> CGFloat {
        return CGFloat(nextFloat())
    }
    
    mutating func nextFloat(in range: ClosedRange<Float>) -> Float {
        return range.lowerBound + nextFloat() * (range.upperBound - range.lowerBound)
    }
    
    mutating func nextCGFloat(in range: ClosedRange<CGFloat>) -> CGFloat {
        return range.lowerBound + nextCGFloat() * (range.upperBound - range.lowerBound)
    }
    
    mutating func nextBool(probability: Float = 0.5) -> Bool {
        return nextFloat() < probability
    }
}
