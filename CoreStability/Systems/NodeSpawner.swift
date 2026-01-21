// NodeSpawner.swift
// CoreStability
// Spawns energy nodes around the core

import SpriteKit

final class NodeSpawner {
    
    weak var parentNode: SKNode?
    
    private var nodes: [EnergyNode] = []
    private var nextNodeId: Int = 0
    private var spawnTimer: TimeInterval = 0
    private var random: DeterministicRandom
    
    var corePosition: CGPoint = .zero
    var allowedNodeTypes: Set<EnergyNode.NodeType> = [.normal]
    var spawnIntervalModifier: Float = 1.0
    
    init(seed: UInt64) {
        random = DeterministicRandom(seed: seed)
    }
    
    func update(deltaTime: TimeInterval, chaosMultiplier: Float) {
        spawnTimer += deltaTime
        
        let modifiedInterval = GameConstants.Difficulty.baseSpawnInterval * Double(spawnIntervalModifier)
        
        if spawnTimer >= modifiedInterval && nodes.count < GameConstants.Performance.maxActiveNodes {
            spawnTimer = 0
            spawnNode()
        }
        
        // Update existing nodes
        for node in nodes where !node.hasExploded {
            node.update(deltaTime: deltaTime, chaosMultiplier: chaosMultiplier)
        }
        
        // Clean up
        nodes.removeAll { $0.hasExploded || $0.parent == nil }
    }
    
    private func spawnNode() {
        guard let parent = parentNode else { return }
        
        let angle = random.nextCGFloat(in: 0...(.pi * 2))
        let distance = random.nextCGFloat(in: GameConstants.Node.minSpawnDistance...GameConstants.Node.maxSpawnDistance)
        
        let x = corePosition.x + cos(angle) * distance
        let y = corePosition.y + sin(angle) * distance
        let position = CGPoint(x: x, y: y)
        
        let polarity = random.nextBool() ? 1 : -1
        
        let nodeType = selectNodeType()
        let node = createNode(type: nodeType, polarity: polarity)
        
        node.position = position
        nodes.append(node)
        parent.addChild(node)
        
        // Spawn animation
        node.setScale(0)
        node.run(SKAction.scale(to: 1.0, duration: 0.3))
    }
    
    private func selectNodeType() -> EnergyNode.NodeType {
        let types = Array(allowedNodeTypes)
        
        if types.count == 1 { return types[0] }
        
        // Weighted selection
        if allowedNodeTypes.contains(.volatile) && random.nextFloat() < GameConstants.Difficulty.volatileChance {
            return .volatile
        }
        if allowedNodeTypes.contains(.phase) && random.nextFloat() < GameConstants.Difficulty.phaseChance {
            return .phase
        }
        if allowedNodeTypes.contains(.fake) && random.nextFloat() < GameConstants.Difficulty.fakeChance {
            return .fake
        }
        
        return .normal
    }
    
    private func createNode(type: EnergyNode.NodeType, polarity: Int) -> EnergyNode {
        let id = nextNodeId
        nextNodeId += 1
        
        switch type {
        case .normal: return NormalNode(id: id, polarity: polarity)
        case .volatile: return VolatileNode(id: id, polarity: polarity)
        case .phase: return PhaseNode(id: id, polarity: polarity)
        case .fake: return FakeNode(id: id, polarity: polarity)
        }
    }
    
    func getNodes() -> [EnergyNode] { nodes }
    
    func getUnstableNodeCount() -> Int {
        return nodes.filter { !$0.isStabilizing && $0.stability < GameConstants.Node.criticalStability }.count
    }
    
    func removeAllNodes() {
        for node in nodes {
            node.removeFromParent()
        }
        nodes.removeAll()
    }
    
    func reset(seed: UInt64) {
        removeAllNodes()
        random = DeterministicRandom(seed: seed)
        spawnTimer = 0
        nextNodeId = 0
    }
}
