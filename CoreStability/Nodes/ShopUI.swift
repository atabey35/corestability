// ShopUI.swift
// CoreStability
// Professional Arcade UI for Market & Vault

import SpriteKit

class ShopUI: SKNode {
    
    // MARK: - Properties
    
    private let containerNode: SKNode
    private let width: CGFloat
    private let height: CGFloat
    
    // Tab Content Containers
    private var gachaContainer: SKNode?
    private var inventoryContainer: SKNode?
    private var iapContainer: SKNode?
    private var armoryContainer: SKNode?
    
    // Texture Cache
    private var textureCache: [String: SKTexture] = [:]
    
    // Callbacks
    var onClose: (() -> Void)?
    
    // MARK: - Init
    
    init(size: CGSize) {
        self.width = size.width * 0.92
        self.height = size.height * 0.88
        self.containerNode = SKNode()
        
        super.init()
        
        setupDimmedBackground()
        setupGlassmorphismPanel()
        setupHeader()
        setupTabBar()
        showGacha() // Default tab
        
        isUserInteractionEnabled = true
        zPosition = 1000
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Optimization Helpers
    
    private func getIconTexture(name: String) -> SKTexture? {
        // 1. Check Cache
        if let cached = textureCache[name] {
            return cached
        }
        
        // 2. Try Asset Catalog (Explicit check mostly for iap_ and skill_ prefixes)
        if name.hasPrefix("iap_") || name.hasPrefix("skill_") || name.hasPrefix("weapon_") {
             let texture = SKTexture(imageNamed: name)
             // Heavy operation: checking .size() forces a load
             if texture.size() != .zero {
                 textureCache[name] = texture
                 return texture
             }
        }
        
        // 3. Try SF Symbol (Not cached as they are system generated, but could be)
        if let symbolTex = SKTexture.fromSymbol(name: name, pointSize: 40) {
            return symbolTex
        }
        
        return nil
    }

    // MARK: - Glassmorphism Panel Setup
    
    private func setupDimmedBackground() {
        let dimmer = SKShapeNode(rectOf: CGSize(width: 3000, height: 3000))
        dimmer.fillColor = SKColor.black.withAlphaComponent(0.7)
        dimmer.strokeColor = .clear
        dimmer.name = "shopDimmer"
        dimmer.zPosition = -1
        addChild(dimmer)
    }
    
    private func setupGlassmorphismPanel() {
        // Outer glow layer
        let glowLayer = SKShapeNode(rectOf: CGSize(width: width + 8, height: height + 8), cornerRadius: 22)
        glowLayer.fillColor = .clear
        glowLayer.strokeColor = SKColor.cyan.withAlphaComponent(0.4)
        glowLayer.lineWidth = 3
        glowLayer.glowWidth = 15
        glowLayer.zPosition = 0
        addChild(glowLayer)
        
        // Main panel - frosted glass effect
        let mainPanel = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 18)
        mainPanel.fillColor = SKColor(red: 0.03, green: 0.05, blue: 0.10, alpha: 0.95)
        mainPanel.strokeColor = SKColor.cyan.withAlphaComponent(0.6)
        mainPanel.lineWidth = 2
        mainPanel.name = "mainPanel"
        mainPanel.zPosition = 1
        addChild(mainPanel)
        
        containerNode.zPosition = 2
        addChild(containerNode)
    }
    
    private func setupHeader() {
        // Title with icon
        // Title with icon
        let titleContainer = SKNode()
        titleContainer.position = CGPoint(x: 0, y: height/2 - 45)
        containerNode.addChild(titleContainer)
        
        // Calculate total width to center it
        let titleText = "MARKET & VAULT"
        let font = UIFont(name: "AvenirNext-Heavy", size: 24) ?? UIFont.systemFont(ofSize: 24, weight: .heavy) // Reduced 28->24
        let textWidth = (titleText as NSString).size(withAttributes: [.font: font]).width
        let iconSize: CGFloat = 24
        let spacing: CGFloat = 10
        let totalContentWidth = iconSize + spacing + textWidth
        
        let startX = -totalContentWidth / 2
        
        if let iconTexture = SKTexture.fromSymbol(name: "storefront.fill", pointSize: 24) {
            let icon = SKSpriteNode(texture: iconTexture)
            icon.size = CGSize(width: 24, height: 24)
            icon.position = CGPoint(x: startX + iconSize/2, y: 0)
            icon.color = .cyan
            icon.colorBlendFactor = 1.0
            titleContainer.addChild(icon)
        }
        
        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = titleText
        title.fontSize = 24
        title.fontColor = .cyan
        title.horizontalAlignmentMode = .left
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: startX + iconSize + spacing, y: 0)
        titleContainer.addChild(title)
        
        // Animated subtitle line
        let subtitleLine = SKShapeNode(rectOf: CGSize(width: width - 60, height: 1))
        subtitleLine.fillColor = SKColor.cyan.withAlphaComponent(0.3)
        subtitleLine.strokeColor = .clear
        subtitleLine.position = CGPoint(x: 0, y: height/2 - 70)
        containerNode.addChild(subtitleLine)
        
        // Close Button - Arcade style
        let closeBtn = createArcadeButton(size: CGSize(width: 40, height: 40), cornerRadius: 20, color: .red)
        // Move further right and up
        closeBtn.position = CGPoint(x: width/2 - 25, y: height/2 - 25) 
        closeBtn.name = "shopClose"
        closeBtn.zPosition = 100 // Ensure on top
        containerNode.addChild(closeBtn)
        
