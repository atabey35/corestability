//
//  ActiveBuffsHUD.swift
//  CoreStability
//
//  Created by Agent on 2026-01-03.
//

import SpriteKit

class ActiveBuffsHUD: SKNode {
    
    private let background: SKShapeNode
    private var buffNodes: [SKNode] = []
    
    override init() {
        // Container visuals (Optional, maybe just transparent)
        background = SKShapeNode(rectOf: CGSize(width: 60, height: 300), cornerRadius: 10)
        background.fillColor = .clear // Transparent for now
        background.strokeColor = .clear
        
        super.init()
        
        addChild(background)
        
        // Listen for updates
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .buffsUpdated, object: nil)
        
        // Timer for countdown
        let wait = SKAction.wait(forDuration: 1.0)
        let update = SKAction.run { [weak self] in self?.updateTimers() }
        run(SKAction.repeatForever(SKAction.sequence([wait, update])))
        
        refresh()
        
        isUserInteractionEnabled = true
        zPosition = 200 // Ensure above other elements
    }
    
    // ... init ...

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = nodes(at: location)
        
        for node in nodes {
             // Check if node or parent has a name starting with "timerLabel_" or similar ID
             // We attached ID to timerLabel (timerLabel_ID). The icon container is the parent.
             // Let's attach ID to the parent container too for easier detection.
             if let name = node.name, name.starts(with: "buff_") {
                 let id = String(name.dropFirst(5))
                 showDescription(for: id)
                 return
             }
             if let parentName = node.parent?.name, parentName.starts(with: "buff_") {
                 let id = String(parentName.dropFirst(5))
                 showDescription(for: id)
                 return
             }
        }
    }

    private func showDescription(for id: String) {
        guard let item = InventoryManager.shared.getItemDetails(id: id) else { return }
        
        // Remove existing toast
        childNode(withName: "descToast")?.removeFromParent()
        
        // Backing
        let bg = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 8)
        bg.fillColor = SKColor(white: 0.1, alpha: 0.9)
        bg.strokeColor = .white
        bg.position = CGPoint(x: 120, y: 0) // To the right of the HUD (HUD is at x=40)
        bg.zPosition = 300
        bg.name = "descToast"
        
        // Name
        let nameLbl = SKLabelNode(text: item.name)
        nameLbl.fontName = "AvenirNext-Bold"
        nameLbl.fontSize = 14
        nameLbl.fontColor = .cyan
        nameLbl.position = CGPoint(x: 0, y: 10)
        bg.addChild(nameLbl)
        
        // Description
        let descLbl = SKLabelNode(text: item.description)
        descLbl.fontName = "AvenirNext-Regular"
        descLbl.fontSize = 12
        descLbl.fontColor = .white
        descLbl.position = CGPoint(x: 0, y: -15)
        bg.addChild(descLbl)
        
        // Add to scene or HUD? HUD is small width? HUD background is small. 
        // Adding to HUD might clip if not careful? No, SKNodes don't clip by default.
        // Position relative to the touched node would be better.
        // Let's align it with the touched node?
        // Finding the node again or just center of HUD?
        // Center of HUD is fine for now as list is vertical.
        // Actually, let's look up the node by name to position it next to it.
        if let buffNode = childNode(withName: "buff_\(id)") {
            bg.position = CGPoint(x: 80, y: buffNode.position.y)
        }
        
        addChild(bg)
        
        // Auto removal
        bg.run(SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func refresh() {
        // Clear old
        buffNodes.forEach { $0.removeFromParent() }
        buffNodes.removeAll()
        
        let buffs = InventoryManager.shared.getActiveBuffIDs()
        if buffs.isEmpty { return }
        
        let startY: CGFloat = 0
        let spacing: CGFloat = 50
        
        for (i, id) in buffs.enumerated() {
            guard let item = InventoryManager.shared.getItemDetails(id: id) else { continue }
            
            let node = SKNode()
            let y = startY - (CGFloat(i) * spacing)
            node.position = CGPoint(x: 0, y: y)
            node.name = "buff_\(id)"
            
            // Icon Background with glow
            let bg = SKShapeNode(circleOfRadius: 20)
            bg.fillColor = SKColor(red: 0.05, green: 0.08, blue: 0.12, alpha: 0.9)
            bg.strokeColor = colorForRarity(item.rarity)
            bg.lineWidth = 2
            bg.glowWidth = 3
            node.addChild(bg)
            
            // SF Symbol Icon instead of emoji
            let sfSymbolName = mapIconToSFSymbol(item.icon)
            if let iconTexture = SKTexture.fromSymbol(name: sfSymbolName, pointSize: 18) {
                let iconSprite = SKSpriteNode(texture: iconTexture)
                iconSprite.size = CGSize(width: 18, height: 18)
                iconSprite.position = CGPoint(x: 0, y: 0)
                iconSprite.color = colorForRarity(item.rarity)
                iconSprite.colorBlendFactor = 1.0
                node.addChild(iconSprite)
            }
            
            // Timer Label
            let timer = SKLabelNode(text: formatTime(InventoryManager.shared.getRemainingTime(id: id)))
            timer.fontSize = 11
            timer.fontName = "AvenirNext-Bold"
            timer.fontColor = .white
            timer.position = CGPoint(x: 0, y: -32)
            timer.name = "timerLabel_\(id)"
            node.addChild(timer)
            
            addChild(node)
            buffNodes.append(node)
        }
    }
    
    /// Maps emoji icons to SF Symbol names
    private func mapIconToSFSymbol(_ emoji: String) -> String {
        switch emoji {
        case "⚔️", "🗡️": return "flame.fill"
        case "🎯", "🔫": return "scope"
        case "💨", "⚡": return "bolt.fill"
        case "💥", "🔥": return "burst.fill"
        case "❤️", "💖": return "heart.fill"
        case "🛡️": return "shield.fill"
        case "⭐", "✨": return "star.fill"
        case "💰", "🪙": return "dollarsign.circle.fill"
        case "🔋", "🔌": return "battery.100.bolt"
        case "🧲": return "arrow.uturn.left.circle.fill"
        case "💎": return "diamond.fill"
        default: return "circle.fill"
        }
    }
    
    private func updateTimers() {
        // Efficient text update without rebuilding nodes
        for node in buffNodes {
            if let timerLabel = node.children.first(where: { $0.name?.starts(with: "timerLabel_") == true }) as? SKLabelNode,
               let name = timerLabel.name {
                let id = String(name.dropFirst(11)) // "timerLabel_".count
                timerLabel.text = formatTime(InventoryManager.shared.getRemainingTime(id: id))
            }
        }
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        if interval <= 0 { return "0s" }
        if interval > 3600 {
            let h = Int(interval) / 3600
            return "\(h)h"
        } else if interval > 60 {
            let m = Int(interval) / 60
            return "\(m)m"
        } else {
            return "\(Int(interval))s"
        }
    }
    
    private func colorForRarity(_ rarity: String) -> SKColor {
         // Simple mapping if string
         switch rarity.lowercased() {
         case "legendary": return .gold
         case "epic": return .purple
         case "rare": return .blue
         default: return .gray
         }
    }
    
    // Helper to handle mixed types (GachaRarity vs String) if needed
    private func colorForRarity(_ rarity: Any) -> SKColor {
        if let r = rarity as? String {
             switch r.lowercased() {
             case "legendary": return SKColor.yellow
             case "epic": return SKColor.purple
             case "rare": return SKColor.blue
             default: return SKColor.gray
             }
        }
        return .white
    }
}
