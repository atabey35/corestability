// PoolManager.swift
// Idle Tower Defense
// Generic object pool for performance optimization

import SpriteKit

protocol Poolable: AnyObject {
    func reset()
}

final class EntityPool<T: SKNode & Poolable> {
    
    private var available: [T] = []
    private let factory: () -> T
    
    var activeCount: Int = 0
    var poolSize: Int { available.count }
    
    init(initialSize: Int = 0, factory: @escaping () -> T) {
        self.factory = factory
        
        // Pre-warm
        for _ in 0..<initialSize {
            available.append(factory())
        }
    }
    
    func get() -> T {
        activeCount += 1
        
        if let item = available.popLast() {
            item.reset()
            return item
        }
        
        return factory()
    }
    
    func returnToPool(_ item: T) {
        activeCount -= 1
        item.removeFromParent()
        item.removeAllActions()
        available.append(item)
    }
    
    func returnAll(_ items: [T]) {
        for item in items {
            returnToPool(item)
        }
    }
}