        if let xTexture = SKTexture.fromSymbol(name: "xmark", pointSize: 18) {
            let xIcon = SKSpriteNode(texture: xTexture)
            xIcon.size = CGSize(width: 18, height: 18)
            xIcon.color = .white
            xIcon.colorBlendFactor = 1.0
            closeBtn.addChild(xIcon)
        }
    }
    
    private func setupTabBar() {
        let tabY = height/2 - 105
        let tabWidth = (width - 40) / 4 // Changed to 4 items
        
        let tabs: [(String, String, String)] = [
            ("PERK VAULT".localized, "sparkles", "tab_gacha"),
            ("ARMORY".localized, "shield.fill", "tab_armory"),
            ("BAG".localized, "bag.fill", "tab_inventory"),
            ("GEM SHOP".localized, "diamond.fill", "tab_iap")
        ]
        
        for (index, tab) in tabs.enumerated() {
            let xPos = -width/2 + 20 + tabWidth/2 + CGFloat(index) * tabWidth + CGFloat(index) * 5
            let isSelected = index == 0
            
            let tabBtn = createTabButton(
                text: tab.0,
                iconName: tab.1,
                name: tab.2,
                width: tabWidth,
                selected: isSelected
            )
            tabBtn.position = CGPoint(x: xPos, y: tabY)
            containerNode.addChild(tabBtn)
        }
    }
    
    private func createTabButton(text: String, iconName: String, name: String, width: CGFloat, selected: Bool) -> SKNode {
        let container = SKNode()
        container.name = name
        
        // Background
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: 45), cornerRadius: 10)
        bg.fillColor = selected ? SKColor.cyan.withAlphaComponent(0.3) : SKColor(white: 0.15, alpha: 0.8)
        bg.strokeColor = selected ? .cyan : SKColor(white: 0.3, alpha: 0.5)
        bg.lineWidth = selected ? 2 : 1
        if selected { bg.glowWidth = 5 }
        bg.name = name
        container.addChild(bg)
        
        // Content Layout
        let iconSize: CGFloat = 14
        let spacing: CGFloat = 6
        
        let font = UIFont(name: "AvenirNext-Bold", size: 11) ?? UIFont.boldSystemFont(ofSize: 11)
        let textWidth = (text as NSString).size(withAttributes: [.font: font]).width
        let totalContentWidth = iconSize + spacing + textWidth
        let startX = -totalContentWidth / 2
        
        // Icon
        if let iconTexture = SKTexture.fromSymbol(name: iconName, pointSize: 14) {
            let icon = SKSpriteNode(texture: iconTexture)
            icon.size = CGSize(width: 14, height: 14)
            icon.position = CGPoint(x: startX + iconSize/2, y: 0)
            icon.color = selected ? .cyan : .gray
            icon.colorBlendFactor = 1.0
            container.addChild(icon)
        }
        
        // Label
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = text
        label.fontSize = 11
        label.fontColor = selected ? .cyan : .gray
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(x: startX + iconSize + spacing, y: 0)
        label.name = "label"
        container.addChild(label)
        
        return container
    }
    
    // MARK: - Gacha View (Perk Vault)
    
    public func showGacha() {
        // Cache Check
        if let gacha = gachaContainer {
            if !gacha.isHidden { return } // Already showing
            
            clearContent() // Hide others
            updateTabs(selected: "tab_gacha")
            gacha.isHidden = false
            return
        }
        
        // First Time Load
        clearContent()
        updateTabs(selected: "tab_gacha")
        
        let container = SKNode()
        container.position = CGPoint(x: 0, y: -30)
        gachaContainer = container
        containerNode.addChild(container)
        
        // Featured Banner with glow
        let bannerNode = createGlassmorphismCard(
            width: width - 50,
            height: 140,
            glowColor: SKColor.purple
        )
        bannerNode.position = CGPoint(x: 0, y: 110)
        container.addChild(bannerNode)
        
        // Banner icon
        if let starTexture = SKTexture.fromSymbol(name: "star.circle.fill", pointSize: 40) {
            let starIcon = SKSpriteNode(texture: starTexture)
            starIcon.size = CGSize(width: 50, height: 50)
            starIcon.position = CGPoint(x: -width/2 + 70, y: -10)
            starIcon.color = .yellow
            starIcon.colorBlendFactor = 1.0
            bannerNode.addChild(starIcon)
            
            // Pulse animation
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.15, duration: 0.8),
                SKAction.scale(to: 1.0, duration: 0.8)
            ])
            starIcon.run(SKAction.repeatForever(pulse))
        }
        
        let bannerTitle = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        bannerTitle.text = "LEGENDARY PERKS".localized
        bannerTitle.fontSize = 24
        bannerTitle.fontColor = .yellow
        bannerTitle.position = CGPoint(x: 20, y: 15)
        bannerNode.addChild(bannerTitle)
        
        let bannerSub = SKLabelNode(fontNamed: "AvenirNext-Medium")
        bannerSub.text = "Guaranteed Legendary every 50 pulls!".localized
        bannerSub.fontSize = 13
        bannerSub.fontColor = SKColor(white: 0.8, alpha: 1)
        bannerSub.position = CGPoint(x: 20, y: -15)
        bannerNode.addChild(bannerSub)
        
        // Pity Counter
        let pity = GachaManager.shared.pullsUntilPity
        let pityNode = createInfoBadge(text: String(format: NSLocalizedString("Pity: %d pulls left", comment: ""), pity), iconName: "hourglass")
        pityNode.position = CGPoint(x: 0, y: 20)
        container.addChild(pityNode)
        
        // IMPORTANT: Drop Rates Panel - ABOVE pull buttons (Apple Guideline 3.1.1 compliance)
        let ratesPanel = createDropRatesPanel()
        ratesPanel.position = CGPoint(x: 0, y: -50)
        container.addChild(ratesPanel)
        
        // Pull Buttons - Side by side (below rates panel)
        let btn1 = createPullButton(
            title: "PULL 1x".localized,
            cost: "100",
            iconName: "diamond.fill",
            color: SKColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1),
            width: (width - 70) / 2
        )
        btn1.position = CGPoint(x: -width/4 + 10, y: -150)
        btn1.name = "pull_1"
        container.addChild(btn1)
        
        let btn10 = createPullButton(
            title: "PULL 10x".localized,
            cost: "900 (10% OFF)",
            iconName: "diamond.fill",
            color: SKColor(red: 0.5, green: 0.2, blue: 0.6, alpha: 1),
            width: (width - 70) / 2
        )
        btn10.position = CGPoint(x: width/4 - 10, y: -150)
        btn10.name = "pull_10"
        container.addChild(btn10)
    }
    
    private func createPullButton(title: String, cost: String, iconName: String, color: SKColor, width: CGFloat) -> SKNode {
        let container = SKNode()
        
        // Glow
        let glow = SKShapeNode(rectOf: CGSize(width: width + 4, height: 74), cornerRadius: 14)
        glow.fillColor = .clear
        glow.strokeColor = color.withAlphaComponent(0.5)
        glow.lineWidth = 2
        glow.glowWidth = 8
        container.addChild(glow)
        
        // Background
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: 70), cornerRadius: 12)
        bg.fillColor = color
        bg.strokeColor = color.lighter(by: 0.3)
        bg.lineWidth = 2
        container.addChild(bg)
        
        // Title
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleLabel.text = title
        titleLabel.fontSize = 18
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: 15) // Expanded spacing
        container.addChild(titleLabel)
        
        // Cost with icon - adjusted positions to avoid overlap
        let costWidth = cost.count * 7 // Estimate text width
        let iconX = -CGFloat(costWidth) / 2 - 10
        
        if let iconTexture = SKTexture.fromSymbol(name: iconName, pointSize: 14) {
            let icon = SKSpriteNode(texture: iconTexture)
            icon.size = CGSize(width: 14, height: 14)
            icon.position = CGPoint(x: iconX, y: -18) 
            icon.color = .cyan
            icon.colorBlendFactor = 1.0
            container.addChild(icon)
        }
        
        let costLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        costLabel.text = cost
        costLabel.fontSize = 12
        costLabel.fontColor = .cyan
        costLabel.horizontalAlignmentMode = .left
        costLabel.position = CGPoint(x: iconX + 18, y: -23)
        container.addChild(costLabel)
        
        return container
    }
    
    private func createInfoBadge(text: String, iconName: String) -> SKNode {
        let container = SKNode()
        
        let bg = SKShapeNode(rectOf: CGSize(width: 180, height: 30), cornerRadius: 15)
        bg.fillColor = SKColor(white: 0.15, alpha: 0.9)
        bg.strokeColor = SKColor(white: 0.3, alpha: 0.5)
        bg.lineWidth = 1
        container.addChild(bg)
        
        if let iconTexture = SKTexture.fromSymbol(name: iconName, pointSize: 12) {
            let icon = SKSpriteNode(texture: iconTexture)
            icon.size = CGSize(width: 12, height: 12)
            icon.position = CGPoint(x: -75, y: 0)
            icon.color = .gray
            icon.colorBlendFactor = 1.0
            container.addChild(icon)
        }
        
        let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
        label.text = text
        label.fontSize = 12
        label.fontColor = .gray
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 5, y: 0)
        container.addChild(label)
        
        return container
    }
    
    private func createRatesBadge() -> SKNode {
        let container = SKNode()
        
        let rates = [
            ("Common", "55%", SKColor.gray),
            ("Rare", "30%", SKColor.blue),
            ("Epic", "12%", SKColor.purple),
            ("Legendary", "3%", SKColor.yellow)
        ]
        
        let totalWidth = CGFloat(rates.count) * 70 + CGFloat(rates.count - 1) * 10
        var xPos = -totalWidth / 2 + 35
        
        for rate in rates {
            let badge = SKShapeNode(rectOf: CGSize(width: 70, height: 24), cornerRadius: 12)
            badge.fillColor = rate.2.withAlphaComponent(0.2)
            badge.strokeColor = rate.2.withAlphaComponent(0.5)
            badge.lineWidth = 1
            badge.position = CGPoint(x: xPos, y: 0)
            container.addChild(badge)
            
            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            label.text = rate.1
            label.fontSize = 10
            label.fontColor = rate.2
            label.verticalAlignmentMode = .center
            badge.addChild(label)
            
            xPos += 80
        }
        
        return container
    }
    
    /// Creates a prominent drop rates panel for Apple Guideline 3.1.1 compliance.
    /// This panel is displayed ABOVE the pull buttons to ensure users see probabilities before purchasing.
    private func createDropRatesPanel() -> SKNode {
        let container = SKNode()
        let panelWidth = width - 60
        let panelHeight: CGFloat = 70
        
        // Glassmorphic background panel
        let bgPanel = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 12)
        bgPanel.fillColor = SKColor(red: 0.05, green: 0.08, blue: 0.15, alpha: 0.95)
        bgPanel.strokeColor = SKColor.cyan.withAlphaComponent(0.4)
        bgPanel.lineWidth = 1.5
        bgPanel.glowWidth = 3
        container.addChild(bgPanel)
        
        // Title: "DROP RATES" with chart icon
        let titleY: CGFloat = 18
        
        if let chartTexture = SKTexture.fromSymbol(name: "chart.bar.fill", pointSize: 14) {
            let chartIcon = SKSpriteNode(texture: chartTexture)
            chartIcon.size = CGSize(width: 14, height: 14)
            chartIcon.position = CGPoint(x: -panelWidth/2 + 25, y: titleY)
            chartIcon.color = .cyan
            chartIcon.colorBlendFactor = 1.0
            container.addChild(chartIcon)
        }
        
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleLabel.text = "DROP RATES".localized
        titleLabel.fontSize = 12
        titleLabel.fontColor = .cyan
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: -panelWidth/2 + 45, y: titleY)
        container.addChild(titleLabel)
        
        // Drop Rates - Each rarity with name and percentage
        let rates: [(String, String, SKColor)] = [
            ("Common".localized, "55%", SKColor.gray),
            ("Rare".localized, "30%", SKColor.blue),
            ("Epic".localized, "12%", SKColor.purple),
            ("Legendary".localized, "3%", SKColor.yellow)
        ]
        
        let rateY: CGFloat = -12
        let rateSpacing: CGFloat = (panelWidth - 40) / CGFloat(rates.count)
        var xPos = -panelWidth/2 + 40
        
        for rate in rates {
            // Rarity colored dot
            let dot = SKShapeNode(circleOfRadius: 5)
            dot.fillColor = rate.2
            dot.strokeColor = rate.2.lighter(by: 0.3)
            dot.lineWidth = 1
            dot.position = CGPoint(x: xPos, y: rateY)
            container.addChild(dot)
            
            // Rate percentage (bold)
            let rateLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            rateLabel.text = rate.1
            rateLabel.fontSize = 14
            rateLabel.fontColor = rate.2
            rateLabel.horizontalAlignmentMode = .left
            rateLabel.verticalAlignmentMode = .center
            rateLabel.position = CGPoint(x: xPos + 12, y: rateY)
            container.addChild(rateLabel)
            
            // Rarity name (smaller, below)
            let nameLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
            nameLabel.text = rate.0
            nameLabel.fontSize = 8
            nameLabel.fontColor = SKColor(white: 0.6, alpha: 1)
            nameLabel.horizontalAlignmentMode = .left
            nameLabel.verticalAlignmentMode = .center
            nameLabel.position = CGPoint(x: xPos + 12, y: rateY - 12)
            container.addChild(nameLabel)
            
            xPos += rateSpacing
        }
        
        return container
    }
    
    // MARK: - Inventory View (BAG) - Grid Layout
    
    // MARK: - Inventory View (BAG) - Grid Layout with Pagination
    
    // Pagination State
    private var currentInventoryPage: Int = 0
    private var armoryPage: Int = 0
    private let itemsPerPage: Int = 8
    
    public func showInventory() {
        // Cache Check
        if let inv = inventoryContainer {
            inv.removeFromParent()
            inventoryContainer = nil
        }
        
        clearContent()
        updateTabs(selected: "tab_inventory")
        
        let container = SKNode()
        container.position = CGPoint(x: 0, y: -30)
        inventoryContainer = container
        containerNode.addChild(container)
        
        let allItems = InventoryManager.shared.inventory.sorted(by: { $0.key < $1.key }) // Consistent order
        
        if allItems.isEmpty {
            // ... Empty State (Keep existing code)
            let emptyContainer = SKNode()
            emptyContainer.position = CGPoint(x: 0, y: 0)
            container.addChild(emptyContainer)
            
            if let iconTexture = SKTexture.fromSymbol(name: "bag.badge.questionmark", pointSize: 50) {
                let icon = SKSpriteNode(texture: iconTexture)
                icon.size = CGSize(width: 50, height: 50)
                icon.position = CGPoint(x: 0, y: 30)
                icon.color = .gray
                icon.colorBlendFactor = 1.0
                emptyContainer.addChild(icon)
            }
            
            let emptyLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            emptyLabel.text = "Your bag is empty"
            emptyLabel.fontSize = 18
            emptyLabel.fontColor = .gray
            emptyLabel.position = CGPoint(x: 0, y: -20)
            emptyContainer.addChild(emptyLabel)
            
            let subLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
            subLabel.text = "Try your luck at Perk Vault!"
            subLabel.fontSize = 14
            subLabel.fontColor = SKColor(white: 0.5, alpha: 1)
            subLabel.position = CGPoint(x: 0, y: -45)
            emptyContainer.addChild(subLabel)
            return
        }
        
        // Pagination Logic
        let totalPages = max(1, Int(ceil(Double(allItems.count) / Double(itemsPerPage))))
        if currentInventoryPage >= totalPages { currentInventoryPage = totalPages - 1 }
        
        let startIndex = currentInventoryPage * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, allItems.count)
        let pageItems = Array(allItems[startIndex..<endIndex])
        
        // Grid Layout: 2 columns
        let cardWidth: CGFloat = (width - 70) / 2
        let cardHeight: CGFloat = 100 // Reduced slightly
        let horizontalSpacing: CGFloat = 15
        let verticalSpacing: CGFloat = 10
        let startY: CGFloat = 130
        
        for (index, item) in pageItems.enumerated() {
            guard let details = InventoryManager.shared.getItemDetails(id: item.key) else { continue }
            
            let col = index % 2
            let row = index / 2
            
            let xPos = (col == 0 ? -1 : 1) * (cardWidth/2 + horizontalSpacing/2)
            let yPos = startY - CGFloat(row) * (cardHeight + verticalSpacing)
            
            let itemCard = createItemCard(
                id: item.key,
                name: details.name,
                description: details.description,
                icon: details.icon,
                rarity: details.rarity,
                count: item.value,
                width: cardWidth,
                height: cardHeight
            )
            itemCard.position = CGPoint(x: xPos, y: yPos)
            container.addChild(itemCard)
        }
        
        // Pagination Controls
        if totalPages > 1 {
            let controlsY: CGFloat = -height/2 + 80
            
            // Page Indicator
            let pageLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
            pageLbl.text = "Page \(currentInventoryPage + 1) / \(totalPages)"
            pageLbl.fontSize = 14
            pageLbl.fontColor = .cyan
            pageLbl.position = CGPoint(x: 0, y: controlsY)
            container.addChild(pageLbl)
            
            // Prev Button
            if currentInventoryPage > 0 {
                let prevBtn = createPageButton(text: "< PREV", name: "bag_prev_page")
                prevBtn.position = CGPoint(x: -80, y: controlsY + 5)
                container.addChild(prevBtn)
            }
            
            // Next Button
            if currentInventoryPage < totalPages - 1 {
                let nextBtn = createPageButton(text: "NEXT >", name: "bag_next_page")
                nextBtn.position = CGPoint(x: 80, y: controlsY + 5)
                container.addChild(nextBtn)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createItemCard(id: String, name: String, description: String, icon: String, rarity: String, count: Int, width: CGFloat, height: CGFloat) -> SKNode {
        let container = SKNode()
        
        let rarityColor = colorForRarity(rarity)
        
        // Card background with glow
        let glow = SKShapeNode(rectOf: CGSize(width: width + 4, height: height + 4), cornerRadius: 14)
        glow.fillColor = .clear
        glow.strokeColor = rarityColor.withAlphaComponent(0.4)
        glow.lineWidth = 2
        glow.glowWidth = 6
        container.addChild(glow)
        
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 12)
        bg.fillColor = SKColor(red: 0.08, green: 0.10, blue: 0.15, alpha: 0.95)
        bg.strokeColor = rarityColor.withAlphaComponent(0.6)
        bg.lineWidth = 1.5
        container.addChild(bg)
        
        // Icon (SF Symbol based on emoji mapping)
        let sfSymbolName = mapIconToSFSymbol(icon)
        if let iconTexture = SKTexture.fromSymbol(name: sfSymbolName, pointSize: 24) {
            let iconSprite = SKSpriteNode(texture: iconTexture)
            iconSprite.size = CGSize(width: 24, height: 24)
            // Move icon slightly left/up to make room
            iconSprite.position = CGPoint(x: -width/2 + 30, y: 20)
            iconSprite.color = rarityColor
            iconSprite.colorBlendFactor = 1.0
            container.addChild(iconSprite)
        }
        
        // Name (Multiline Fix)
        let nameLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        nameLabel.text = name
        nameLabel.fontSize = 11 // Slightly smaller to fit "Minor Strength Potion"
        nameLabel.fontColor = .white
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.verticalAlignmentMode = .center
        nameLabel.numberOfLines = 2
        nameLabel.preferredMaxLayoutWidth = width - 65
        nameLabel.position = CGPoint(x: -width/2 + 55, y: 20)
        container.addChild(nameLabel)
        
        // Count badge
        let countBadge = SKShapeNode(circleOfRadius: 10)
        countBadge.fillColor = rarityColor.withAlphaComponent(0.3)
        countBadge.strokeColor = rarityColor
        countBadge.lineWidth = 1
        countBadge.position = CGPoint(x: width/2 - 18, y: 25)
        container.addChild(countBadge)
        
        let countLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        countLabel.text = "x\(count)"
        countLabel.fontSize = 9
        countLabel.fontColor = .white
        countLabel.verticalAlignmentMode = .center
        countBadge.addChild(countLabel)
        
        // Use button at bottom of card
        let buttonHeight: CGFloat = 28
        let useBtn = createArcadeButton(size: CGSize(width: width - 20, height: buttonHeight), cornerRadius: 8, color: .cyan)
        // Ensure button is low enough
        useBtn.position = CGPoint(x: 0, y: -height/2 + 20)
        useBtn.name = "use_\(id)"
        container.addChild(useBtn)
        
        let useLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        useLabel.text = "USE"
        useLabel.fontSize = 11
        useLabel.fontColor = .black
        useLabel.verticalAlignmentMode = .center
        useBtn.addChild(useLabel)
        
        return container
    }
    
    // MARK: - Armory (Weapon Shop)
    
    // MARK: - Armory (Weapon Shop & Upgrades)
    
    // Page 0: Weapons (Pistol, Shotgun, Railgun, Blade, Turrets)
    // Page 1: Upgrades (Damage, FireRate, Range, HP, Defense)
    
    public func showArmory() {
        // Cache Check
        if let armory = armoryContainer {
             // If we are just switching tabs back to armory, we might want to keep it.
             // But if we called showArmory() due to pagination, we MUST rebuild.
             // Simple fix: Remove the old container if it exists so we rebuild.
             armory.removeFromParent()
             armoryContainer = nil
        }
        
        clearContent()
        updateTabs(selected: "tab_armory")
        
        let container = SKNode()
        container.position = CGPoint(x: 0, y: -30)
        armoryContainer = container
        containerNode.addChild(container)
        
        // Title (Moved Up Higher)
        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = "ADVANCED WEAPONRY".localized
        title.fontSize = 22
        title.fontColor = .cyan
        title.position = CGPoint(x: 0, y: 210)
        container.addChild(title)
        
        // Collect All Items
        var allItems: [Any] = []
        
        // 1. Pistol (Default) - Now Equippable Logic
        allItems.append(("Pistol".localized, "Default Sidearm".localized, "weapon_pistol"))
        
        // 2. Shotgun & Railgun
        allItems.append((WeaponType.shotgun, "Shotgun".localized, IAPProduct.shotgunRental, IAPProduct.shotgunLifetime, "iap_weapon_shotgun"))
        allItems.append((WeaponType.railgun, "Railgun".localized, IAPProduct.railgunRental, IAPProduct.railgunLifetime, "iap_weapon_railgun"))
        
        // 3. Spinning Blade
        allItems.append(("Spinning Blade".localized, "Orbital Weapon".localized, IAPProduct.bladeWeapon, "iap_weapon_blade"))
        
        // 4. All Turret Slots (1-4) based on unlock status
        let unlockedSlots = UpgradeManager.shared.turretSlotsUnlocked
        let slotProducts: [Int: IAPProduct] = [
            1: .turretSlot1,
            2: .turretSlot2,
            3: .turretSlot3,
            4: .turretSlot4
        ]
        for slot in 1...4 {
            let slotName = String(format: NSLocalizedString("Turret Slot %d", comment: ""), slot)
            let slotImage = "iap_slot_\(slot)"
            if slot <= unlockedSlots {
                allItems.append((slotName, "Unlocked!".localized, slotImage))
            } else if let product = slotProducts[slot] {
                allItems.append((slotName, "Deploy an extra turret!".localized, product, slotImage))
            }
        }

        // Pagination Logic
        let itemsPerPage = 3
        let totalPages = Int(ceil(Double(allItems.count) / Double(itemsPerPage)))
        armoryPage = max(0, min(armoryPage, totalPages - 1)) // Clamp
        
        let startIndex = armoryPage * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, allItems.count)
        let pageItems = Array(allItems[startIndex..<endIndex])
        
        let startY: CGFloat = 120
        let spacing: CGFloat = 145 
        
        for (index, item) in pageItems.enumerated() {
            let yPos = startY - CGFloat(index) * spacing
            var card: SKNode = SKNode()
            
            if let pistolData = item as? (String, String, String) {
                if pistolData.0 == "Pistol" {
                    // Special Pistol Card
                    card = createWeaponCard(type: .pistol, name: "Pistol", rentalProd: nil, lifeProd: nil, icon: "weapon_pistol", width: width - 40, height: 130)
                } else {
                     // Maxed Turret
                    card = createStaticOwnedCard(name: pistolData.0, desc: pistolData.1, icon: pistolData.2, width: width - 40, height: 130)
                }
            }
            else if let wData = item as? (WeaponType, String, IAPProduct, IAPProduct, String) {
                // Rental Weapon
                card = createWeaponCard(
                    type: wData.0,
                    name: wData.1,
                    rentalProd: wData.2,
                    lifeProd: wData.3,
                    icon: wData.4,
                    width: width - 40,
                    height: 130
                )
            }
            else if let tData = item as? (String, String, IAPProduct, String) {
                // Unlock Card
                let isBlade = tData.0 == "Spinning Blade"
                let isBladeOwned = isBlade && UpgradeManager.shared.isBladeUnlocked
                if isBladeOwned {
                    card = createStaticOwnedCard(name: tData.0, desc: "Experimental Weapon", icon: tData.3, width: width - 40, height: 130)
                } else {
                    card = createUnlockCard(name: tData.0, desc: tData.1, product: tData.2, icon: tData.3, width: width - 40, height: 130, isFree: false)
                }
            }
            
            card.position = CGPoint(x: 0, y: yPos)
            container.addChild(card)
        }
        
        // Navigation Buttons
        setupArmoryNavigation(container: container, totalPages: totalPages)
    }
    
    private func setupArmoryNavigation(container: SKNode, totalPages: Int) {
        let yPos: CGFloat = -height/2 + 60
        
        if armoryPage > 0 {
            let prevBtn = createPageButton(text: "PREV", name: "armory_prev_page")
            prevBtn.position = CGPoint(x: -80, y: yPos)
            container.addChild(prevBtn)
        }
        
        if armoryPage < totalPages - 1 {
            let nextBtn = createPageButton(text: "NEXT", name: "armory_next_page")
            nextBtn.position = CGPoint(x: 80, y: yPos)
            container.addChild(nextBtn)
        }
        
        // Page Indicator
        let pageLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        pageLabel.text = "\(armoryPage + 1) / \(totalPages)"
        pageLabel.fontSize = 14
        pageLabel.fontColor = .gray
        pageLabel.position = CGPoint(x: 0, y: yPos - 5)
        container.addChild(pageLabel)
    }
    
    private func createWeaponCard(type: WeaponType, name: String, rentalProd: IAPProduct?, lifeProd: IAPProduct?, icon: String, width: CGFloat, height: CGFloat) -> SKNode {
        let container = SKNode()
        
        // Special case for pistol which is always unlocked
        let isDefault = (type == .pistol)
        var isUnlocked = UpgradeManager.shared.unlockedWeapons.contains(type)
        if isDefault { isUnlocked = true } // Pistol always owned
        
        let isRented = UpgradeManager.shared.rentedWeapons[type] != nil && UpgradeManager.shared.rentedWeapons[type]! > Date()
        
        // Background
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 16)
        bg.fillColor = SKColor(red: 0.1, green: 0.12, blue: 0.2, alpha: 0.95)
        bg.strokeColor = isUnlocked ? .green : (isRented ? .yellow : .cyan)
        bg.lineWidth = 2
        container.addChild(bg)
        
        // Icon
        let iconNode: SKSpriteNode
        if let texture = getIconTexture(name: icon) {
             iconNode = SKSpriteNode(texture: texture)
             // Heuristic: If it's a large asset (not symbol), size it up
             if icon.hasPrefix("iap_") || icon.hasPrefix("weapon_") {
                 iconNode.size = CGSize(width: 80, height: 80)
                 iconNode.position = CGPoint(x: -width/2 + 50, y: 15)
             } else {
                 // Symbol
                 iconNode.size = CGSize(width: 50, height: 50)
                 iconNode.position = CGPoint(x: -width/2 + 50, y: 20)
                 iconNode.color = isUnlocked ? .green : .cyan
                 iconNode.colorBlendFactor = 1.0
             }
        } else {
             iconNode = SKSpriteNode(color: .gray, size: CGSize(width: 50, height: 50))
             iconNode.position = CGPoint(x: -width/2 + 50, y: 20)
        }
        container.addChild(iconNode)
        
        // Name
        let nameLbl = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        nameLbl.text = name
        nameLbl.fontSize = 20
        nameLbl.fontColor = .white
        nameLbl.horizontalAlignmentMode = .left
        nameLbl.position = CGPoint(x: -width/2 + 110, y: 35) // Moved Right from +90 to +110
        container.addChild(nameLbl)
        
        // Status / Desc
        let statusLbl = SKLabelNode(fontNamed: "AvenirNext-Medium")
        if isUnlocked {
             statusLbl.text = isDefault ? "Default Sidearm" : "OWNED (Lifetime)"
             statusLbl.fontColor = .green
        } else if let remaining = UpgradeManager.shared.getRentalTimeRemaining(type) {
             statusLbl.text = "RENTED: \(remaining) left"
             statusLbl.fontColor = .yellow
        } else {
            statusLbl.text = "Not Owned"
            statusLbl.fontColor = .gray
        }
        statusLbl.fontSize = 12
        statusLbl.horizontalAlignmentMode = .left
        statusLbl.position = CGPoint(x: -width/2 + 110, y: 15) // Moved Right from +90 to +110
        container.addChild(statusLbl)

        // Buttons (Right Side)
        if !isUnlocked && !isRented {
            // RENT / BUY
            if let rProd = rentalProd {
                let rentBtn = createArcadeButton(size: CGSize(width: 100, height: 40), cornerRadius: 8, color: .orange)
                rentBtn.position = CGPoint(x: width/2 - 170, y: -20)
                rentBtn.name = "buy_\(rProd.rawValue)"
                container.addChild(rentBtn)
                
                let rentLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
                rentLbl.text = "Rent \(IAPManager.shared.getLocalizedPrice(for: rProd))"
                rentLbl.fontSize = 11
                rentLbl.verticalAlignmentMode = .center
                rentBtn.addChild(rentLbl)
                
                let dur = SKLabelNode(fontNamed: "AvenirNext-Bold")
                dur.text = "15 DAYS"
                dur.fontSize = 10
                dur.fontColor = .orange
                dur.position = CGPoint(x: 0, y: -35)
                rentBtn.addChild(dur)
            }
            
            if let lProd = lifeProd {
                let lifeBtn = createArcadeButton(size: CGSize(width: 100, height: 40), cornerRadius: 8, color: .green)
                lifeBtn.position = CGPoint(x: width/2 - 60, y: -20)
                lifeBtn.name = "buy_\(lProd.rawValue)"
                container.addChild(lifeBtn)
                
                let lifeLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
                lifeLbl.text = "Buy \(IAPManager.shared.getLocalizedPrice(for: lProd))"
                lifeLbl.fontSize = 11
                lifeLbl.verticalAlignmentMode = .center
                lifeBtn.addChild(lifeLbl)
                
                let dur = SKLabelNode(fontNamed: "AvenirNext-Bold")
                dur.text = "LIFETIME"
                dur.fontSize = 10
                dur.fontColor = .green
                dur.position = CGPoint(x: 0, y: -35)
                lifeBtn.addChild(dur)
            }
        } else {
            // EQUIP LOGIC
            // Check if active
            if UpgradeManager.shared.activeWeapon == type {
                let eqLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
                eqLbl.text = "✅ EQUIPPED"
                eqLbl.fontSize = 16
                eqLbl.fontColor = .green
                eqLbl.position = CGPoint(x: width/2 - 60, y: -10)
                container.addChild(eqLbl)
            } else {
                let eqBtn = createArcadeButton(size: CGSize(width: 120, height: 40), cornerRadius: 8, color: .cyan)
                eqBtn.position = CGPoint(x: width/2 - 70, y: -10)
                eqBtn.name = "equip_\(type.rawValue)"
                container.addChild(eqBtn)
                
                let eqLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
                eqLbl.text = "EQUIP"
                eqLbl.fontSize = 14
                eqLbl.fontColor = .black
                eqLbl.verticalAlignmentMode = .center
                eqBtn.addChild(eqLbl)
            }
        }
        
        return container
    }
    
    private func createUpgradeCard(name: String, level: Int, icon: String, width: CGFloat, height: CGFloat) -> SKNode {
        let container = SKNode()
        
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 16)
        bg.fillColor = SKColor(red: 0.1, green: 0.12, blue: 0.2, alpha: 0.95)
        bg.strokeColor = .cyan
        bg.lineWidth = 2
        container.addChild(bg)
        
        // Icon
        if let tex = SKTexture.fromSymbol(name: icon, pointSize: 40) {
            let sprite = SKSpriteNode(texture: tex)
            sprite.size = CGSize(width: 50, height: 50)
            sprite.position = CGPoint(x: -width/2 + 50, y: 20)
            sprite.color = .cyan
            sprite.colorBlendFactor = 1.0
            container.addChild(sprite)
        }
        
        // Info
        let nameLbl = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        nameLbl.text = "\(name) (Lvl \(level))"
        nameLbl.fontSize = 18
        nameLbl.fontColor = .white
        nameLbl.horizontalAlignmentMode = .left
        nameLbl.position = CGPoint(x: -width/2 + 90, y: 35)
        container.addChild(nameLbl)
        
        // Cost (100 * level)
        let cost = 100 * (level + 1)
        
        // Buy Button
        let btn = createArcadeButton(size: CGSize(width: 140, height: 40), cornerRadius: 8, color: .yellow)
        btn.position = CGPoint(x: width/2 - 80, y: -10)
        btn.name = "upgrade_\(name)" // Need to handle this name!
        container.addChild(btn)
        
        let costLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        costLbl.text = "UPGRADE $\(cost)"
        costLbl.fontSize = 12
        costLbl.fontColor = .black
        costLbl.verticalAlignmentMode = .center
        btn.addChild(costLbl)
        
        return container
    }
            

    
    private func createStaticOwnedCard(name: String, desc: String, icon: String, width: CGFloat, height: CGFloat) -> SKNode {
        let container = SKNode()
        
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 16)
        bg.fillColor = SKColor(red: 0.1, green: 0.12, blue: 0.2, alpha: 0.95)
        bg.strokeColor = .green
        bg.lineWidth = 2
        container.addChild(bg)
        
        let iconNode: SKSpriteNode
        if let texture = getIconTexture(name: icon) {
             iconNode = SKSpriteNode(texture: texture)
             if icon.hasPrefix("iap_") || icon.hasPrefix("weapon_") {
                 iconNode.size = CGSize(width: 80, height: 80)
                 iconNode.position = CGPoint(x: -width/2 + 50, y: 15)
             } else {
                 iconNode.size = CGSize(width: 50, height: 50)
                 iconNode.position = CGPoint(x: -width/2 + 50, y: 20)
                 iconNode.color = .green
                 iconNode.colorBlendFactor = 1.0
             }
        } else {
             iconNode = SKSpriteNode(color: .green, size: CGSize(width: 50, height: 50))
             iconNode.position = CGPoint(x: -width/2 + 50, y: 20)
        }
        container.addChild(iconNode)
        
        let nameLbl = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        nameLbl.text = name
        nameLbl.fontSize = 20
        nameLbl.fontColor = .white
        nameLbl.horizontalAlignmentMode = .left
        nameLbl.position = CGPoint(x: -width/2 + 110, y: 35) // Moved Right to +110
        container.addChild(nameLbl)
        
        let descLbl = SKLabelNode(fontNamed: "AvenirNext-Medium")
        descLbl.text = desc
        descLbl.fontSize = 12
        descLbl.fontColor = .gray
        descLbl.horizontalAlignmentMode = .left
        descLbl.position = CGPoint(x: -width/2 + 110, y: 15) // Moved Right to +110
        container.addChild(descLbl)
        
        let badge = SKLabelNode(fontNamed: "AvenirNext-Bold")
        badge.text = "✅ OWNED"
        badge.fontSize = 16
        badge.fontColor = .green
        badge.position = CGPoint(x: width/2 - 80, y: -10)
        container.addChild(badge)
        
        return container
    }
    
    private func createUnlockCard(name: String, desc: String, product: IAPProduct, icon: String, width: CGFloat, height: CGFloat, isFree: Bool) -> SKNode {
        let container = SKNode()
        
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 16)
        bg.fillColor = SKColor(red: 0.1, green: 0.12, blue: 0.2, alpha: 0.95)
        bg.strokeColor = .cyan
        bg.lineWidth = 2
        container.addChild(bg)
        
        let iconNode: SKSpriteNode
        if let texture = getIconTexture(name: icon) {
             iconNode = SKSpriteNode(texture: texture)
             if icon.hasPrefix("iap_") || icon.hasPrefix("skill_") {
                 iconNode.size = CGSize(width: 80, height: 80)
                 iconNode.position = CGPoint(x: -width/2 + 50, y: 15)
             } else {
                 iconNode.size = CGSize(width: 50, height: 50)
                 iconNode.position = CGPoint(x: -width/2 + 50, y: 20)
                 iconNode.color = .cyan
                 iconNode.colorBlendFactor = 1.0
             }
        } else {
            iconNode = SKSpriteNode(color: .cyan, size: CGSize(width: 50, height: 50))
            iconNode.position = CGPoint(x: -width/2 + 50, y: 20)
        }
        container.addChild(iconNode)
        
        let nameLbl = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        nameLbl.text = name
        nameLbl.fontSize = 20
        nameLbl.fontColor = .white
        nameLbl.horizontalAlignmentMode = .left
        nameLbl.position = CGPoint(x: -width/2 + 110, y: 35) // Moved Right to +110
        container.addChild(nameLbl)
        
        let descLbl = SKLabelNode(fontNamed: "AvenirNext-Medium")
        descLbl.text = desc
        descLbl.fontSize = 12
        descLbl.fontColor = .gray
        descLbl.horizontalAlignmentMode = .left
        descLbl.position = CGPoint(x: -width/2 + 110, y: 15) // Moved Right to +110
        container.addChild(descLbl)
        
        // Button
        let btnColor: SKColor = isFree ? .green : .cyan
        let buyBtn = createArcadeButton(size: CGSize(width: 120, height: 40), cornerRadius: 8, color: btnColor)
        buyBtn.position = CGPoint(x: width/2 - 80, y: -10)
        buyBtn.name = "buy_\(product.rawValue)"
        container.addChild(buyBtn)
        
        let btnLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        btnLbl.text = isFree ? "CLAIM (FREE)" : IAPManager.shared.getLocalizedPrice(for: product)
        btnLbl.fontSize = 12
        btnLbl.fontColor = .black
        btnLbl.verticalAlignmentMode = .center
        buyBtn.addChild(btnLbl)
        
        return container
    }
    
    // MARK: - IAP View (Gem Shop)
    
    private func showIAP() {
        // Cache Check
        if let iap = iapContainer {
            if !iap.isHidden { return }
            
            clearContent()
            updateTabs(selected: "tab_iap")
            iap.isHidden = false
            return
        }
        
        clearContent()
        updateTabs(selected: "tab_iap")
        
        let container = SKNode()
        container.position = CGPoint(x: 0, y: -30)
        iapContainer = container
        containerNode.addChild(container)
        
        // Gem packs data - MUST match IAPProduct enum IDs exactly!
        // Tuple: Name, Desc, Amount, Price, ProdID, ImageName
        let packs: [(String, String, Int, String, String, String)] = [
            ("Starter Gems", "Try it out!", 80, "$0.99", IAPProduct.gems80.rawValue, "iap_gems_80"),
            ("Handful of Gems", "Small pack to get started", 500, "$4.99", IAPProduct.gems500.rawValue, "iap_gems_500"),
            ("Pouch of Gems", "Popular choice!", 1200, "$9.99", IAPProduct.gems1200.rawValue, "iap_gems_1200"),
            ("Chest of Gems", "Great value pack", 3500, "$24.99", IAPProduct.gems3500.rawValue, "iap_gems_3500"),
            ("Vault of Gems", "For serious collectors", 8000, "$49.99", IAPProduct.gems8000.rawValue, "iap_gems_8000"),
            ("Treasury of Gems", "Ultimate pack!", 20000, "$99.99", IAPProduct.gems20000.rawValue, "iap_gems_20000")
        ]
        
        let cardHeight: CGFloat = 80
        let verticalSpacing: CGFloat = 12
        // Shift up significantly to use empty space (User feedback: "yukarıda bir sürü yer var")
        let startY: CGFloat = 220 // Was 130
        
        for (index, pack) in packs.enumerated() {
            let yPos = startY - CGFloat(index) * (cardHeight + verticalSpacing)
            
            let card = createGemPackCard(
                name: pack.0,
                description: pack.1,
                gemAmount: pack.2,
                price: pack.3,
                productId: pack.4,
                imageName: pack.5,
                width: width - 50,
                height: cardHeight,
                isPopular: index == 1
            )
            card.position = CGPoint(x: 0, y: yPos)
            container.addChild(card)
        }
        
        // Restore Purchases Button
        let restoreBtn = SKShapeNode(rectOf: CGSize(width: 200, height: 40), cornerRadius: 8)
        restoreBtn.fillColor = SKColor(white: 0.15, alpha: 1) // Restored dark fill
        restoreBtn.strokeColor = .cyan // Restored cyan stroke
        restoreBtn.lineWidth = 1
        // Move down to avoid overlap (Bottom of last item was approx -260, so -height/2 + 50 is safe)
        restoreBtn.position = CGPoint(x: 0, y: -height/2 + 50) 
        restoreBtn.name = "restore_btn" // Restored name for touch handling
        container.addChild(restoreBtn)
        
        let restoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        restoreLabel.text = "Restore Purchases"
        restoreLabel.fontSize = 14
        restoreLabel.fontColor = .cyan
        restoreLabel.verticalAlignmentMode = .center
        restoreBtn.addChild(restoreLabel)
    }
    
    private func createGemPackCard(name: String, description: String, gemAmount: Int, price: String, productId: String, imageName: String, width: CGFloat, height: CGFloat, isPopular: Bool) -> SKNode {
        let container = SKNode()
        
        let accentColor: SKColor = isPopular ? .yellow : .cyan
        
        // Glow for popular
        if isPopular {
            let glow = SKShapeNode(rectOf: CGSize(width: width + 6, height: height + 6), cornerRadius: 16)
            glow.fillColor = .clear
            glow.strokeColor = accentColor.withAlphaComponent(0.5)
            glow.lineWidth = 2
            glow.glowWidth = 10
            container.addChild(glow)
        }
        
        // Background
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 14)
        bg.fillColor = SKColor(red: 0.08, green: 0.10, blue: 0.15, alpha: 0.95)
        bg.strokeColor = accentColor.withAlphaComponent(0.6)
        bg.lineWidth = isPopular ? 2 : 1
        container.addChild(bg)
        
        // Popular badge
        if isPopular {
            let badge = SKShapeNode(rectOf: CGSize(width: 80, height: 20), cornerRadius: 10)
            badge.fillColor = .yellow
            badge.strokeColor = .clear
            badge.position = CGPoint(x: width/2 - 50, y: height/2 - 5)
            container.addChild(badge)
            
            let badgeLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            badgeLabel.text = "POPULAR"
            badgeLabel.fontSize = 10
            badgeLabel.fontColor = .black
            badgeLabel.verticalAlignmentMode = .center
            badge.addChild(badgeLabel)
        }
        
        // Gem icon
        // Gem icon (Asset or Symbol)
        let iconNode: SKSpriteNode
        if let texture = getIconTexture(name: imageName) {
            iconNode = SKSpriteNode(texture: texture)
            if imageName.hasPrefix("iap_") {
                 iconNode.size = CGSize(width: 70, height: 70) // Larger for gems
                 iconNode.position = CGPoint(x: -width/2 + 45, y: 5)
            } else {
                // Should not happen for gems usually, but fallback
                iconNode.size = CGSize(width: 30, height: 30)
                iconNode.position = CGPoint(x: -width/2 + 35, y: 5)
                iconNode.color = accentColor
                iconNode.colorBlendFactor = 1.0
            }
        } else {
             iconNode = SKSpriteNode(color: accentColor, size: CGSize(width: 30, height: 30))
             iconNode.position = CGPoint(x: -width/2 + 35, y: 5)
        }
        container.addChild(iconNode)
        
        // Name
        let nameLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        nameLabel.text = name
        nameLabel.fontSize = 15
        nameLabel.fontColor = .white
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.position = CGPoint(x: -width/2 + 95, y: 12) // Moved Right to +95
        container.addChild(nameLabel)
        
        // Gem amount
        let gemLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        gemLabel.text = "\(gemAmount.formatted())"
        gemLabel.fontSize = 13
        gemLabel.fontColor = accentColor
        gemLabel.horizontalAlignmentMode = .left
        gemLabel.position = CGPoint(x: -width/2 + 95, y: -10) // Moved Right to +95
        container.addChild(gemLabel)
        
        // Buy button (right side)
        let buyBtn = createArcadeButton(size: CGSize(width: 90, height: 40), cornerRadius: 10, color: .green)
        buyBtn.position = CGPoint(x: width/2 - 60, y: 0)
        buyBtn.name = "buy_\(productId)"
        container.addChild(buyBtn)
        
        let priceLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        priceLabel.text = price
        priceLabel.fontSize = 14
        priceLabel.fontColor = .white
        priceLabel.verticalAlignmentMode = .center
        buyBtn.addChild(priceLabel)
        
        return container
    }
    
    // MARK: - Helpers
    
    private func createArcadeButton(size: CGSize, cornerRadius: CGFloat, color: SKColor) -> SKShapeNode {
        let btn = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        btn.fillColor = color
        btn.strokeColor = color.lighter(by: 0.3)
        btn.lineWidth = 2
        btn.glowWidth = 4
        return btn
    }
    
    private func createPageButton(text: String, name: String) -> SKNode {
        let container = SKNode()
        container.name = name
        
        let btn = SKShapeNode(rectOf: CGSize(width: 60, height: 30), cornerRadius: 8)
        btn.fillColor = SKColor(white: 0.2, alpha: 0.9)
        btn.strokeColor = .cyan
        btn.lineWidth = 1
        btn.position = CGPoint(x: 0, y: 0)
        btn.name = name
        container.addChild(btn)
        
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = text
        label.fontSize = 10
        label.fontColor = .cyan
        label.verticalAlignmentMode = .center
        container.addChild(label)
        
        return container
    }
    
    private func createGlassmorphismCard(width: CGFloat, height: CGFloat, glowColor: SKColor) -> SKNode {
        let container = SKNode()
        
        let glow = SKShapeNode(rectOf: CGSize(width: width + 4, height: height + 4), cornerRadius: 14)
        glow.fillColor = .clear
        glow.strokeColor = glowColor.withAlphaComponent(0.4)
        glow.lineWidth = 2
        glow.glowWidth = 8
        container.addChild(glow)
        
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 12)
        bg.fillColor = glowColor.withAlphaComponent(0.15)
        bg.strokeColor = glowColor.withAlphaComponent(0.5)
        bg.lineWidth = 1.5
        container.addChild(bg)
        
        return container
    }
    
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
        case "📜": return "scroll.fill"
        case "🧪": return "flask.fill"
        default: return "circle.fill"
        }
    }
    
    private func colorForRarity(_ rarity: String) -> SKColor {
        switch rarity.lowercased() {
        case "legendary": return SKColor.yellow
        case "epic": return SKColor.purple
        case "rare": return SKColor.blue
        case "common": return SKColor.gray
        default: return SKColor.white
        }
    }
    
    private func clearContent() {
        // Instead of removing all children, we hide the distinct containers so they can be reused
        gachaContainer?.isHidden = true
        inventoryContainer?.isHidden = true
        iapContainer?.isHidden = true
        armoryContainer?.isHidden = true
    }
    
    private func updateTabs(selected: String) {
        for child in containerNode.children {
            if let name = child.name, name.hasPrefix("tab_") {
                // Background
                if let bg = child.children.first(where: { $0 is SKShapeNode }) as? SKShapeNode {
                     let isSelected = (name == selected)
                     bg.fillColor = isSelected ? SKColor.cyan.withAlphaComponent(0.3) : SKColor(white: 0.15, alpha: 0.8)
                     bg.strokeColor = isSelected ? .cyan : SKColor(white: 0.3, alpha: 0.5)
                     bg.lineWidth = isSelected ? 2 : 1
                     bg.glowWidth = isSelected ? 5 : 0
                }
                
                // Icon & Label Color
                child.children.forEach { node in
                    if let label = node as? SKLabelNode {
                        label.fontColor = (name == selected) ? .cyan : .gray
                    } else if let sprite = node as? SKSpriteNode {
                        sprite.color = (name == selected) ? .cyan : .gray
                    }
                }
            }
        }
    }
    
    // MARK: - Touch Handling
    
    private func performPull(count: Int) {
        guard GachaManager.shared.canPull(count: count) else {
            showToast(message: "Not enough Gems!")
            
            // Auto-redirect to Gem Shop
            run(SKAction.sequence([
                SKAction.wait(forDuration: 1.0), // Wait for toast
                SKAction.run { [weak self] in
                    self?.showIAP() // Switch to Gem Shop tab
                }
            ]))
            return
        }
        
        if let perks = GachaManager.shared.pull(count: count) {
            // Animate Opening
            animateBoxOpening(perks: perks)
        }
    }
    
    private func animateBoxOpening(perks: [GachaPerk]) {
        // Overlay
        let overlay = SKShapeNode(rectOf: CGSize(width: 3000, height: 3000))
        overlay.fillColor = SKColor.black.withAlphaComponent(0.9)
        overlay.strokeColor = .clear
        overlay.zPosition = 2000
        overlay.name = "boxOverlay"
        addChild(overlay)
        
        // Box / Chest ID
        let box = SKSpriteNode(color: .cyan, size: CGSize(width: 100, height: 100))
        if let boxTex = SKTexture.fromSymbol(name: "shippingbox.fill", pointSize: 100) {
            box.texture = boxTex
        }
        box.position = CGPoint(x: 0, y: 0)
        box.zPosition = 2001
        box.color = .purple
        box.colorBlendFactor = 1.0
        addChild(box)
        
        // Shake sequence
        let shake = SKAction.sequence([
            SKAction.rotate(byAngle: 0.2, duration: 0.1),
            SKAction.rotate(byAngle: -0.4, duration: 0.1),
            SKAction.rotate(byAngle: 0.2, duration: 0.1)
        ])
        
        box.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.2),
            SKAction.repeat(shake, count: 5),
            SKAction.scale(to: 1.5, duration: 0.1),
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.scale(to: 3.0, duration: 0.2)
            ]),
            SKAction.run { [weak self] in
                self?.showRewardReveal(perks: perks, overlay: overlay)
                box.removeFromParent()
            }
        ]))
        
        // Sound
        AudioManager.shared.playUpgrade() // Placeholder for box shake
    }
    
    private func showRewardReveal(perks: [GachaPerk], overlay: SKNode) {
        // Flash
        let flash = SKShapeNode(rectOf: CGSize(width: 3000, height: 3000))
        flash.fillColor = .white
        flash.alpha = 0
        flash.zPosition = 2002
        addChild(flash)
        
        flash.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 1.0, duration: 0.1),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
        
        // Audio
        AudioManager.shared.playWaveComplete()
        
        let count = perks.count
        
        // SINGLE ITEM: Force Center
        if count == 1 {
            let card = createRewardCard(perk: perks[0], compact: false)
            card.position = CGPoint(x: 0, y: 30) // Slightly up to clear button
            card.setScale(0)
            card.zPosition = 2005
            overlay.addChild(card)
            
            card.run(SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 0.2),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
        }
        else {
            // MULTI ITEM (10x): Tighter Grid
            let isLargePull = count > 5
            
            // Tighter packing for 10 items
            let scale: CGFloat = isLargePull ? 0.8 : 1.0
            let rowHeight: CGFloat = isLargePull ? 85 : 110
            let colWidth: CGFloat = isLargePull ? 190 : 240
            
            let cols = 2
            let rows = Int(ceil(Double(count) / Double(cols)))
            
            // Center the entire block
            let totalBlockHeight = CGFloat(rows - 1) * rowHeight
            let startY = totalBlockHeight / 2 + 20 
            
            for (i, perk) in perks.enumerated() {
                let row = i / cols
                let col = i % cols
                
                // Centered columns: -width/2, +width/2
                let xPos = (col == 0 ? -colWidth/2 : colWidth/2)
                let yPos = startY - CGFloat(row) * rowHeight
                
                // Card
                let card = createRewardCard(perk: perk, compact: isLargePull)
                card.position = CGPoint(x: CGFloat(xPos), y: yPos)
                card.setScale(0)
                card.zPosition = 2005
                overlay.addChild(card)
                
                // Pop in
                card.run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.05 * Double(i)),
                    SKAction.scale(to: scale * 1.2, duration: 0.15),
                    SKAction.scale(to: scale, duration: 0.1)
                ]))
            }
        }
        
        // Close Button
        let closeBtn = createArcadeButton(size: CGSize(width: 200, height: 60), cornerRadius: 30, color: .green)
        closeBtn.position = CGPoint(x: 0, y: -height/2 + 60)
        closeBtn.zPosition = 2010
        closeBtn.name = "closeRewardOverlay"
        overlay.addChild(closeBtn)
        
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = "COLLECT"
        label.fontSize = 20
        label.fontColor = .black
        label.verticalAlignmentMode = .center
        closeBtn.addChild(label)
    }
    
    // MARK: - Helper: Reward Card for Gacha
    private func createRewardCard(perk: GachaPerk, compact: Bool) -> SKNode {
        let container = SKNode()
        let color = colorForRarity(perk.rarity.rawValue)
        let width: CGFloat = compact ? 180 : 220
        let height: CGFloat = compact ? 75 : 100
        
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 10)
        bg.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1)
        bg.strokeColor = color
        bg.lineWidth = compact ? 2 : 3
        container.addChild(bg)
        
        if let icon = SKTexture.fromSymbol(name: "sparkles", pointSize: compact ? 20 : 30) {
            let sprite = SKSpriteNode(texture: icon)
            sprite.color = color
            sprite.colorBlendFactor = 1.0
            sprite.position = CGPoint(x: -width/2 + (compact ? 25 : 40), y: 0)
            sprite.size = CGSize(width: compact ? 20 : 30, height: compact ? 20 : 30)
            container.addChild(sprite)
        }
        
        let lbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        lbl.text = perk.name
        lbl.fontSize = compact ? 11 : 14
        lbl.fontColor = color
        lbl.position = CGPoint(x: (compact ? -15 : 10), y: (compact ? 5 : 10))
        container.addChild(lbl)
        
        let sub = SKLabelNode(fontNamed: "AvenirNext-Medium")
        sub.text = perk.rarity.rawValue.uppercased()
        sub.fontSize = compact ? 9 : 12
        sub.fontColor = .white
        sub.position = CGPoint(x: (compact ? -15 : 10), y: (compact ? -10 : -15))
        container.addChild(sub)
        
        return container
    }
    
    // MARK: - BAG ITEM CARD (Fixing Overlap)
    // The previous createItemCard (lines ~460) needs modification. 
    // Since I can't target it directly if it's out of range, I'll assume I need to 
    // replace `createItemCard` method which is likely around line 460-520.
    // The range provided here is 902-1000.
    // I need to use another call to fix createItemCard separately.
    
    // ... continues ...
    
    private func showRewards(_ perks: [GachaPerk]) {
        let count = perks.count
        let msg = count == 1 ? "Got: \(perks[0].name)!" : "Got \(count) Perks!"
        showToast(message: msg)
    }
    
    private func showToast(message: String) {
        let toast = SKShapeNode(rectOf: CGSize(width: 250, height: 50), cornerRadius: 25)
        toast.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 0.95)
        toast.strokeColor = .cyan
        toast.lineWidth = 2
        toast.glowWidth = 5
        toast.position = CGPoint(x: 0, y: 0)
        toast.zPosition = 3000
        addChild(toast)
        
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = message
        label.fontSize = 16
        label.fontColor = .cyan
        label.verticalAlignmentMode = .center
        toast.addChild(label)
        
        let moveUp = SKAction.moveBy(x: 0, y: 100, duration: 0.3)
        moveUp.timingMode = .easeOut
        let wait = SKAction.wait(forDuration: 1.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        
        toast.run(SKAction.sequence([moveUp, wait, fadeOut, SKAction.removeFromParent()]))
    }





    
    // MARK: - Pagination
    
    private func nextArmoryPage() {
        armoryPage += 1
        showArmory()
    }
    
    private func prevArmoryPage() {
        if armoryPage > 0 {
            armoryPage -= 1
            showArmory()
        }
    }
    
    private func nextInventoryPage() {
        currentInventoryPage += 1
        showInventory()
    }
    
    private func prevInventoryPage() {
        if currentInventoryPage > 0 {
            currentInventoryPage -= 1
            showInventory()
        }
    }


    
    // MARK: - Setup
    

    

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let nodes = nodes(at: loc)
        
        // Find the first interactive node by traversing up from any touched node
        for node in nodes {
             var current: SKNode? = node
             while let c = current {
                 if let name = c.name {
                    
                    // Close Button
                    if name == "shopClose" || name == "close_btn" {
                        close()
                        return
                    }
                    
                    // Tab Buttons
                    if name == "tab_gacha" {
                        showGacha()
                        return
                    } else if name == "tab_armory" {
                        showArmory()
                        return
                    } else if name == "tab_inventory" {
                        showInventory()
                        return
                    } else if name == "tab_iap" {
                        showIAP()
                        return
                    }
                    
                    // Pagination
                    if name == "armory_next_page" {
                        nextArmoryPage()
                        return
                    } else if name == "armory_prev_page" {
                        prevArmoryPage()
                        return
                    } else if name == "bag_next_page" {
                        nextInventoryPage()
                        return
                    } else if name == "bag_prev_page" {
                        prevInventoryPage()
                        return
                    }
                    
                    // Gacha Pulls
                    if name == "pull_1" {
                        performPull(count: 1)
                        return
                    } else if name == "pull_10" {
                        performPull(count: 10)
                        return
                    }
                    
                    // Inventory Use
                    if name.hasPrefix("use_") {
                        let itemId = String(name.dropFirst(4))
                        if InventoryManager.shared.useItem(id: itemId) {
                            showToast(message: "Buff Activated!")
                            showInventory()
                        }
                        return
                    }
                    // Gacha Reward Overlay
                    if name == "closeRewardOverlay" {
                        childNode(withName: "boxOverlay")?.removeFromParent()
                        showGacha()
                        return
                    }
                    
                    // Purchase Actions
                    if name == "buy_rent" {
                        buy(product: .railgunRental)
                        return
                    } else if name == "buy_life" {
                        buy(product: .railgunLifetime)
                        return
                    } else if name == "restore_btn" {
                        IAPManager.shared.restorePurchases { success, _ in
                             if success { self.showToast(message: "Restored!") }
                        }
                        return
                    }
                    else if name.hasPrefix("buy_") {
                        // Extract product ID
                        let productID = String(name.dropFirst(4))
                         // Map raw string to IAPProduct?
                         if let product = IAPProduct(rawValue: productID) {
                             buy(product: product)
                         }
                        return
                    }
                    else if name.hasPrefix("equip_") {
                        let weapon = String(name.dropFirst(6))
                         // Logic to equip...
                         // For now just print or handle if method exists
                        return
                    }
                 }
                 
                 // Stop if we hit the root container to avoid infinite loop or checking scene
                 if c == containerNode || c == self { break }
                 current = c.parent
             }
        }
    }
    
    private func buy(product: IAPProduct) {
        IAPManager.shared.purchase(product) { [weak self] success, error in
            if success {
                self?.run(SKAction.sequence([
                    SKAction.run {
                       // AudioManager.shared.playUpgrade() 
                    },
                    SKAction.wait(forDuration: 0.5),
                    SKAction.run { self?.close() }
                ]))
            } else {
                 // Error handling
            }
        }
    }
    
    private func close() {
        run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ]))
        onClose?()
    }
}

