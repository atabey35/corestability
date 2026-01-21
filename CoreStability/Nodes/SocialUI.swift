// SocialUI.swift
// CoreStability
// UI for Leaderboards and Clan Management

import SpriteKit
import GameKit

class SocialUI: SKNode {
    
    // MARK: - Properties
    
    private let background: SKShapeNode
    private let width: CGFloat
    private let height: CGFloat
    
    // Containers
    private var lbContainer: SKNode?
    private var clanContainer: SKNode?
    
    // Callbacks
    var onClose: (() -> Void)?
    
    // MARK: - Init
    
    init(size: CGSize) {
        self.width = size.width * 0.9
        self.height = size.height * 0.85
        
        // Modal Background
        let rect = CGRect(x: -width/2, y: -height/2, width: width, height: height)
        background = SKShapeNode(rect: rect, cornerRadius: 20)
        background.fillColor = SKColor(white: 0.1, alpha: 0.95)
        background.strokeColor = .blue
        background.lineWidth = 2
        background.name = "popupBackground"
        
        super.init()
        
        setupLayer()
        setupHeader()
        setupTabs()
        showLeaderboard() // Default tab
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupLayer() {
        let bg = SKShapeNode(rectOf: CGSize(width: 3000, height: 3000))
        bg.fillColor = SKColor.black.withAlphaComponent(0.5)
        bg.strokeColor = .clear
        bg.name = "socialDimmer"
        addChild(bg)
        
        addChild(background)
        
        isUserInteractionEnabled = true
        zPosition = 1000
    }
    
    private func setupHeader() {
        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "SOCIAL HUB"
        title.fontSize = 32
        title.fontColor = .blue
        title.position = CGPoint(x: 0, y: height/2 - 50)
        background.addChild(title)
        
        // Close Button
        let closeBtn = SKShapeNode(circleOfRadius: 20)
        closeBtn.fillColor = .red
        closeBtn.position = CGPoint(x: width/2 - 30, y: height/2 - 30)
        closeBtn.name = "socialClose"
        
        let xLabel = SKLabelNode(text: "✕")
        xLabel.fontName = "AvenirNext-Bold"
        xLabel.fontSize = 20
        xLabel.verticalAlignmentMode = .center
        closeBtn.addChild(xLabel)
        
        background.addChild(closeBtn)
    }
    
    private func setupTabs() {
        let lbTab = createTabButton(text: "LEADERBOARD", x: 0, selected: true)
        lbTab.name = "tab_lb"
        background.addChild(lbTab)
        
        // Clan tab removed per user request
    }
    
    private func createTabButton(text: String, x: CGFloat, selected: Bool) -> SKShapeNode {
        let btn = SKShapeNode(rectOf: CGSize(width: width/2 - 20, height: 50), cornerRadius: 10)
        btn.fillColor = selected ? .blue : .darkGray
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
    
    // MARK: - Leaderboard View
    
    private func showLeaderboard() {
        clearContent()
        updateTabs(selected: "tab_lb")
        
        let container = SKNode()
        lbContainer = container
        background.addChild(container)
        
        // Game Center Button
        let gcBtn = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 10)
        gcBtn.fillColor = .white
        gcBtn.position = CGPoint(x: 0, y: height/2 - 180)
        gcBtn.name = "open_gc"
        container.addChild(gcBtn)
        
        let gcLbl = SKLabelNode(text: "Open Game Center 🎮")
        gcLbl.fontName = "AvenirNext-Bold"
        gcLbl.fontSize = 18
        gcLbl.fontColor = .black
        gcLbl.verticalAlignmentMode = .center
        gcBtn.addChild(gcLbl)
        
        // Mock List Title
        let listTitle = SKLabelNode(text: "Top Players (Global)")
        listTitle.fontSize = 20
        listTitle.fontColor = .lightGray
        listTitle.position = CGPoint(x: 0, y: height/2 - 240)
        container.addChild(listTitle)
        
        // List entries - show Chapter/Wave format
        let entries = LeaderboardManager.shared.getLeaderboard(type: .allTime).prefix(5)
        let startY: CGFloat = height/2 - 290
        let spacing: CGFloat = 60
        
        for (i, entry) in entries.enumerated() {
             let y = startY - (CGFloat(i) * spacing)
            
            let bg = SKShapeNode(rectOf: CGSize(width: width - 60, height: 50), cornerRadius: 8)
            bg.fillColor = (entry.playerName == LeaderboardManager.shared.playerName) ? .blue : SKColor(white: 0.2, alpha: 1)
            bg.position = CGPoint(x: 0, y: y)
            container.addChild(bg)
            
            // Rank
            let rank = SKLabelNode(text: "#\(entry.rank)")
            rank.fontSize = 18
            rank.fontName = "AvenirNext-Bold"
            rank.position = CGPoint(x: -width/2 + 60, y: y - 5)
            container.addChild(rank)
            
            // Name (shorter to make room)
            let displayName = entry.playerName.count > 12 ? String(entry.playerName.prefix(10)) + ".." : entry.playerName
            let name = SKLabelNode(text: displayName)
            name.fontSize = 16
            name.fontName = "AvenirNext-Medium"
            name.horizontalAlignmentMode = .left
            name.position = CGPoint(x: -width/2 + 100, y: y - 5)
            container.addChild(name)
            
            // Chapter/Wave Display
            let progressText = "Ch.\(entry.chapter) W.\(entry.wave)"
            let progress = SKLabelNode(text: progressText)
            progress.fontSize = 14
            progress.fontName = "AvenirNext-Bold"
            progress.fontColor = .cyan
            progress.horizontalAlignmentMode = .right
            progress.position = CGPoint(x: width/2 - 60, y: y - 5)
            container.addChild(progress)
        }
    }
    
    // MARK: - Clan View
    
    private func showClan() {
        clearContent()
        updateTabs(selected: "tab_clan")
        
        let container = SKNode()
        clanContainer = container
        background.addChild(container)
        
        if let clan = ClanManager.shared.currentClan {
            showMyClan(clan, in: container)
        } else {
            showJoinClan(in: container)
        }
    }
    
    private func showMyClan(_ clan: Clan, in container: SKNode) {
        // Clan Header
        let name = SKLabelNode(text: "[\(clan.tag)] \(clan.name)")
        name.fontSize = 28
        name.fontName = "AvenirNext-Bold"
        name.fontColor = .white
        name.position = CGPoint(x: 0, y: 150)
        container.addChild(name)
        
        let lvl = SKLabelNode(text: "Level \(clan.level)")
        lvl.fontSize = 20
        lvl.fontColor = .cyan
        lvl.position = CGPoint(x: 0, y: 110)
        container.addChild(lvl)
        
        // XP Bar
        let barWidth: CGFloat = 300
        let barBg = SKShapeNode(rectOf: CGSize(width: barWidth, height: 15), cornerRadius: 7)
        barBg.fillColor = .black
        barBg.position = CGPoint(x: 0, y: 80)
        container.addChild(barBg)
        
        let ratio = CGFloat(clan.experience) / CGFloat(clan.xpForNextLevel)
        if ratio > 0 {
            let fill = SKShapeNode(rectOf: CGSize(width: barWidth * ratio, height: 15), cornerRadius: 7)
            fill.fillColor = .blue
            fill.position = CGPoint(x: -barWidth/2 + (barWidth * ratio)/2, y: 0)
            barBg.addChild(fill)
        }
        
        // Buttons
        let donateBtn = createButton(text: "Donate 100 💎", color: .purple, y: -50)
        donateBtn.name = "clan_donate"
        container.addChild(donateBtn)
        
        let leaveBtn = createButton(text: "Leave Clan", color: .red, y: -130)
        leaveBtn.name = "clan_leave"
        container.addChild(leaveBtn)
        
        // Bonuses List
        let bonuses = ClanManager.shared.getClanBonuses()
        let bonusTitle = SKLabelNode(text: "Active Bonuses:")
        bonusTitle.fontSize = 16
        bonusTitle.fontColor = .gray
        bonusTitle.position = CGPoint(x: 0, y: 20)
        container.addChild(bonusTitle)
        
        for (i, b) in bonuses.enumerated() {
             let lbl = SKLabelNode(text: "• \(b.description)")
             lbl.fontSize = 14
             lbl.fontName = "AvenirNext-Medium"
             lbl.position = CGPoint(x: 0, y: 0 - (CGFloat(i) * 20))
            // Adjust position relative to bonus title if list is long?
            // placing them lower
             lbl.position = CGPoint(x: 0, y: -100 - (CGFloat(i) * 20) - 100) // Below buttons
             // Actually, let's put them above donate
             lbl.position = CGPoint(x: 0, y: 0 - (CGFloat(i+1) * 20))
             container.addChild(lbl)
        }
    }
    
    private func showJoinClan(in container: SKNode) {
        let title = SKLabelNode(text: "No Clan")
        title.fontSize = 24
        title.position = CGPoint(x: 0, y: 150)
        container.addChild(title)
        
        // Create Button
        let createBtn = createButton(text: "Create Clan (500 💎)", color: .green, y: 90)
        createBtn.name = "clan_create"
        container.addChild(createBtn)
        
        // List Title
        let sub = SKLabelNode(text: "Available Clans:")
        sub.fontSize = 18
        sub.fontColor = .gray
        sub.position = CGPoint(x: 0, y: 30)
        container.addChild(sub)
        
        // Mock List
        let clans = ClanManager.shared.getAvailableClans().prefix(3)
        let startY: CGFloat = -20
        let spacing: CGFloat = 70
        
        for (i, clan) in clans.enumerated() {
            let y = startY - (CGFloat(i) * spacing)
            
            let bg = SKShapeNode(rectOf: CGSize(width: width - 80, height: 60), cornerRadius: 8)
            bg.fillColor = SKColor(white: 0.2, alpha: 1)
            bg.position = CGPoint(x: 0, y: y)
            container.addChild(bg)
            
            let name = SKLabelNode(text: "[\(clan.tag)] \(clan.name)")
            name.fontSize = 18
            name.fontName = "AvenirNext-Bold"
            name.horizontalAlignmentMode = .left
            name.position = CGPoint(x: -width/2 + 60, y: y + 5)
            container.addChild(name)
            
            let info = SKLabelNode(text: "Lvl \(clan.level) • \(clan.memberIDs.count) Members")
            info.fontSize = 14
            info.fontColor = .gray
            info.horizontalAlignmentMode = .left
            info.position = CGPoint(x: -width/2 + 60, y: y - 15)
            container.addChild(info)
            
            let join = SKShapeNode(rectOf: CGSize(width: 80, height: 30), cornerRadius: 5)
            join.fillColor = .blue
            join.position = CGPoint(x: width/2 - 90, y: y)
            join.name = "clan_join_mock_\(i)" // Using index as ID for mock
            container.addChild(join)
            
            let jLbl = SKLabelNode(text: "JOIN")
            jLbl.fontSize = 14
            jLbl.verticalAlignmentMode = .center
            join.addChild(jLbl)
        }
    }
    
    private func createButton(text: String, color: SKColor, y: CGFloat) -> SKShapeNode {
        let btn = SKShapeNode(rectOf: CGSize(width: 220, height: 50), cornerRadius: 10)
        btn.fillColor = color
        btn.position = CGPoint(x: 0, y: y)
        
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 18
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        btn.addChild(label)
        
        return btn
    }
    
    // MARK: - Interaction
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
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
    
    private func handleButton(_ name: String) {
        if name == "socialDimmer" || name == "socialClose" {
            onClose?()
            removeFromParent()
        }
        else if name == "popupBackground" { return }
        else if name == "tab_lb" {
            showLeaderboard()
        }
        else if name == "tab_clan" {
            showClan()
        }
        else if name == "open_gc" {
             if let scene = scene, let view = scene.view, let vc = view.window?.rootViewController {
                 GameCenterManager.shared.showLeaderboard(from: vc, leaderboardID: "com.corestability.leaderboard.highscore")
             }
        }
        else if name == "clan_donate" {
            if ClanManager.shared.contributeGems(100) {
                 showClan() // Refresh
            }
        }
        else if name == "clan_leave" {
            if ClanManager.shared.leaveClan() {
                 showClan()
            }
        }
        else if name == "clan_create" {
            // Mock Create
            if ClanManager.shared.createClan(name: "My New Clan", tag: "NEW") {
                 showClan()
            } else {
                 print("Failed to create clan (Insufficient gems?)")
            }
        }
        else if name.starts(with: "clan_join_") {
             // Mock Join
             // In real app, we'd parse ID.
             let list = ClanManager.shared.getAvailableClans()
             if let index = Int(name.components(separatedBy: "_").last ?? ""), index < list.count {
                 let clan = list[index]
                 if ClanManager.shared.joinClan(clan) {
                     showClan()
                 }
             }
        }
    }
    
    private func clearContent() {
        lbContainer?.removeFromParent()
        clanContainer?.removeFromParent()
        lbContainer = nil
        clanContainer = nil
    }
    
    private func updateTabs(selected: String) {
       if let t1 = background.childNode(withName: "tab_lb") as? SKShapeNode,
          let t2 = background.childNode(withName: "tab_clan") as? SKShapeNode {
           let isLb = selected == "tab_lb"
           t1.fillColor = isLb ? .blue : .darkGray
           (t1.childNode(withName: "label") as? SKLabelNode)?.fontColor = isLb ? .black : .white
           
           t2.fillColor = !isLb ? .blue : .darkGray
           (t2.childNode(withName: "label") as? SKLabelNode)?.fontColor = !isLb ? .black : .white
       }
    }
}
