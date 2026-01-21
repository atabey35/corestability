// QuestPassUI.swift
// CoreStability
// UI for Daily Quests and Battle Pass

import SpriteKit

class QuestPassUI: SKNode {
    
    // MARK: - Properties
    
    private let background: SKShapeNode
    private let width: CGFloat
    private let height: CGFloat
    
    // Containers
    private var questContainer: SKNode?
    private var passContainer: SKNode?
    
    // Callbacks
    var onClose: (() -> Void)?
    
    // Scroll state for Battle Pass
    private var scrollNode: SKNode?
    private var lastTouchY: CGFloat = 0
    private var scrollY: CGFloat = 0
    private let rowHeight: CGFloat = 80
    
    // MARK: - Init
    
    init(size: CGSize) {
        self.width = size.width * 0.9
        self.height = size.height * 0.85
        
        // Modal Background
        let rect = CGRect(x: -width/2, y: -height/2, width: width, height: height)
        background = SKShapeNode(rect: rect, cornerRadius: 20)
        background.fillColor = SKColor(white: 0.1, alpha: 0.95)
        background.strokeColor = .orange
        background.lineWidth = 2
        background.name = "popupBackground" // Fix for touch fallthrough
        
        super.init()
        
        setupLayer()
        setupHeader()
        setupTabs()
        showQuests() // Default tab
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupLayer() {
        let bg = SKShapeNode(rectOf: CGSize(width: 3000, height: 3000))
        bg.fillColor = SKColor.black.withAlphaComponent(0.5)
        bg.strokeColor = .clear
        bg.name = "questDimmer"
        addChild(bg)
        
        addChild(background)
        
        isUserInteractionEnabled = true
        zPosition = 1000
    }
    
    private func setupHeader() {
        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "QUESTS & PASS"
        title.fontSize = 32
        title.fontColor = .orange
        title.position = CGPoint(x: 0, y: height/2 - 50)
        background.addChild(title)
        
        // Close Button
        let closeBtn = SKShapeNode(circleOfRadius: 20)
        closeBtn.fillColor = .red
        closeBtn.position = CGPoint(x: width/2 - 30, y: height/2 - 30)
        closeBtn.name = "questClose"
        
        let xLabel = SKLabelNode(text: "✕")
        xLabel.fontName = "AvenirNext-Bold"
        xLabel.fontSize = 20
        xLabel.verticalAlignmentMode = .center
        closeBtn.addChild(xLabel)
        
        background.addChild(closeBtn)
    }
    
    private func setupTabs() {
        let questTab = createTabButton(text: "DAILY QUESTS", x: -width/4, selected: true)
        questTab.name = "tab_quest"
        background.addChild(questTab)
        
        let passTab = createTabButton(text: "BATTLE PASS", x: width/4, selected: false)
        passTab.name = "tab_pass"
        background.addChild(passTab)
    }
    
    private func createTabButton(text: String, x: CGFloat, selected: Bool) -> SKShapeNode {
        let btn = SKShapeNode(rectOf: CGSize(width: width/2 - 20, height: 50), cornerRadius: 10)
        btn.fillColor = selected ? .orange : .darkGray
        btn.strokeColor = .clear
        btn.position = CGPoint(x: x, y: height/2 - 110)
        
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = text
        label.fontSize = 20
        label.fontColor = selected ? .black : .white
        label.verticalAlignmentMode = .center
        label.name = "label"
        btn.addChild(label)
        
        return btn
    }
    
    // MARK: - Quests View
    
    private func showQuests() {
        clearContent()
        updateTabs(selected: "tab_quest")
        
        let container = SKNode()
        questContainer = container
        background.addChild(container)
        
        DailyQuestManager.shared.refreshIfNeeded()
        let quests = DailyQuestManager.shared.quests
        
        let startY: CGFloat = 100
        let spacing: CGFloat = 120
        
        if quests.isEmpty {
             let lbl = SKLabelNode(text: "No quests available.")
             lbl.fontSize = 24
             container.addChild(lbl)
             return
        }
        
        for (i, quest) in quests.enumerated() {
            let y = startY - (CGFloat(i) * spacing)
            
            let bg = SKShapeNode(rectOf: CGSize(width: width - 60, height: 100), cornerRadius: 12)
            bg.fillColor = SKColor(white: 0.2, alpha: 1)
            bg.position = CGPoint(x: 0, y: y)
            container.addChild(bg)
            
            // Description
            let desc = SKLabelNode(text: quest.description)
            desc.fontSize = 20
            desc.fontName = "AvenirNext-Bold"
            desc.horizontalAlignmentMode = .left
            desc.position = CGPoint(x: -width/2 + 50, y: y + 25)
            container.addChild(desc)
            
            // Rewards (Right aligned, same line as Desc)
            var rewardText = ""
            if quest.coinReward > 0 { rewardText += "\(quest.coinReward) 💰 " }
            if quest.gemReward > 0 { rewardText += "\(quest.gemReward) 💎" }
            
            let rLbl = SKLabelNode(text: rewardText)
            rLbl.fontSize = 16
            rLbl.fontColor = .yellow
            rLbl.horizontalAlignmentMode = .right
            rLbl.position = CGPoint(x: width/2 - 60, y: y + 25)
            container.addChild(rLbl)
            
            // Action Button (Bottom Right)
            let canClaim = DailyQuestManager.shared.canClaim(quest: quest)
            let isClaimed = DailyQuestManager.shared.claimedQuestIDs.contains(quest.id)
            
            let btn = SKShapeNode(rectOf: CGSize(width: 80, height: 35), cornerRadius: 5)
            btn.position = CGPoint(x: width/2 - 80, y: y - 15)
            
            if isClaimed {
                btn.fillColor = .gray
                btn.name = "claimed"
            } else if canClaim {
                btn.fillColor = .green
                btn.name = "claim_quest_\(quest.id)"
            } else {
                btn.fillColor = .darkGray
                btn.name = "locked"
                btn.alpha = 0.5
            }
            container.addChild(btn)
            
            let btnLbl = SKLabelNode(text: isClaimed ? "DONE" : (canClaim ? "CLAIM" : "GO"))
            btnLbl.fontName = "AvenirNext-Bold"
            btnLbl.fontSize = 14
            btnLbl.fontColor = isClaimed ? .lightGray : .black
            btnLbl.verticalAlignmentMode = .center
            btn.addChild(btnLbl)
            
            // Progress Bar (Bottom Left, taking up rest of space)
            let progressWidth: CGFloat = width - 250 // Dynamic width
            let pBg = SKShapeNode(rectOf: CGSize(width: progressWidth, height: 15), cornerRadius: 7)
            pBg.fillColor = .black
            // Position: Left anchored + offset
            pBg.position = CGPoint(x: -width/2 + 50 + progressWidth/2, y: y - 15)
            container.addChild(pBg)
            
            let ratio = CGFloat(min(quest.progress, quest.target)) / CGFloat(quest.target)
            if ratio > 0 {
                let pFill = SKShapeNode(rectOf: CGSize(width: progressWidth * ratio, height: 15), cornerRadius: 7)
                pFill.fillColor = .green
                pFill.position = CGPoint(x: -progressWidth/2 + (progressWidth * ratio)/2, y: 0)
                pBg.addChild(pFill)
            }
            
            let pText = SKLabelNode(text: quest.progressText)
            pText.fontSize = 12
            pText.fontName = "AvenirNext-Bold"
            pText.verticalAlignmentMode = .center
            pText.position = CGPoint(x: 0, y: 0) // Inside bar
            pText.zPosition = 2
            pBg.addChild(pText)
        }
    }
    
    // MARK: - Battle Pass View
    
    private func showPass() {
        clearContent()
        updateTabs(selected: "tab_pass")
        
        let container = SKNode()
        passContainer = container
        background.addChild(container)
        
        // Header Info
        let bp = BattlePassManager.shared
        let lvlInfo = SKLabelNode(text: "Level \(bp.currentLevel)")
        lvlInfo.fontSize = 28
        lvlInfo.fontColor = .white
        lvlInfo.position = CGPoint(x: 0, y: 120)
        container.addChild(lvlInfo)
        
        // XP Bar
        let barWidth: CGFloat = 300
        let barBg = SKShapeNode(rectOf: CGSize(width: barWidth, height: 20), cornerRadius: 10)
        barBg.fillColor = .black
        barBg.position = CGPoint(x: 0, y: 80)
        container.addChild(barBg)
        
        let ratio = CGFloat(bp.levelProgress)
        if ratio > 0 {
            let fill = SKShapeNode(rectOf: CGSize(width: barWidth * ratio, height: 20), cornerRadius: 10)
            fill.fillColor = .cyan
            fill.position = CGPoint(x: -barWidth/2 + (barWidth * ratio)/2, y: 0)
            barBg.addChild(fill)
        }
        
        let xpText = SKLabelNode(text: "\(bp.xpInCurrentLevel) / \(bp.xpPerLevel) XP")
        xpText.fontSize = 14
        xpText.position = CGPoint(x: 0, y: -5)
        barBg.addChild(xpText)
        
        // Headers
        let freeHeader = SKLabelNode(text: "FREE")
        freeHeader.fontSize = 18
        freeHeader.fontName = "AvenirNext-Bold"
        freeHeader.fontColor = .lightGray
        freeHeader.position = CGPoint(x: -width/4 - 10, y: 30) // Adjusted X
        container.addChild(freeHeader)
        
        let premHeader = SKLabelNode(text: "PREMIUM")
        premHeader.fontSize = 18
        premHeader.fontName = "AvenirNext-Bold"
        premHeader.fontColor = .yellow
        premHeader.position = CGPoint(x: width/4 + 10, y: 30)
        container.addChild(premHeader)
        
        // Separator Line
        let separator = SKShapeNode(rect: CGRect(x: -1, y: -height/2 + 20, width: 2, height: height/2 + 50))
        separator.fillColor = SKColor(white: 0.3, alpha: 0.5)
        separator.strokeColor = .clear
        separator.position = CGPoint(x: 0, y: 0)
        separator.zPosition = 5
        container.addChild(separator)
        
        // Scroll Container Mask

        let maskRect = CGRect(x: -width/2 + 20, y: -height/2 + 20, width: width - 40, height: height/2 - 20)
        let cropNode = SKCropNode()
        cropNode.maskNode = SKShapeNode(rect: maskRect, cornerRadius: 0) // Simple mask
        if let mask = cropNode.maskNode as? SKShapeNode {
            mask.fillColor = .white // REQUIRED for masking to work
        }
        // Actually, let's just use a defined area.
        
        // For simplicity, implement a manual scroll node
        let scroll = SKNode()
        self.scrollNode = scroll
        scroll.position = CGPoint(x: 0, y: 0)
        cropNode.addChild(scroll)
        cropNode.zPosition = 10
        container.addChild(cropNode)
        
        // Populate Levels
        let levels = 1...bp.maxLevel
        let startY: CGFloat = 0 // Relative to scroll node
        
        for level in levels {
            let y = startY - (CGFloat(level - 1) * rowHeight)
            
            // Row Bg
            let bg = SKShapeNode(rectOf: CGSize(width: width - 60, height: 70), cornerRadius: 8)
            bg.fillColor = (level <= bp.currentLevel) ? SKColor(white: 0.25, alpha: 1) : SKColor(white: 0.15, alpha: 1)
            bg.position = CGPoint(x: 0, y: y)
            scroll.addChild(bg)
            
            // Level Badge
            let lvlBadge = SKShapeNode(circleOfRadius: 20)
            lvlBadge.fillColor = (level <= bp.currentLevel) ? .orange : .gray
            lvlBadge.position = CGPoint(x: -width/2 + 60, y: y)
            scroll.addChild(lvlBadge)
            
            let lvlNum = SKLabelNode(text: "\(level)")
            lvlNum.fontSize = 16
            lvlNum.fontName = "AvenirNext-Bold"
            lvlNum.verticalAlignmentMode = .center
            lvlBadge.addChild(lvlNum)
            
            // Free Reward
            if let reward = BattlePassManager.freeRewards[level] {
                let node = createRewardNode(reward: reward, isPremium: false, level: level)
                node.position = CGPoint(x: -50, y: y)
                scroll.addChild(node)
            } else {
                 let dash = SKLabelNode(text: "-")
                 dash.position = CGPoint(x: -50, y: y - 5)
                 scroll.addChild(dash)
            }
            
            // Premium Reward
            if let reward = BattlePassManager.premiumRewards[level] {
                let node = createRewardNode(reward: reward, isPremium: true, level: level)
                node.position = CGPoint(x: 100, y: y)
                scroll.addChild(node)
            } else {
                // Lock icon if no premium pass? Or just empty
                 if !bp.hasPremiumPass {
                     let lock = SKLabelNode(text: "🔒")
                     lock.fontSize = 14
                     lock.position = CGPoint(x: 100, y: y - 5)
                     scroll.addChild(lock)
                 }
            }
        }
        
        // Initial scroll position: Center on current level
        let targetY = CGFloat(bp.currentLevel - 1) * rowHeight
        // Clamp
        scrollY = min(max(targetY, 0), CGFloat(bp.maxLevel) * rowHeight - 200)
        scroll.position.y = scrollY + 40 // Offset
    }
    
    private func createRewardNode(reward: BattlePassReward, isPremium: Bool, level: Int) -> SKNode {
        let node = SKNode()
        
        // Icon (Text for now)
        let icon = SKLabelNode(text: isPremium ? "🌟" : "🎁") // Simple icons
        icon.position = CGPoint(x: -20, y: -5)
        node.addChild(icon)
        
        // Text
        let lbl = SKLabelNode(text: reward.description)
        lbl.fontSize = 12
        lbl.horizontalAlignmentMode = .left
        lbl.preferredMaxLayoutWidth = 100
        lbl.numberOfLines = 2
        lbl.position = CGPoint(x: 0, y: 5)
        node.addChild(lbl)
        
        // Claim Status
        let bp = BattlePassManager.shared
        var canClaim = false
        var isClaimed = false
        
        if isPremium {
            canClaim = bp.canClaimPremium(level: level)
            isClaimed = bp.claimedPremiumLevels.contains(level)
            
            if !bp.hasPremiumPass {
                 // Locked
                 lbl.fontColor = .gray
            }
        } else {
            canClaim = bp.canClaimFree(level: level)
            isClaimed = bp.claimedFreeLevels.contains(level)
        }
        
        if canClaim {
            let btn = SKShapeNode(rectOf: CGSize(width: 60, height: 25), cornerRadius: 4)
            btn.fillColor = .green
            btn.position = CGPoint(x: 60, y: -15)
            btn.name = "claim_bp_\(isPremium ? "prem" : "free")_\(level)"
            node.addChild(btn)
            
            let cLbl = SKLabelNode(text: "GET")
            cLbl.fontSize = 10
            cLbl.fontColor = .black
            cLbl.verticalAlignmentMode = .center
            btn.addChild(cLbl)
        } else if isClaimed {
            let cLbl = SKLabelNode(text: "✓")
            cLbl.fontSize = 14
            cLbl.fontColor = .green
            cLbl.position = CGPoint(x: 60, y: -15)
            node.addChild(cLbl)
        }
        
        return node
    }
    
    // MARK: - Input
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Scroll Logic Init
        lastTouchY = location.y
        
        let nodes = nodes(at: location)
        for node in nodes {
            if let name = node.name {
                handleButton(name)
                return
            }
            if let parentName = node.parent?.name {
                handleButton(parentName)
                return
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let scroll = scrollNode else { return }
        let location = touch.location(in: self)
        let dy = location.y - lastTouchY
        lastTouchY = location.y
        
        // Update Scroll
        scrollY += dy
        
        // Clamp (Approximate)
        let maxScroll = CGFloat(BattlePassManager.shared.maxLevel) * rowHeight
        if scrollY < -100 { scrollY = -100 }
        if scrollY > maxScroll { scrollY = maxScroll }
        
        scroll.position.y = scrollY
    }
    
    private func handleButton(_ name: String) {
        if name == "questDimmer" || name == "questClose" {
            onClose?()
            removeFromParent()
        }
        else if name == "popupBackground" {
            // Do nothing, just consume touch
            return
        }
        else if name == "tab_quest" {
            showQuests()
        }
        else if name == "tab_pass" {
            showPass()
        }
        else if name.starts(with: "claim_quest_") {
            let id = String(name.dropFirst(12)) // "claim_quest_ID"
            // Find reference to GameScene's CurrencyManager via Singleton or Scene?
            // Ideally should pass dependency. For now, assume global Managers or we need to access GameScene.
            // Let's use `CurrencyManager` if it was a singleton, but it's not.
            // We'll rely on `onClose` to update things, but we need to award coins.
            // Wait, `CurrencyManager` is instance of GameScene.
            // I need to access GameScene instance.
            if let scene = scene as? GameScene {
                // Need public accessor in GameScene or pass in init
                // Making a quick hack: traverse scene
                if let reward = DailyQuestManager.shared.claimReward(questID: id, currencyManager: scene.currencyManager) {
                     print("Claimed Quest: \(reward.description)")
                     showQuests() // Refresh
                }
            }
        }
        else if name.starts(with: "claim_bp_") {
            // "claim_bp_free_5"
            let parts = name.components(separatedBy: "_")
            if parts.count >= 4, let level = Int(parts[3]) {
                let isPremium = parts[2] == "prem"
                if let scene = scene as? GameScene {
                    if isPremium {
                        _ = BattlePassManager.shared.claimPremiumReward(level: level, currencyManager: scene.currencyManager)
                    } else {
                        _ = BattlePassManager.shared.claimFreeReward(level: level, currencyManager: scene.currencyManager)
                    }
                    showPass() // Refresh
                }
            }
        }
    }
    
    private func clearContent() {
        questContainer?.removeFromParent()
        passContainer?.removeFromParent()
        questContainer = nil
        passContainer = nil
        scrollNode = nil
    }
    
    private func updateTabs(selected: String) {
       if let t1 = background.childNode(withName: "tab_quest") as? SKShapeNode,
          let t2 = background.childNode(withName: "tab_pass") as? SKShapeNode {
           let isQuest = selected == "tab_quest"
           t1.fillColor = isQuest ? .orange : .darkGray
           (t1.childNode(withName: "label") as? SKLabelNode)?.fontColor = isQuest ? .black : .white
           
           t2.fillColor = !isQuest ? .orange : .darkGray
           (t2.childNode(withName: "label") as? SKLabelNode)?.fontColor = !isQuest ? .black : .white
       }
    }
}