// MARK: - Gacha Promo UI
class GachaPromoUI: SKNode {
    
    // MARK: - Properties
    private let size: CGSize
    private let containerNode: SKNode
    
    var onOpenVault: (() -> Void)?
    var onClose: (() -> Void)?
    
    // MARK: - Init
    init(size: CGSize) {
        self.size = size
        self.containerNode = SKNode()
        super.init()
        
        setupDimmedBackground()
        setupPromoCard()
        
        isUserInteractionEnabled = true
        zPosition = 2000 // High zPosition
        
        // Entry Animation
        containerNode.setScale(0.0)
        containerNode.run(SKAction.scale(to: 1.0, duration: 0.3))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupDimmedBackground() {
        let dimmer = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        dimmer.fillColor = SKColor.black.withAlphaComponent(0.85)
        dimmer.strokeColor = .clear
        dimmer.name = "bg_dimmer"
        addChild(dimmer)
    }
    
    private func setupPromoCard() {
        let width: CGFloat = 340
        let height: CGFloat = 500
        
        // Card Background
        let card = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 24)
        card.fillColor = SKColor(red: 0.1, green: 0.05, blue: 0.2, alpha: 1.0) // Dark Purple
        card.strokeColor = .purple
        card.lineWidth = 2
        card.glowWidth = 10
        containerNode.addChild(card)
        
        // Header Text
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleLabel.text = "LEGENDARY POWER\nAWAITS YOU!"
        titleLabel.numberOfLines = 2
        titleLabel.fontSize = 24
        titleLabel.fontColor = .yellow
        titleLabel.position = CGPoint(x: 0, y: height/2 - 60)
        containerNode.addChild(titleLabel)
        
        // Subtitle
        let subLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        subLabel.text = "Open the Perk Vault to get stronger!"
        subLabel.fontSize = 14
        subLabel.fontColor = .cyan
        subLabel.position = CGPoint(x: 0, y: height/2 - 110)
        containerNode.addChild(subLabel)
        
        // Icon (Box/Star)
        if let iconTex = SKTexture.fromSymbol(name: "archivebox.circle.fill", pointSize: 100) {
            let icon = SKSpriteNode(texture: iconTex)
            icon.size = CGSize(width: 120, height: 120)
            icon.color = .purple
            icon.colorBlendFactor = 1.0
            icon.position = CGPoint(x: 0, y: 30)
            
            // Pulse Animation
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.8),
                SKAction.scale(to: 1.0, duration: 0.8)
            ])
            icon.run(SKAction.repeatForever(pulse))
            
            containerNode.addChild(icon)
        }
        
        // Buttons
        setupButtons(width: width, height: height)
        
        addChild(containerNode)
    }
    
    private func setupButtons(width: CGFloat, height: CGFloat) {
        let btnWidth = width * 0.8
        let btnHeight: CGFloat = 60
        let startY: CGFloat = -height/2 + 140
        
        // 1. Open Vault Button
        let openBtn = createButton(
            text: "OPEN PERK VAULT",
            color: SKColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1.0), // Purple
            size: CGSize(width: btnWidth, height: btnHeight)
        )
        openBtn.position = CGPoint(x: 0, y: startY)
        openBtn.name = "btn_open"
        containerNode.addChild(openBtn)
        
        // 2. Close Button
        let closeLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        closeLabel.text = "Continue Game"
        closeLabel.fontSize = 16
        closeLabel.fontColor = .gray
        closeLabel.position = CGPoint(x: 0, y: startY - 80)
        closeLabel.name = "btn_close"
        
        let closeBtn = SKShapeNode(rectOf: CGSize(width: 150, height: 40))
        closeBtn.fillColor = .clear
        closeBtn.strokeColor = .clear
        closeBtn.position = CGPoint(x: 0, y: startY - 70)
        closeBtn.name = "btn_close"
        closeBtn.addChild(closeLabel)
        
        containerNode.addChild(closeBtn)
    }
    
    private func createButton(text: String, color: SKColor, size: CGSize) -> SKNode {
        let container = SKNode()
        
        // Glow
        let bg = SKShapeNode(rectOf: size, cornerRadius: 12)
        bg.fillColor = color
        bg.strokeColor = .white
        bg.lineWidth = 1
        bg.glowWidth = 4
        container.addChild(bg)
        
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = text
        label.fontSize = 16
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        container.addChild(label)
        
        return container
    }
    
    // MARK: - Input
    
    private func openVault() {
        run(SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.run { [weak self] in
                self?.onOpenVault?()
            },
            SKAction.removeFromParent()
        ]))
    }
    
    private func close() {
        run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.run { [weak self] in
                self?.onClose?()
            },
            SKAction.removeFromParent()
        ]))
    }
    // MARK: - Input
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let nodes = nodes(at: loc)
        
        for node in nodes {
            var current: SKNode? = node
            while let c = current {
                if let name = c.name {
                    if name == "btn_close" || name == "bg_dimmer" {
                        close()
                        return
                    } else if name == "btn_open" {
                        openVault()
                        return
                    }
                }
                current = c.parent
                if c == self { break }
            }
        }
    }
}

// MARK: - SKColor Extension

extension SKColor {
    static let gold = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
    
    func lighter(by percentage: CGFloat) -> SKColor {
        return self.adjustBrightness(by: abs(percentage))
    }
    
    func adjustBrightness(by percentage: CGFloat) -> SKColor {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        
        if self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            let newBrightness = min(max(brightness + percentage, 0.0), 1.0)
            return SKColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha)
        }
        return self
    }
}

// MARK: - Special Offer UI (Railgun Weapon Offer)

class SpecialOfferUI: SKNode {
    
    // MARK: - Properties
    private let containerNode: SKNode
    private let width: CGFloat
    private let height: CGFloat
    private let offerType: OfferType
    
    var onClose: (() -> Void)?
    var onPurchase: ((IAPProduct) -> Void)?
    
    enum OfferType {
        case survivor // Passed 3 mins
        case struggler // Died 3 times
    }
    
    // MARK: - Init
    init(size: CGSize, type: OfferType) {
        self.width = 320
        self.height = 560
        self.containerNode = SKNode()
        self.offerType = type
        super.init()
        
        setupDimmedBackground()
        setupOfferCard()
        
        isUserInteractionEnabled = true
        zPosition = 3000
        
        // Entry Animation
        containerNode.setScale(0.0)
        containerNode.run(SKAction.scale(to: 1.0, duration: 0.3))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupDimmedBackground() {
        let dimmer = SKShapeNode(rectOf: CGSize(width: 1000, height: 2000))
        dimmer.fillColor = SKColor.black.withAlphaComponent(0.8)
        dimmer.strokeColor = .clear
        dimmer.name = "special_offer_dimmer"
        addChild(dimmer)
    }
    
    private func setupOfferCard() {
        // Card BG with gradient effect
        let card = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 20)
        card.fillColor = SKColor(red: 0.08, green: 0.05, blue: 0.15, alpha: 1.0)
        card.strokeColor = SKColor.cyan
        card.lineWidth = 2
        card.glowWidth = 12
        containerNode.addChild(card)
        
        // Limited Time Badge
        let badgeBg = SKShapeNode(rectOf: CGSize(width: 140, height: 28), cornerRadius: 14)
        badgeBg.fillColor = SKColor.red
        badgeBg.strokeColor = .white
        badgeBg.lineWidth = 1
        badgeBg.position = CGPoint(x: 0, y: height/2 - 30)
        containerNode.addChild(badgeBg)
        
        let badgeLbl = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        badgeLbl.text = "⚡ SPECIAL OFFER"
        badgeLbl.fontSize = 12
        badgeLbl.fontColor = .white
        badgeLbl.verticalAlignmentMode = .center
        badgeBg.addChild(badgeLbl)
        
        // Header
        let titleLbl = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleLbl.text = "RAILGUN"
        titleLbl.fontSize = 28
        titleLbl.fontColor = .cyan
        titleLbl.position = CGPoint(x: 0, y: height/2 - 70)
        containerNode.addChild(titleLbl)
        
        // Railgun Image
        let railgunTexture = SKTexture(imageNamed: "iap_weapon_railgun")
        let railgunSprite = SKSpriteNode(texture: railgunTexture)
        railgunSprite.size = CGSize(width: 120, height: 120)
        railgunSprite.position = CGPoint(x: 0, y: 60)
        containerNode.addChild(railgunSprite)
        
        // Glow effect behind weapon
        let glowCircle = SKShapeNode(circleOfRadius: 70)
        glowCircle.fillColor = SKColor.cyan.withAlphaComponent(0.15)
        glowCircle.strokeColor = .clear
        glowCircle.position = CGPoint(x: 0, y: 60)
        glowCircle.zPosition = -1
        containerNode.addChild(glowCircle)
        
        // Description
        let descLbl = SKLabelNode(fontNamed: "AvenirNext-Medium")
        descLbl.text = "Most powerful weapon!"
        descLbl.fontSize = 14
        descLbl.fontColor = SKColor(white: 0.7, alpha: 1)
        descLbl.position = CGPoint(x: 0, y: -20)
        containerNode.addChild(descLbl)
        
        // Features
        let features = ["⚡ Pierces all enemies", "💥 Massive damage", "🎯 Long range"]
        for (index, feature) in features.enumerated() {
            let featureLbl = SKLabelNode(fontNamed: "AvenirNext-Medium")
            featureLbl.text = feature
            featureLbl.fontSize = 12
            featureLbl.fontColor = .white
            featureLbl.horizontalAlignmentMode = .left
            featureLbl.position = CGPoint(x: -width/2 + 50, y: -50 - CGFloat(index) * 20)
            containerNode.addChild(featureLbl)
        }
        
        setupButtons()
        addChild(containerNode)
    }
    
    private func setupButtons() {
        // Get localized prices
        let rentalPrice = IAPManager.shared.getLocalizedPrice(for: .railgunRental)
        let lifetimePrice = IAPManager.shared.getLocalizedPrice(for: .railgunLifetime)
        
        // 15 Days Button
        let rentalBtn = createPurchaseButton(
            title: "15 DAYS",
            price: rentalPrice,
            color: SKColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1),
            width: width - 50
        )
        rentalBtn.position = CGPoint(x: 0, y: -145)
        rentalBtn.name = "btn_railgun_rental"
        containerNode.addChild(rentalBtn)
        
        // Lifetime Button (highlighted)
        let lifetimeBtn = createPurchaseButton(
            title: "FOREVER ⭐",
            price: lifetimePrice,
            color: SKColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 1),
            width: width - 50,
            highlighted: true
        )
        lifetimeBtn.position = CGPoint(x: 0, y: -210)
        lifetimeBtn.name = "btn_railgun_lifetime"
        containerNode.addChild(lifetimeBtn)
        
        // Best Value badge on lifetime
        let valueBadge = SKShapeNode(rectOf: CGSize(width: 80, height: 20), cornerRadius: 10)
        valueBadge.fillColor = .yellow
        valueBadge.strokeColor = .clear
        valueBadge.position = CGPoint(x: width/2 - 60, y: -195)
        containerNode.addChild(valueBadge)
        
        let valueLbl = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        valueLbl.text = "BEST VALUE"
        valueLbl.fontSize = 8
        valueLbl.fontColor = .black
        valueLbl.verticalAlignmentMode = .center
        valueBadge.addChild(valueLbl)
        
        // Close Button
        let closeBtn = SKLabelNode(fontNamed: "AvenirNext-Bold")
        closeBtn.text = "No Thanks"
        closeBtn.fontSize = 14
        closeBtn.fontColor = .gray
        closeBtn.position = CGPoint(x: 0, y: -height/2 + 30)
        closeBtn.name = "btn_close_offer"
        containerNode.addChild(closeBtn)
    }
    
    private func createPurchaseButton(title: String, price: String, color: SKColor, width: CGFloat, highlighted: Bool = false) -> SKNode {
        let container = SKNode()
        
        // Glow for highlighted
        if highlighted {
            let glow = SKShapeNode(rectOf: CGSize(width: width + 6, height: 52), cornerRadius: 14)
            glow.fillColor = .clear
            glow.strokeColor = color.withAlphaComponent(0.6)
            glow.lineWidth = 2
            glow.glowWidth = 8
            container.addChild(glow)
        }
        
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: 48), cornerRadius: 12)
        bg.fillColor = color
        bg.strokeColor = .white
        bg.lineWidth = highlighted ? 2 : 1
        container.addChild(bg)
        
        // Title on left
        let titleLbl = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleLbl.text = title
        titleLbl.fontSize = 16
        titleLbl.fontColor = .white
        titleLbl.horizontalAlignmentMode = .left
        titleLbl.verticalAlignmentMode = .center
        titleLbl.position = CGPoint(x: -width/2 + 20, y: 0)
        container.addChild(titleLbl)
        
        // Price on right
        let priceLbl = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        priceLbl.text = price
        priceLbl.fontSize = 18
        priceLbl.fontColor = .white
        priceLbl.horizontalAlignmentMode = .right
        priceLbl.verticalAlignmentMode = .center
        priceLbl.position = CGPoint(x: width/2 - 20, y: 0)
        container.addChild(priceLbl)
        
        return container
    }
    
    // MARK: - Interaction
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = nodes(at: location)
        
        for node in nodes {
            var current: SKNode? = node
            while let c = current {
                if let name = c.name {
                    if name == "btn_close_offer" {
                        close()
                        return
                    } else if name == "btn_railgun_rental" {
                        purchaseRailgun(product: .railgunRental)
                        return
                    } else if name == "btn_railgun_lifetime" {
                        purchaseRailgun(product: .railgunLifetime)
                        return
                    }
                }
                current = c.parent
                if c == self { break }
            }
        }
    }
    
    private func purchaseRailgun(product: IAPProduct) {
        // Animate button press
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.impactOccurred()
        
        onPurchase?(product)
        
        // Call IAPManager
        IAPManager.shared.purchase(product) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.showSuccess()
                } else if let error = error {
                    print("[SpecialOfferUI] Purchase failed: \(error)")
                }
            }
        }
    }
    
    private func showSuccess() {
        // Success animation
        let successLbl = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        successLbl.text = "✓ UNLOCKED!"
        successLbl.fontSize = 24
        successLbl.fontColor = .green
        successLbl.position = CGPoint(x: 0, y: 0)
        successLbl.setScale(0)
        containerNode.addChild(successLbl)
        
        successLbl.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in self?.close() }
        ]))
    }
    
    private func close() {
        run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.run { [weak self] in
                self?.onClose?()
            },
            SKAction.removeFromParent()
        ]))
    }
}
