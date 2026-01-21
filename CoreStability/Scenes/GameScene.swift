// GameScene.swift
// Idle Tower Defense
// Main game scene - orchestrates tower, enemies, projectiles, waves

import SpriteKit
import GameplayKit

// MARK: - Localization Extension
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

/// Shortcut function for localization with format arguments
func L(_ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, comment: "")
    return String(format: format, arguments: args)
}

final class GameScene: SKScene {
    
    // MARK: - Core Components
    
    private var tower: TowerNode!
    private var enemySpawner: EnemySpawner!
    private var projectileManager: ProjectileManager!
    private var waveController: WaveController!
    var currencyManager: CurrencyManager!
    
    // Turrets
    private var turrets: [TurretNode] = []
    
    // MARK: - UI
    
    private var waveLabel: SKLabelNode!
    private var coinsLabel: SKLabelNode!
    private var gemsLabel: SKLabelNode!          // NEW: Premium currency
    private var dailyRewardBtn: SKShapeNode!     // NEW: Daily login
    private var shopBtn: SKShapeNode!            // NEW: Shop & Gacha
    private var questBtn: SKShapeNode!           // NEW: Quest & Battle Pass
    private var socialBtn: SKShapeNode!          // NEW: Social & Clan
    private var hpBar: SKShapeNode!
    private var hpBarFill: SKShapeNode!
    private var speedButton: SKLabelNode!
    
    // MARK: - State
    
    private var lastUpdateTime: TimeInterval = 0
    var gameSpeed: CGFloat = 1.0
    private let speedOptions: [CGFloat] = [1.0, 2.0, 3.5]
    private var speedIndex: Int = 0
    
    // Texture Cache
    private var textureCache: [String: SKTexture] = [:]
    
    // MARK: - Market & Skills
    
    private var upgradeManager: UpgradeManager!
    private var marketNode: SKNode!
    private var statPanel: SKNode!
    private var isGameOver: Bool = false
    
    private var skillUziBtn: SKShapeNode!
    private var skillRocketBtn: SKShapeNode!
    private var skillFreezeBtn: SKShapeNode!
    private var skillLaserBtn: SKShapeNode!   // NEW
    private var skillShieldBtn: SKShapeNode!  // NEW
    private var skillEmpBtn: SKShapeNode!
    
    private var uziCooldown: TimeInterval = 0
    private var rocketCooldown: TimeInterval = 0
    private var freezeCooldown: TimeInterval = 0
    private var laserCooldown: TimeInterval = 0   // NEW
    private var shieldCooldown: TimeInterval = 0  // NEW
    private var empCooldown: TimeInterval = 0
    
    private let uziMaxCooldown: TimeInterval = 25
    private let rocketMaxCooldown: TimeInterval = 12
    private let freezeMaxCooldown: TimeInterval = 20
    private let laserMaxCooldown: TimeInterval = 15
    private let shieldMaxCooldown: TimeInterval = 45
    private let empMaxCooldown: TimeInterval = 90
    
    private var isMarketOpen: Bool = false
    
    // MARK: - Target Priority
    
    private var targetPriority: TargetPriority = .closest
    
    // MARK: - Wave Modifiers & Passives
    
    private var currentWaveModifier: WaveModifier = .normal
    private var waveModifierLabel: SKLabelNode!
    private var passiveManager = PassiveUpgradeManager()
    
    // MARK: - Pause Menu
    
    private var isGamePaused: Bool = false
    
    // Heal Button
    private var healButton: SKShapeNode!
    
    // MARK: - Optimization Helpers
    
    
    // MARK: - Optimization Helpers
    
    private func getCachedTexture(name: String) -> SKTexture? {
        if let cached = textureCache[name] {
            return cached
        }
        
        // Asset Catalog (Prioritize Assets over Symbols)
        // Explicitly check for known asset prefixes or just try loading
        // Added Sprite suffixes for skills
        if name.hasPrefix("skill_") || name.hasPrefix("iap_") || name.hasPrefix("weapon_") || name.hasSuffix("Sprite") {
             let texture = SKTexture(imageNamed: name)
             if texture.size() != .zero {
                 textureCache[name] = texture
                 return texture
             }
        }
        
        // SF Symbol Fallback
        if let symbolTex = SKTexture.fromSymbol(name: name, pointSize: 40) {
            return symbolTex
        }
        
        return nil
    }
    
    // Perks
    private var activePerkOptions: [Perk] = []
    private var pauseButton: SKLabelNode!
    private var pauseOverlay: SKNode?
    private var splashOverlay: SKNode?
    private var isGameStarted: Bool = false
    
    // MARK: - Visual Feedback & Combo
    
    private var visualFeedback: VisualFeedbackSystem!
    private var lastHPCheck: CGFloat = 1.0
    
    // Skill States
    private var isShieldActive: Bool = false
    
    // Blade System (New)
    private var bladeNode: SKSpriteNode?
    private var bladeAngle: CGFloat = 0
    private var bladeHitTimers: [SKNode: TimeInterval] = [:] // Cooldown per enemy
    
    // Special Offer Tracking
    private var sessionStartTime: Date = Date()
    private static var consecutiveDeaths: Int = 0 // Static to persist across restarts
    
    // MARK: - Lifecycle
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        // Initialize Combo Manager
        ComboManager.shared.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(onComboMilestone(_:)), name: .comboMilestone, object: nil)
        
        // Lifecycle - Pause/Resume
        NotificationCenter.default.addObserver(self, selector: #selector(onAppWillResignActive), name: .appWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAppDidBecomeActive), name: .appDidBecomeActive, object: nil)
        
        setupScene()
        setupTower()
        setupSystems()
        setupUI()
        setupInputs()
        setupCamera()
        setupAudio()
        
        lastUpdateTime = 0
        
        // Start game
        if let bonus = AchievementManager.shared.startGoldBonus as Int?, bonus > 0 {
             currencyManager.addCoins(bonus)
        }
        

        
        waveController.reset()
        
        // Sync Game Center on Launch
        if let vc = view.window?.rootViewController {
            GameCenterManager.shared.authenticatePlayer(presentingViewController: vc) { success, _ in
                if success {
                    // Report saved High Wave to Leaderboard
                    let bestWave = AchievementManager.shared.highestWave
                    if bestWave > 0 {
                        GameCenterManager.shared.submitWave(bestWave)
                        // Estimate score (Chapter 1 * 1000 + Wave) ~ approx
                        // Ideally we'd save High Score too, but wave is priority request
                    }
                }
            }
        }
        
        // Show splash screen at start
        showSplashScreen()
    }
    
    // MARK: - Splash Screen
    
    private func showSplashScreen() {
        isGamePaused = true
        
        let overlay = SKNode()
        overlay.name = "splashOverlay"
        overlay.zPosition = 5000
        splashOverlay = overlay
        addChild(overlay)
        
        // Dark background
        let bg = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        bg.fillColor = SKColor(red: 0.02, green: 0.02, blue: 0.05, alpha: 1.0)
        bg.strokeColor = .clear
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(bg)
        
        // Title glow
        let titleGlow = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleGlow.text = "HEXAGONAL".localized
        titleGlow.fontSize = 42
        titleGlow.fontColor = SKColor.cyan.withAlphaComponent(0.3)
        titleGlow.position = CGPoint(x: size.width / 2 + 2, y: size.height * 0.65 + 20)
        overlay.addChild(titleGlow)
        
        let titleGlow2 = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleGlow2.text = "TOWER DEFENSE".localized
        titleGlow2.fontSize = 42
        titleGlow2.fontColor = SKColor.cyan.withAlphaComponent(0.3)
        titleGlow2.position = CGPoint(x: size.width / 2 + 2, y: size.height * 0.65 - 20)
        overlay.addChild(titleGlow2)
        
        // Title
        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = "HEXAGONAL".localized
        title.fontSize = 42
        title.fontColor = .cyan
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.65 + 18)
        overlay.addChild(title)
        
        let title2 = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title2.text = "TOWER DEFENSE".localized
        title2.fontSize = 42
        title2.fontColor = .cyan
        title2.position = CGPoint(x: size.width / 2, y: size.height * 0.65 - 22)
        overlay.addChild(title2)
        
        // Subtitle (Removed or changed to something else if needed, user didn't specify)
        let subtitle = SKLabelNode(fontNamed: "AvenirNext-Medium")
        subtitle.text = "SCI-FI STRATEGY".localized
        subtitle.fontSize = 18
        subtitle.fontColor = SKColor(white: 0.6, alpha: 1)
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.65 - 60)
        overlay.addChild(subtitle)
        
        // Tower icon (Main Logo Transparent)
        let icon = SKSpriteNode(imageNamed: "TowerSprite") // Using the transparent tower sprite we generated
        // If the user wants the "App Icon fully transparent", and since the App Icon HAS the tower in it,
        // and we have a high-res TowerSprite asset, this is the best fit.
        // We can scale it up since it's 180px @3x which is plenty for 100x100.
        icon.size = CGSize(width: 140, height: 140) // Slightly larger
        icon.position = CGPoint(x: size.width / 2, y: size.height * 0.45)
        // icon.color = .cyan // Don't tint the sprite, let its natural neon colors show
        // icon.colorBlendFactor = 0.0
        overlay.addChild(icon)
        
        // Pulse animation
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 2.0),
            SKAction.scale(to: 1.0, duration: 2.0)
        ])
        icon.run(SKAction.repeatForever(pulse))
        
        // Start Button
        let startBtn = SKShapeNode(rectOf: CGSize(width: 220, height: 60), cornerRadius: 30)
        startBtn.fillColor = SKColor.cyan
        startBtn.strokeColor = SKColor.cyan.withAlphaComponent(0.5)
        startBtn.lineWidth = 3
        startBtn.glowWidth = 15
        startBtn.position = CGPoint(x: size.width / 2, y: size.height * 0.25)
        startBtn.name = "startGameBtn"
        overlay.addChild(startBtn)
        
        let startLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        startLabel.text = "START GAME".localized
        startLabel.fontSize = 22
        startLabel.fontColor = .black
        startLabel.verticalAlignmentMode = .center
        startBtn.addChild(startLabel)
        
        // Button pulse
        let btnPulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.8),
            SKAction.scale(to: 1.0, duration: 0.8)
        ])
        startBtn.run(SKAction.repeatForever(btnPulse))
        
        // Music icon hint
        if let musicIcon = SKTexture.fromSymbol(name: "speaker.wave.3.fill", pointSize: 16) {
            let icon = SKSpriteNode(texture: musicIcon)
            icon.size = CGSize(width: 16, height: 16)
            icon.position = CGPoint(x: size.width / 2 - 80, y: size.height * 0.15)
            icon.color = .gray
            icon.colorBlendFactor = 1.0
            overlay.addChild(icon)
        }
        
        let musicHint = SKLabelNode(fontNamed: "AvenirNext-Regular")
        musicHint.text = "Tap to enable sound".localized
        musicHint.fontSize = 12
        musicHint.fontColor = SKColor(white: 0.4, alpha: 1)
        musicHint.position = CGPoint(x: size.width / 2 + 10, y: size.height * 0.15 - 5)
        overlay.addChild(musicHint)
        
        // Version
        let version = SKLabelNode(fontNamed: "AvenirNext-Regular")
        version.text = "v1.0 - Arcade Edition"
        version.fontSize = 10
        version.fontColor = SKColor(white: 0.3, alpha: 1)
        version.position = CGPoint(x: size.width / 2, y: 30)
        overlay.addChild(version)
    }
    
    private func dismissSplashScreen() {
        guard let splash = splashOverlay else { return }
        
        // Start music
        AudioManager.shared.startBackgroundMusic()
        
        // Fade out
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        splash.run(SKAction.sequence([fadeOut, SKAction.removeFromParent()]))
        
        splashOverlay = nil
        isGameStarted = true
        isGamePaused = false
    }
    
    // MARK: - Setup
    
    private func setupScene() {
        // Dark background
        backgroundColor = SKColor(red: 0.04, green: 0.04, blue: 0.08, alpha: 1.0)  // #0A0A14
        
        // Grid (subtle)
        let gridPath = CGMutablePath()
        let spacing: CGFloat = 50
        
        var x: CGFloat = 0
        while x <= size.width {
            gridPath.move(to: CGPoint(x: x, y: 0))
            gridPath.addLine(to: CGPoint(x: x, y: size.height))
            x += spacing
        }
        
        var y: CGFloat = 0
        while y <= size.height {
            gridPath.move(to: CGPoint(x: 0, y: y))
            gridPath.addLine(to: CGPoint(x: size.width, y: y))
            y += spacing
        }
        
        let grid = SKShapeNode(path: gridPath)
        grid.strokeColor = SKColor(white: 0.1, alpha: 0.3)
        grid.lineWidth = 0.5
        grid.zPosition = -100
        addChild(grid)
    }
    
    private func setupTower() {
        tower = TowerNode()
        tower.position = CGPoint(x: size.width / 2, y: size.height / 2)
        tower.zPosition = 10
        addChild(tower)
    }
    
    private func setupSystems() {
        // Enemy spawner
        enemySpawner = EnemySpawner()
        enemySpawner.parentNode = self
        enemySpawner.screenSize = size
        enemySpawner.targetPosition = tower.position
        
        // Projectile manager
        projectileManager = ProjectileManager()
        projectileManager.parentNode = self
        projectileManager.delegate = self
        
        // Wave controller
        waveController = WaveController()
        waveController.delegate = self
        
        // Currency
        currencyManager = CurrencyManager()
        currencyManager.delegate = self
        
        // Upgrades
        upgradeManager = UpgradeManager.shared
        
        // Visual Feedback System
        visualFeedback = VisualFeedbackSystem()
        visualFeedback.parentNode = self
        visualFeedback.setupVignette(size: size)
    }
    
    private func setupUI() {
        // Wave label (Top - 15% down)
        waveLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        waveLabel.fontSize = 28
        waveLabel.fontColor = .cyan
        waveLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.85) // 15% down
        waveLabel.zPosition = 100
        waveLabel.text = "WAVE 1"
        addChild(waveLabel)
        
        // Coins label (top left)
        coinsLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        coinsLabel.fontSize = 24
        coinsLabel.fontColor = .yellow
        coinsLabel.horizontalAlignmentMode = .left
        coinsLabel.position = CGPoint(x: 30, y: size.height * 0.92)
        coinsLabel.zPosition = 100
        coinsLabel.text = "$ 0"
        addChild(coinsLabel)
        
        // Gems label (next to coins) - SF Symbol instead of emoji
        gemsLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        gemsLabel.fontSize = 22
        gemsLabel.fontColor = SKColor(red: 0.3, green: 0.9, blue: 0.95, alpha: 1.0) // Teal
        gemsLabel.horizontalAlignmentMode = .left
        gemsLabel.position = CGPoint(x: 50, y: size.height * 0.92 - 30)
        gemsLabel.zPosition = 100
        gemsLabel.text = "\(GemManager.shared.gems)"
        addChild(gemsLabel)
        
        // Gem Icon (SF Symbol)
        if let gemTexture = SKTexture.fromSymbol(name: "diamond.fill", pointSize: 18) {
            let gemIcon = SKSpriteNode(texture: gemTexture)
            gemIcon.size = CGSize(width: 18, height: 18)
            gemIcon.position = CGPoint(x: 30, y: size.height * 0.92 - 30)
            gemIcon.color = SKColor(red: 0.3, green: 0.9, blue: 0.95, alpha: 1.0)
            gemIcon.colorBlendFactor = 1.0
            gemIcon.zPosition = 100
            addChild(gemIcon)
        }
        
        // Quest Button (Removed)
        // Quest/Pass system deprecated per user request.
        
        // Social Button (Left side, below gems) - SF Symbol: trophy.fill
        socialBtn = SKShapeNode(rectOf: CGSize(width: 50, height: 50), cornerRadius: 10)
        socialBtn.fillColor = SKColor(red: 0.1, green: 0.2, blue: 0.4, alpha: 0.9)
        socialBtn.strokeColor = .cyan
        socialBtn.lineWidth = 2
        socialBtn.glowWidth = 3
        socialBtn.position = CGPoint(x: 40, y: size.height * 0.92 - 70)
        socialBtn.zPosition = 100
        socialBtn.name = "socialButton"
        addChild(socialBtn)
        
        if let socialTexture = SKTexture.fromSymbol(name: "trophy.fill", pointSize: 24) {
            let socialIcon = SKSpriteNode(texture: socialTexture)
            socialIcon.size = CGSize(width: 24, height: 24)
            socialIcon.position = CGPoint(x: 0, y: 0)
            socialIcon.color = .yellow
            socialIcon.colorBlendFactor = 1.0
            socialBtn.addChild(socialIcon)
        }
        
        // Shop Button (Top Right) - SF Symbol: cart.fill
        shopBtn = SKShapeNode(rectOf: CGSize(width: 50, height: 50), cornerRadius: 10)
        shopBtn.fillColor = SKColor(red: 0.3, green: 0.1, blue: 0.4, alpha: 0.9)
        shopBtn.strokeColor = .magenta
        shopBtn.lineWidth = 2
        shopBtn.glowWidth = 3
        shopBtn.position = CGPoint(x: size.width - 40, y: size.height * 0.92 - 10)
        shopBtn.zPosition = 100
        shopBtn.name = "shopButton"
        addChild(shopBtn)
        
        if let shopTexture = SKTexture.fromSymbol(name: "cart.fill", pointSize: 24) {
            let shopIcon = SKSpriteNode(texture: shopTexture)
            shopIcon.size = CGSize(width: 24, height: 24)
            shopIcon.position = CGPoint(x: 0, y: 0)
            shopIcon.color = .white
            shopIcon.colorBlendFactor = 1.0
            shopBtn.addChild(shopIcon)
        }
        
        // Market/Upgrade Button (below Shop) - SF Symbol: hammer.fill
        let marketBtn = SKShapeNode(rectOf: CGSize(width: 50, height: 50), cornerRadius: 10)
        marketBtn.fillColor = SKColor(red: 0.1, green: 0.3, blue: 0.2, alpha: 0.9)
        marketBtn.strokeColor = .green
        marketBtn.lineWidth = 2
        marketBtn.glowWidth = 3
        marketBtn.position = CGPoint(x: size.width - 40, y: size.height * 0.92 - 70)
        marketBtn.zPosition = 100
        marketBtn.name = "marketButton"
        addChild(marketBtn)
        
        if let marketTexture = SKTexture.fromSymbol(name: "hammer.fill", pointSize: 24) {
            let marketIcon = SKSpriteNode(texture: marketTexture)
            marketIcon.size = CGSize(width: 24, height: 24)
            marketIcon.position = CGPoint(x: 0, y: 0)
            marketIcon.color = .white
            marketIcon.colorBlendFactor = 1.0
            marketBtn.addChild(marketIcon)
        }
        
        // HP Bar (bottom)
        let barWidth: CGFloat = size.width - 40
        let barHeight: CGFloat = 16
        
        hpBar = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 8)
        hpBar.fillColor = SKColor(white: 0.1, alpha: 0.9)
        hpBar.strokeColor = .gray
        hpBar.lineWidth = 1
        hpBar.position = CGPoint(x: size.width / 2, y: 50)
        hpBar.zPosition = 100
        addChild(hpBar)
        
        hpBarFill = SKShapeNode(rectOf: CGSize(width: barWidth - 4, height: barHeight - 4), cornerRadius: 6)
        hpBarFill.fillColor = .green
        hpBarFill.strokeColor = .clear
        hpBarFill.position = CGPoint(x: size.width / 2, y: 50)
        hpBarFill.zPosition = 101
        addChild(hpBarFill)
        
        // Speed button (bottom right)
        speedButton = SKLabelNode(fontNamed: "AvenirNext-Bold")
        speedButton.fontSize = 20
        speedButton.fontColor = .cyan
        speedButton.position = CGPoint(x: 80, y: 300) // Moved to left side to avoid overlap
        speedButton.zPosition = 100
        speedButton.text = "x1.0"
        speedButton.name = "speedButton"
        addChild(speedButton)
        

        
        // Pause Button (Left side, below social) - SF Symbol: pause.circle.fill
        let pauseBtn = SKShapeNode(rectOf: CGSize(width: 44, height: 44), cornerRadius: 22)
        pauseBtn.fillColor = SKColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 0.9)
        pauseBtn.strokeColor = .white
        pauseBtn.lineWidth = 2
        pauseBtn.glowWidth = 2
        pauseBtn.position = CGPoint(x: 40, y: size.height * 0.92 - 140)
        pauseBtn.zPosition = 100
        pauseBtn.name = "pauseButton"
        addChild(pauseBtn)
        
        if let pauseTexture = SKTexture.fromSymbol(name: "pause.circle.fill", pointSize: 28) {
            let pauseIcon = SKSpriteNode(texture: pauseTexture)
            pauseIcon.size = CGSize(width: 28, height: 28)
            pauseIcon.position = CGPoint(x: 0, y: 0)
            pauseIcon.color = .white
            pauseIcon.colorBlendFactor = 1.0
            pauseBtn.addChild(pauseIcon)
        }
        
        // Fix: Larger touch area for easier pausing
        let pauseHitArea = SKShapeNode(circleOfRadius: 40)
        pauseHitArea.fillColor = .white
        pauseHitArea.alpha = 0.001
        pauseHitArea.position = CGPoint.zero
        pauseHitArea.name = "pauseButton"
        pauseBtn.addChild(pauseHitArea)
        
        setupHealButton()
        
        // Wave Modifier Label (Top Center)
        waveModifierLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        waveModifierLabel.fontSize = 14
        waveModifierLabel.fontColor = .yellow
        waveModifierLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.92)
        waveModifierLabel.zPosition = 100
        waveModifierLabel.text = ""
        addChild(waveModifierLabel)
        
        // Active Buffs HUD (Left side, below pause/leaderboard)
        let buffsHUD = ActiveBuffsHUD()
        buffsHUD.position = CGPoint(x: 40, y: size.height * 0.70)
        buffsHUD.zPosition = 90
        addChild(buffsHUD)
        
        setupSkillsUI()
        setupStatPanel()
        setupMarketUI()
        
        // Initial Stat Update
        updateTowerStats()
    }
    
    private func setupInputs() {
        isUserInteractionEnabled = true
        view?.isMultipleTouchEnabled = true
    }
    
    private func setupCamera() {
        let cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)
        cameraNode.position = CGPoint(x: size.width/2, y: size.height/2)
    }
    
    private func setupAudio() {
        // AudioManager.shared.playBackground() // Not implemented
    }
    
    @objc private func onComboMilestone(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let coins = userInfo["coins"] as? Int,
           let _ = userInfo["combo"] as? Int {
            
            currencyManager.addCoins(coins)
            showFloatingText("+\(coins) COINS!", at: tower.position, color: .yellow)
            AudioManager.shared.playUpgrade()
            
            // Visual flair
            let flare = SKShapeNode(circleOfRadius: 50)
            flare.strokeColor = .yellow
            flare.lineWidth = 4
            flare.position = tower.position
            addChild(flare)
            flare.run(SKAction.sequence([
                SKAction.scale(to: 3.0, duration: 0.5),
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.removeFromParent()
            ]))
        }
    }
    
    private func updateTowerStats() {
        // Base from Upgrades
        let baseDamage = upgradeManager.getDamage(base: 13)
        let baseFireRate = upgradeManager.getFireRate(base: 1.0)
        let baseRange = upgradeManager.getRange(base: 150)
        let baseHP = upgradeManager.getMaxHP(base: 130)
        let baseDefense = upgradeManager.getDefense()
        
        // Apply Perks & Achievements
        tower.damage = baseDamage * PerkManager.shared.damageMultiplier * CGFloat(AchievementManager.shared.damageBonusMultiplier)
        tower.fireRate = baseFireRate * PerkManager.shared.attackSpeedMultiplier
        tower.range = baseRange * PerkManager.shared.rangeMultiplier
        tower.maxHP = baseHP * PerkManager.shared.maxHPMultiplier
        tower.maxHP = baseHP * PerkManager.shared.maxHPMultiplier
        tower.defense = baseDefense
        
        // Visual Flair for Legendary Perks (Based on Active Buffs)
        tower.applyVisualFlair(activeBuffs: InventoryManager.shared.getActiveBuffIDs())
        
        // Weapon Modifiers
        switch upgradeManager.activeWeapon {
        case .shotgun:
            tower.damage *= 0.9 // Buffed: Solid damage per pellet
            tower.fireRate *= 0.8 // Buffed: Decent fire rate
            tower.range *= 0.75 // Buffed: Usable range
        case .sniper:
            tower.damage *= 6.0 // Buffed: One-shot potential
            tower.fireRate *= 0.6 // Buffed: Faster re-fire
            tower.range *= 2.0 // Buffed: Screen-wide
        case .railgun:
            tower.damage *= 5.0 // Buffed: Heavy hitter
            tower.fireRate *= 0.4 // Buffed: Faster
            tower.range *= 2.5 // Buffed: Infinite range practically

        default: break
        }
        
        // Turrets Sync
        syncTurrets()
        
        // Projectile Logic
        projectileManager.critChance = 0.1 + PerkManager.shared.critChanceBonus
        
        
        // Update UI
        updateStatPanel()
    }
    
    private func setupStatPanel() {
        statPanel = SKNode()
        statPanel.zPosition = 95
        statPanel.position = CGPoint(x: size.width - 90, y: 160)
        addChild(statPanel)
        
        // MARK: - Frosted Glass HUD Background
        // Main panel with glassmorphism effect
        let panelWidth: CGFloat = 160
        let panelHeight: CGFloat = 140
        
        // Outer glow layer
        let glowBg = SKShapeNode(rectOf: CGSize(width: panelWidth + 6, height: panelHeight + 6), cornerRadius: 14)
        glowBg.fillColor = .clear
        glowBg.strokeColor = SKColor.cyan.withAlphaComponent(0.4)
        glowBg.lineWidth = 2
        glowBg.glowWidth = 8
        glowBg.position = CGPoint(x: 0, y: 50)
        statPanel.addChild(glowBg)
        
        // Main background - frosted glass style
        let bg = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 12)
        bg.fillColor = SKColor(red: 0.05, green: 0.08, blue: 0.12, alpha: 0.85)
        bg.strokeColor = SKColor.cyan.withAlphaComponent(0.8)
        bg.lineWidth = 1.5
        bg.position = CGPoint(x: 0, y: 50)
        bg.name = "statPanelBg"
        statPanel.addChild(bg)
        
        // Panel title
        let titleLabel = SKLabelNode(text: "STATS".localized)
        titleLabel.fontName = "AvenirNext-Heavy"
        titleLabel.fontSize = 12
        titleLabel.fontColor = .cyan
        titleLabel.position = CGPoint(x: 0, y: panelHeight/2 + 35)
        titleLabel.horizontalAlignmentMode = .center
        statPanel.addChild(titleLabel)
        
        // Stat icons and labels with SF Symbols
        let stats: [(String, String, String)] = [
            ("Damage".localized, "flame.fill", "stat_Damage"),
            ("Fire Rate".localized, "bolt.fill", "stat_FireRate"),
            ("Range".localized, "scope", "stat_Range"),
            ("Health".localized, "heart.fill", "stat_Health"),
            ("Defense".localized, "shield.fill", "stat_Defense")
        ]
        
        for (i, stat) in stats.enumerated() {
            let yOffset = CGFloat(100 - i * 24)
            
            // Icon
            if let iconTexture = SKTexture.fromSymbol(name: stat.1, pointSize: 14) {
                let icon = SKSpriteNode(texture: iconTexture)
                icon.size = CGSize(width: 14, height: 14)
                icon.position = CGPoint(x: -65, y: yOffset)
                icon.color = .cyan
                icon.colorBlendFactor = 1.0
                icon.name = "icon_\(stat.2)"
                statPanel.addChild(icon)
            }
            
            // Stat name
            let nameLabel = SKLabelNode(text: stat.0)
            nameLabel.fontName = "AvenirNext-Medium"
            nameLabel.fontSize = 11
            nameLabel.fontColor = SKColor(white: 0.8, alpha: 1.0)
            nameLabel.horizontalAlignmentMode = .left
            nameLabel.position = CGPoint(x: -48, y: yOffset - 4)
            statPanel.addChild(nameLabel)
            
            // Level value (right aligned)
            let valueLabel = SKLabelNode(text: "Lv.1")
            valueLabel.name = stat.2
            valueLabel.fontName = "AvenirNext-Bold"
            valueLabel.fontSize = 12
            valueLabel.fontColor = .cyan
            valueLabel.horizontalAlignmentMode = .right
            valueLabel.position = CGPoint(x: 65, y: yOffset - 4)
            statPanel.addChild(valueLabel)
            
            // Horizontal separator line (except after last)
            if i < stats.count - 1 {
                let separator = SKShapeNode(rectOf: CGSize(width: panelWidth - 20, height: 0.5))
                separator.fillColor = SKColor.cyan.withAlphaComponent(0.2)
                separator.strokeColor = .clear
                separator.position = CGPoint(x: 0, y: yOffset - 14)
                statPanel.addChild(separator)
            }
        }
    }
    
    private func updateStatPanel() {
        let stats: [(String, Int)] = [
            ("Damage", upgradeManager.damageLevel),
            ("FireRate", upgradeManager.fireRateLevel),
            ("Range", upgradeManager.rangeLevel),
            ("Health", upgradeManager.healthLevel),
            ("Defense", upgradeManager.defenseLevel)
        ]
        
        for (name, level) in stats {
            if let node = statPanel.childNode(withName: "stat_\(name)") as? SKLabelNode {
                node.text = "Lv.\(level)"
                
                // Pop animation
                node.run(SKAction.sequence([
                    SKAction.scale(to: 1.3, duration: 0.1),
                    SKAction.scale(to: 1.0, duration: 0.1)
                ]))
            }
        }
    }
    
    private func setupSkillsUI() {
        let btnSize: CGFloat = 48
        let padding: CGFloat = 8
        let numButtons = 6
        let totalWidth = btnSize * CGFloat(numButtons) + padding * CGFloat(numButtons - 1)
        let startX = (size.width - totalWidth) / 2 + btnSize / 2
        let y: CGFloat = 95
        
        // Skills with emoji icons
        // Skills with new Asset Names (Fallback to SF Symbol if asset missing)
        let skills: [(name: String, icon: String, skillName: String)] = [
            ("UZI", "skill_icon_uzi", "skill_uzi"),
            ("ROCKET", "skill_icon_rocket", "skill_rocket"),
            ("FREEZE", "skill_icon_freeze", "skill_freeze"),
            ("LASER", "skill_icon_laser", "skill_laser"),
            ("SHIELD", "skill_icon_shield", "skill_shield"),
            ("EMP", "skill_emp", "skill_emp")
        ]
        
        for (index, skill) in skills.enumerated() {
            let xPos = startX + CGFloat(index) * (btnSize + padding)
            let btn = createSkillButton(name: skill.name, icon: skill.icon, position: CGPoint(x: xPos, y: y))
            btn.name = skill.skillName
            addChild(btn)
            
            // Assign to variables
            switch skill.skillName {
            case "skill_uzi": skillUziBtn = btn
            case "skill_rocket": skillRocketBtn = btn
            case "skill_freeze": skillFreezeBtn = btn
            case "skill_laser": skillLaserBtn = btn
            case "skill_shield": skillShieldBtn = btn
            case "skill_emp": skillEmpBtn = btn
            default: break
            }
        }
    }
    
    private func createSkillButton(name: String, icon: String, position: CGPoint) -> SKShapeNode {
        let btnSize: CGFloat = 48
        
        // Base Button Shape
        let btn = SKShapeNode(rectOf: CGSize(width: btnSize, height: btnSize), cornerRadius: 10)
        btn.fillColor = SKColor(white: 0.12, alpha: 0.95)
        btn.strokeColor = SKColor(white: 0.4, alpha: 1.0)
        btn.lineWidth = 1.5
        btn.position = position
        btn.zPosition = 90
        
        // CROP NODE for locking the icon into the rounded shape (fixes white corners)
        let cropNode = SKCropNode()
        let mask = SKShapeNode(rectOf: CGSize(width: btnSize-2, height: btnSize-2), cornerRadius: 9)
        mask.fillColor = .white
        cropNode.maskNode = mask
        cropNode.position = CGPoint(x: 0, y: 0)
        cropNode.zPosition = 1 
        btn.addChild(cropNode)
        
        // Icon Logic
        // Icon Logic
        let iconNode: SKSpriteNode
        if let texture = getCachedTexture(name: icon) {
            // Valid Texture (Asset or Symbol from Cache/Helper)
             iconNode = SKSpriteNode(texture: texture)
             if icon.hasPrefix("skill_") {
                 iconNode.size = CGSize(width: btnSize, height: btnSize)
             } else {
                 // Symbol fallback size
                 iconNode.size = CGSize(width: 28, height: 28)
                 iconNode.color = .cyan
                 iconNode.colorBlendFactor = 1.0
             }
        } else {
             iconNode = SKSpriteNode(color: .red, size: CGSize(width: 20, height: 20))
        }

        iconNode.position = CGPoint(x: 0, y: 0)
        iconNode.name = "icon"
        iconNode.isUserInteractionEnabled = false
        cropNode.addChild(iconNode) // Add to CropNode, not Btn
        
        // Name Label (High Visibility)
        // 1. Black Outline/Shadow for contrast
        let shadowLbl = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        shadowLbl.text = name
        shadowLbl.fontSize = 9
        shadowLbl.fontColor = .black
        shadowLbl.verticalAlignmentMode = .center
        shadowLbl.position = CGPoint(x: 1, y: -16) // Slightly offset
        shadowLbl.name = "labelShadow"
        shadowLbl.zPosition = 99
        btn.addChild(shadowLbl)
        
        // 2. Main Text
        let nameLbl = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        nameLbl.text = name
        nameLbl.fontSize = 9
        nameLbl.fontColor = .white
        nameLbl.verticalAlignmentMode = .center
        nameLbl.position = CGPoint(x: 0, y: -15) // Bottom of button
        nameLbl.name = "label"
        nameLbl.zPosition = 100 // Topmost
        btn.addChild(nameLbl)
        
        // Cooldown overlay (Above icon, below text)
        let cd = SKShapeNode(rectOf: CGSize(width: btnSize, height: btnSize), cornerRadius: 10)
        cd.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.75)
        cd.strokeColor = .clear
        cd.name = "cooldownOverlay"
        cd.isHidden = true
        cd.zPosition = 50 
        btn.addChild(cd)
        
        // Cooldown text
        let cdText = SKLabelNode(fontNamed: "AvenirNext-Bold")
        cdText.text = ""
        cdText.fontSize = 11
        cdText.fontColor = .white
        cdText.verticalAlignmentMode = .bottom
        cdText.horizontalAlignmentMode = .center
        cdText.position = CGPoint(x: 0, y: -btnSize/2 + 2)
        cdText.name = "cooldownText"
        cdText.zPosition = 101 // Above everything
        btn.addChild(cdText)
        
        return btn
    }
    
    private func setupHealButton() {
        let btnWidth: CGFloat = 140 // Widen to fit text
        let btnHeight: CGFloat = 40
        let yPos: CGFloat = 160 // Above skills
        
        let btn = SKShapeNode(rectOf: CGSize(width: btnWidth, height: btnHeight), cornerRadius: 10)
        btn.fillColor = SKColor(red: 0.1, green: 0.5, blue: 0.2, alpha: 0.9)
        btn.strokeColor = .green
        btn.lineWidth = 2
        btn.position = CGPoint(x: 100, y: yPos) // Adjusted x for wider button
        btn.name = "healButton"
        btn.zPosition = 90
        addChild(btn)
        
        // Icon + Text
        let lbl = SKLabelNode(text: "HEAL 50%".localized)
        lbl.fontName = "AvenirNext-Bold"
        lbl.fontSize = 12 // Smaller font
        lbl.fontColor = .white
        lbl.verticalAlignmentMode = .center
        lbl.horizontalAlignmentMode = .left
        lbl.position = CGPoint(x: -30, y: 8) // Moved up slightly
        btn.addChild(lbl)
        
        let costLbl = SKLabelNode(text: "$300")
        costLbl.name = "cost"
        costLbl.fontSize = 12
        costLbl.fontColor = .yellow
        costLbl.horizontalAlignmentMode = .left
        costLbl.position = CGPoint(x: -30, y: -8) // Under "HEAL" but inside button
        costLbl.verticalAlignmentMode = .center
        costLbl.name = "cost"
        btn.addChild(costLbl)
        
        if let texture = SKTexture.fromSymbol(name: "heart.fill", pointSize: 20) {
            let icon = SKSpriteNode(texture: texture)
            icon.size = CGSize(width: 20, height: 20)
            icon.position = CGPoint(x: -45, y: 0)
            icon.color = .white
            icon.colorBlendFactor = 1.0
            btn.addChild(icon)
        }
        
        // Removed separate cost label implementation to integrate above
        // btn.addChild(costLbl)
        
        healButton = btn
    }
    
    private func setupMarketUI() {
        marketNode = SKNode()
        marketNode.zPosition = 2000
        marketNode.alpha = 0
        marketNode.isHidden = true
        addChild(marketNode)
        
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = SKColor.black.withAlphaComponent(0.85)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: size.width/2, y: size.height/2)
        marketNode.addChild(overlay)
        
        let bgWidth = size.width * 0.95
        let bgHeight = size.height * 0.8
        let bg = SKShapeNode(rectOf: CGSize(width: bgWidth, height: bgHeight), cornerRadius: 16)
        bg.fillColor = SKColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        bg.strokeColor = .cyan
        bg.lineWidth = 2
        bg.glowWidth = 10
        bg.position = CGPoint(x: size.width/2, y: size.height/2)
        bg.name = "marketBackground"
        marketNode.addChild(bg)
        
        let title = SKLabelNode(text: "UPGRADE CENTER".localized)
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 32
        title.fontColor = .cyan
        title.position = CGPoint(x: 0, y: bgHeight/2 - 40)
        bg.addChild(title)
        
        title.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 1.0),
            SKAction.scale(to: 1.0, duration: 1.0)
        ])))
        
        // --- COINS DISPLAY (Centered above upgrades) ---
        let coinsDisplayBg = SKShapeNode(rectOf: CGSize(width: 180, height: 50), cornerRadius: 25)
        coinsDisplayBg.fillColor = SKColor(red: 0.1, green: 0.15, blue: 0.1, alpha: 0.95)
        coinsDisplayBg.strokeColor = SKColor.green.withAlphaComponent(0.6)
        coinsDisplayBg.lineWidth = 2
        coinsDisplayBg.glowWidth = 6
        coinsDisplayBg.position = CGPoint(x: 0, y: bgHeight/2 - 80)
        coinsDisplayBg.name = "marketCoinsDisplay"
        bg.addChild(coinsDisplayBg)
        
        if let coinIcon = SKTexture.fromSymbol(name: "dollarsign.circle.fill", pointSize: 22) {
            let icon = SKSpriteNode(texture: coinIcon)
            icon.size = CGSize(width: 24, height: 24)
            icon.position = CGPoint(x: -55, y: 0)
            icon.color = .green
            icon.colorBlendFactor = 1.0
            coinsDisplayBg.addChild(icon)
        }
        
        let marketCoinsLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        marketCoinsLabel.text = "$ \(currencyManager.coins)"
        marketCoinsLabel.fontSize = 22
        marketCoinsLabel.fontColor = .green
        marketCoinsLabel.verticalAlignmentMode = .center
        marketCoinsLabel.horizontalAlignmentMode = .center
        marketCoinsLabel.position = CGPoint(x: 10, y: 0)
        marketCoinsLabel.name = "marketCoinsLabel"
        coinsDisplayBg.addChild(marketCoinsLabel)
        
        // --- STATS UI ---
        let statsContainer = SKNode()
        statsContainer.name = "statsContainer"
        bg.addChild(statsContainer)
        
        let types: [(UpgradeType, String, Int)] = [
            (.damage, "DAMAGE".localized, 1),
            (.fireRate, "FIRE RATE".localized, 0),
            (.range, "RANGE".localized, -1),
            (.health, "MAX HP".localized, -2),
            (.defense, "DEFENSE".localized, -3)
        ]
        
        let unlockY: CGFloat = -60
        
        for (type, name, offset) in types {
            let btn = createUpgradeButton(type: type, name: name)
            let newOffset = CGFloat(offset) + 0.5 
            btn.position = CGPoint(x: 0, y: newOffset * 85 + unlockY)
            statsContainer.addChild(btn)
        }
        
        let closeBtn = SKLabelNode(text: "RESUME".localized)
        closeBtn.fontName = "AvenirNext-Bold"
        closeBtn.fontSize = 24
        closeBtn.fontColor = .white
        closeBtn.position = CGPoint(x: 0, y: -bgHeight/2 + 25)
        closeBtn.name = "closeMarket"
        bg.addChild(closeBtn)
    }



    private func createTabButton(text: String, name: String, selected: Bool) -> SKShapeNode {
        let w: CGFloat = 140
        let h: CGFloat = 40
        let btn = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 8)
        btn.fillColor = selected ? .cyan : .darkGray
        btn.strokeColor = .white
        btn.name = name
        
        let lbl = SKLabelNode(text: text)
        lbl.fontName = "AvenirNext-Bold"
        lbl.fontSize = 18
        lbl.fontColor = selected ? .black : .white
        lbl.verticalAlignmentMode = .center
        lbl.name = "label" // Pass through
        btn.addChild(lbl)
        
        return btn
    }
    
    private func createTurretButton() -> SKShapeNode {
        let w: CGFloat = 300
        let h: CGFloat = 70
        let btn = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 12)
        btn.fillColor = SKColor(white: 0.15, alpha: 1)
        btn.strokeColor = .cyan
        btn.lineWidth = 2
        btn.name = "buy_turret"
        
        let lbl = SKLabelNode(text: "BUY TURRET")
        lbl.fontSize = 20
        lbl.fontName = "AvenirNext-Bold"
        lbl.fontColor = .cyan
        lbl.position = CGPoint(x: -60, y: 10)
        btn.addChild(lbl)
        
        let costLbl = SKLabelNode(text: "$5000")
        costLbl.name = "cost"
        costLbl.fontSize = 18
        costLbl.fontColor = .yellow
        costLbl.position = CGPoint(x: -60, y: -15)
        btn.addChild(costLbl)
        
        // Icon
        if let texture = SKTexture.fromSymbol(name: "hexagon.fill", pointSize: 30) {
            let icon = SKSpriteNode(texture: texture)
            icon.color = .white
            icon.colorBlendFactor = 1.0
            icon.position = CGPoint(x: 80, y: 0)
            btn.addChild(icon)
        }
        
        return btn
    }
    
    private func createWeaponButton(type: WeaponType) -> SKShapeNode {
        let w: CGFloat = 160
        let h: CGFloat = 80
        let btn = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 10)
        btn.fillColor = SKColor(white: 0.1, alpha: 1)
        btn.strokeColor = .magenta
        btn.name = "weapon_\(type.rawValue)"
        
        let lbl = SKLabelNode(text: type.rawValue)
        lbl.fontSize = 16
        lbl.fontName = "AvenirNext-Bold"
        lbl.fontColor = .white
        lbl.position = CGPoint(x: 0, y: 15)
        btn.addChild(lbl)
        
        let status = SKLabelNode(text: "LOCKED")
        status.name = "status"
        status.fontSize = 14
        status.fontColor = .gray
        status.position = CGPoint(x: 0, y: -15)
        btn.addChild(status)
        
        return btn
    }
    
    private func animateCoinCollection(from position: CGPoint) {
        let coin = SKShapeNode(circleOfRadius: 6)
        coin.fillColor = .yellow
        coin.strokeColor = .orange
        coin.position = position
        coin.zPosition = 80
        addChild(coin)
        
        let targetParam = coinsLabel.position
        
        let move = SKAction.move(to: targetParam, duration: 0.6)
        move.timingMode = .easeIn
        let fade = SKAction.scale(to: 0.5, duration: 0.6)
        let group = SKAction.group([move, fade])
        
        coin.run(SKAction.sequence([group, SKAction.removeFromParent()]))
    }
    
    private func createUpgradeButton(type: UpgradeType, name: String) -> SKShapeNode {
        let w: CGFloat = 300
        let h: CGFloat = 60
        let btn = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 12)
        btn.fillColor = SKColor(white: 0.15, alpha: 1)
        btn.strokeColor = .magenta
        btn.lineWidth = 2
        btn.name = "upgrade_\(type.rawValue)"
        
        let lbl = SKLabelNode(text: "\(name)")
        lbl.name = "label"
        lbl.fontSize = 18
        lbl.fontName = "AvenirNext-Bold"
        lbl.fontColor = .white
        lbl.horizontalAlignmentMode = .left
        lbl.position = CGPoint(x: -w/2 + 50, y: -8) // Shifted right for icon
        btn.addChild(lbl)
        
        // Icon
        var iconName = "gear"
        switch type {
        case .damage: iconName = "flame.fill"
        case .fireRate: iconName = "bolt.fill"
        case .range: iconName = "scope"
        case .health: iconName = "heart.fill"
        case .defense: iconName = "shield.fill"
        }
        
        if let texture = SKTexture.fromSymbol(name: iconName, pointSize: 24) {
            let icon = SKSpriteNode(texture: texture)
            icon.size = CGSize(width: 24, height: 24)
            icon.position = CGPoint(x: -w/2 + 25, y: -2)
            icon.color = .white
            icon.colorBlendFactor = 1.0
            btn.addChild(icon)
        }
        
        let costLbl = SKLabelNode(text: "$\(upgradeManager.getCost(for: type))")
        costLbl.name = "cost"
        costLbl.fontSize = 18
        costLbl.fontName = "AvenirNext-Bold"
        costLbl.fontColor = .yellow
        costLbl.horizontalAlignmentMode = .right
        costLbl.position = CGPoint(x: w/2 - 20, y: -8)
        btn.addChild(costLbl)
        
        // Level Dots or Text could go here
        
        return btn
    }

    private func syncTurrets() {
        let targetCount = upgradeManager.turretCount
        
        // Add if needed
        while turrets.count < targetCount {
            let turret = TurretNode()
            turret.orbitRadius = 70 + CGFloat(turrets.count * 20) 
            turret.orbitSpeed = turrets.count % 2 == 0 ? 1.0 : -1.0
            turret.position = tower.position
            turret.zPosition = 10
            addChild(turret)
            turrets.append(turret)
        }
        
        // Update Stats
        // Requirements:
        // Damage = 25% of Player
        // Range = 50% of Player
        // Fire Speed = 50% of Player (Player uses Freq, Turret uses Delay)
        
        let scaledDamage = tower.damage * 0.25
        let scaledRange = tower.range * 0.5
        
        // Tower.fireRate is Frequency (shots/sec). Turret.fireRate is Delay (sec).
        // Target Turret Freq = TowerFreq * 0.5
        // Delay = 1.0 / TargetFreq
        let towerFreq = max(0.1, tower.fireRate)
        let scaledFireDelay = 1.0 / (towerFreq * 0.5)
        
        for turret in turrets {
             turret.damage = scaledDamage
             turret.range = scaledRange
             turret.fireRate = scaledFireDelay
        }
    }
    
    private func updateMarketUI() {
        // Fix: Targeting statsContainer instead of direct bg children
        guard let bg = marketNode.childNode(withName: "marketBackground"),
              let statsContainer = bg.childNode(withName: "statsContainer") else { return }
        
        // Update coins display
        if let coinsDisplay = bg.childNode(withName: "marketCoinsDisplay"),
           let coinsLabel = coinsDisplay.childNode(withName: "marketCoinsLabel") as? SKLabelNode {
            coinsLabel.text = "$ \(currencyManager.coins)"
        }
        
        let types: [UpgradeType] = [.damage, .fireRate, .range, .health, .defense]
        for type in types {
            if let btn = statsContainer.childNode(withName: "upgrade_\(type.rawValue)") as? SKShapeNode {
                let cost = upgradeManager.getCost(for: type)
                if let costLbl = btn.childNode(withName: "cost") as? SKLabelNode {
                    costLbl.text = "$\(cost)"
                }
                
                // Determine color based on affordability
                let canAfford = currencyManager.coins >= cost
                btn.strokeColor = canAfford ? .green : .gray
                btn.fillColor = canAfford ? SKColor(white: 0.15, alpha: 1) : SKColor(white: 0.1, alpha: 1)
                
                // Update Label Color
                if let lbl = btn.childNode(withName: "label") as? SKLabelNode {
                    lbl.fontColor = canAfford ? .white : .gray
                }
            }
        }
    }
    
    // MARK: - Update
    
    override func update(_ currentTime: TimeInterval) {
        let rawDelta = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        if isGamePaused { return }
        
        guard rawDelta > 0 && rawDelta < 0.5 else { return }
        
        // Apply game speed
        let deltaTime = rawDelta * Double(gameSpeed)
        
        // Update systems
        enemySpawner.update(deltaTime: deltaTime)
        
        let enemies = enemySpawner.getEnemies()
        tower.update(deltaTime: deltaTime, enemies: enemies)
        // Blade Logic
        updateBlade(deltaTime: deltaTime, enemies: enemies)
        
        projectileManager.update(deltaTime: deltaTime, enemies: enemies, tower: tower)
        
        // Perk: Overcharge Self-Damage
        if PerkManager.shared.hasOvercharge {
            tower.takeDamage(1.0 * CGFloat(deltaTime))
        }
        
        // Tower firing
        if let fireData = tower.fire() {
            AudioManager.shared.playTowerFire()
            
            // Perk: Explosive Ammo
            var radius = fireData.explosionRadius
            if CGFloat.random(in: 0...1) < PerkManager.shared.explosionChance {
                radius = max(radius, 40.0)
            }
            
            // Weapon Logic
            switch upgradeManager.activeWeapon {
            case .shotgun:
                // 3 Pellets - Spread
                let spread: CGFloat = 0.15
                for i in -1...1 {
                    let angle = atan2(fireData.direction.dy, fireData.direction.dx) + (CGFloat(i) * spread)
                    let spreadDir = CGVector(dx: cos(angle), dy: sin(angle))
                    projectileManager.spawnProjectile(
                        type: .player, damage: fireData.damage, position: fireData.position, direction: spreadDir,
                        speed: fireData.speed, maxDistance: tower.range * 0.85 + 50, penetration: fireData.penetration, explosionRadius: radius
                    )
                }
            case .sniper:
                // High Speed, Single Shot
                projectileManager.spawnProjectile(
                    type: .player, damage: fireData.damage, position: fireData.position, direction: fireData.direction,
                    speed: fireData.speed * 3.0, // Fast
                    maxDistance: tower.range + 100, penetration: 2, explosionRadius: radius
                )
            case .railgun:
                 // Infinite Penetration, Fast
                 projectileManager.spawnProjectile(
                     type: .player, damage: fireData.damage, position: fireData.position, direction: fireData.direction,
                     speed: fireData.speed * 2.0,
                     maxDistance: tower.range + 100, penetration: 99, explosionRadius: radius // 99 Penetration
                 )
            default: // Pistol
                 projectileManager.spawnProjectile(
                    type: .player, damage: fireData.damage, position: fireData.position, direction: fireData.direction,
                    speed: fireData.speed, maxDistance: tower.range + 50, penetration: fireData.penetration, explosionRadius: radius
                )
            }
        }
        
        // Update Turrets
        let allEnemies = enemySpawner.getAllEnemies() // Assume I added this accessor
        turrets.forEach { $0.update(deltaTime: deltaTime, center: tower.position, enemies: allEnemies, projectileManager: projectileManager) }

        
        // Enemy firing (Ranged/Boss)
        // Enemy firing (Ranged/Boss/Healer)
        for enemy in enemies {
            // Healer Logic
            if enemy.enemyType == .healer {
                if let _ = enemy.fire() {
                    // Find injured ally within range
                    let allies = enemies.filter { $0 != enemy && $0.currentHP < $0.maxHP }
                    
                    var bestTarget: Enemy?
                    var bestDistSq: CGFloat = CGFloat.greatestFiniteMagnitude
                    
                    for ally in allies {
                        let dx = ally.position.x - enemy.position.x
                        let dy = ally.position.y - enemy.position.y
                        let dSq = dx*dx + dy*dy
                        if dSq < bestDistSq {
                            bestDistSq = dSq
                            bestTarget = ally
                        }
                    }
                    
                    if let target = bestTarget, bestDistSq <= 150*150 { // Range 150
                        target.heal(amount: 15) // Heal 15 HP
                        createHealBeam(from: enemy.position, to: target.position)
                    }
                }
                continue
            }
            
            if let fireData = enemy.fire() {
                projectileManager.spawnProjectile(
                    type: .enemy,
                    damage: fireData.damage,
                    position: fireData.position,
                    direction: fireData.direction,
                    speed: fireData.speed
                )
            }
        }
        
        // Check tower collision with enemies
        checkTowerCollisions(enemies: enemies)
        
        // Wave progression
        waveController.update(deltaTime: deltaTime, waveComplete: enemySpawner.isWaveComplete())
        
        // Update HP bar
        updateHPBar()
        
        // Game over check
        if tower.isDead && !isGameOver {
            gameOver()
        }
        
        // Cooldowns
        if uziCooldown > 0 { uziCooldown -= deltaTime }
        if rocketCooldown > 0 { rocketCooldown -= deltaTime }
        if freezeCooldown > 0 { freezeCooldown -= deltaTime }
        if laserCooldown > 0 { laserCooldown -= deltaTime }
        if shieldCooldown > 0 { shieldCooldown -= deltaTime }
        if empCooldown > 0 { empCooldown -= deltaTime }
        
        // Visual feedback - vignette for low HP
        let hpRatio = tower.currentHP / tower.maxHP
        visualFeedback.updateVignetteForLoad(Float(1.0 - hpRatio) * 100)
        
        // Haptic for critical HP state
        if hpRatio < 0.3 && lastHPCheck >= 0.3 {
            HapticsManager.shared.onCriticalState()
        }
        lastHPCheck = hpRatio
        
        updateSkillsUIState()
    }
    
    private func updateSkillsUIState() {
        updateSkillBtn(skillUziBtn, cooldown: uziCooldown, max: uziMaxCooldown)
        updateSkillBtn(skillRocketBtn, cooldown: rocketCooldown, max: rocketMaxCooldown)
        updateSkillBtn(skillFreezeBtn, cooldown: freezeCooldown, max: freezeMaxCooldown)
        updateSkillBtn(skillLaserBtn, cooldown: laserCooldown, max: laserMaxCooldown)
        updateSkillBtn(skillShieldBtn, cooldown: shieldCooldown, max: shieldMaxCooldown)
        updateSkillBtn(skillEmpBtn, cooldown: empCooldown, max: empMaxCooldown)
    }
    
    private func updateSkillBtn(_ btn: SKShapeNode, cooldown: TimeInterval, max: TimeInterval) {
        guard let overlay = btn.childNode(withName: "cooldownOverlay") else { return }
        
        if cooldown > 0 {
            overlay.isHidden = false
            overlay.yScale = CGFloat(cooldown / max)
            
            // Update cooldown text
            if let cdText = btn.childNode(withName: "cooldownText") as? SKLabelNode {
                cdText.text = String(format: "%.1f", cooldown)
                cdText.isHidden = false
            }
        } else {
            overlay.isHidden = true
            if let cdText = btn.childNode(withName: "cooldownText") as? SKLabelNode {
                cdText.isHidden = true
            }
        }
    }
    
    private func checkTowerCollisions(enemies: [Enemy]) {
        for enemy in enemies where !enemy.isDead {
            let distance = enemy.distanceTo(tower.position)
            if distance < 30 {  // Contact radius
                if isShieldActive {
                    // Shield kills enemy without taking damage
                    enemy.takeDamage(999999)
                    showFloatingText("BLOCKED!", at: tower.position, color: .blue)
                    AudioManager.shared.playSpark()
                } else {
                    tower.takeDamage(enemy.damage)
                    enemy.takeDamage(9999)  // Kill enemy on contact
                }
                ComboManager.shared.addKill(at: enemy.position, on: self)
            }
        }
    }
    
    private func updateHPBar() {
        let ratio = tower.currentHP / tower.maxHP
        hpBarFill.xScale = ratio
        
        if ratio > 0.6 {
            hpBarFill.fillColor = SKColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0)
        } else if ratio > 0.3 {
            hpBarFill.fillColor = SKColor(red: 0.9, green: 0.7, blue: 0.1, alpha: 1.0)
        } else {
            hpBarFill.fillColor = SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        }
    }
    
    private func gameOver() {
        if isGameOver { return }
        isGameOver = true
        
        // Pause game logic but KEEP VIEW UNPAUSED for UI animations
        isGamePaused = true 
        self.view?.isPaused = false
        physicsWorld.speed = 0 // Stop physics (enemies moving)
        
        GameScene.consecutiveDeaths += 1
        
        // Fix: Force close Market/Shop if open to prevent UI blocking
        marketNode.isHidden = true
        marketNode.alpha = 0
        children.forEach { node in
            if node is ShopUI { node.removeFromParent() }
        }
        
        AudioManager.shared.playGameOver()
        HapticsManager.shared.onDeath()
        
        // Check Special Offer Conditions
        // Condition 1: Duration > 3 mins (180s)
        let duration = Date().timeIntervalSince(sessionStartTime)
        // Condition 2: 3 Consecutive Deaths
        
        _ = UpgradeManager.shared.isUnlocked(weapon: .railgun)
        
        let isSurvivor = duration > 180
        let isStruggler = GameScene.consecutiveDeaths >= 3
        
        if (isSurvivor || isStruggler) { // && !isRailgunUnlocked {
             // TEST MODE: Force Show
             showSpecialOffer(type: isSurvivor ? .survivor : .struggler)
             return 
        }
        
        showGameOverUI()
    }
    
    private func showSpecialOffer(type: SpecialOfferUI.OfferType) {
        let offer = SpecialOfferUI(size: size, type: type)
        offer.position = CGPoint(x: size.width/2, y: size.height/2)
        offer.onClose = { [weak self] in
            self?.showGameOverUI()
            // Reset consecutive deaths if offer shown to prevent spam?
            // User requirement: "3 consecutive deaths". If we show it, and they die again, do we show it again?
            // "Sınırlı teklif" implies not every time.
            // Let's reset consecutive deaths if offer shown.
            GameScene.consecutiveDeaths = 0
        }
        addChild(offer)
    }

    private func showGameOverUI() {
        // Submit to Game Center & Local Leaderboard (Async to prevent lag)
        let wave = waveController.currentWave
        let chapter = waveController.currentChapter
        let coins = currencyManager.coins
        
        DispatchQueue.global(qos: .background).async {
            LeaderboardManager.shared.submitScore(wave: wave, chapter: chapter, coins: coins)
            
            let score = (wave * 100) + (chapter * 1000) + (coins / 10)
            GameCenterManager.shared.submitGameOver(score: score, wave: wave)
            GameCenterManager.shared.checkWaveAchievements(wave: wave)
        }
        
        // Overlay
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = SKColor.black.withAlphaComponent(0.8)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: size.width/2, y: size.height/2)
        overlay.zPosition = 500
        overlay.name = "gameOverOverlay"
        addChild(overlay)
        
        let lbl = SKLabelNode(text: "GAME OVER".localized)
        lbl.fontName = "AvenirNext-Bold"
        lbl.fontSize = 40
        lbl.fontColor = .red
        lbl.position = CGPoint(x: 0, y: 80)
        overlay.addChild(lbl)
        
        let subLbl = SKLabelNode(text: L("Chapter %d - Wave %d", waveController.currentChapter, waveController.currentWave))
        subLbl.fontName = "AvenirNext-Medium"
        subLbl.fontSize = 20
        subLbl.position = CGPoint(x: 0, y: 40)
        overlay.addChild(subLbl)
        
        // Watch Ad Revive Button
        let reviveBtn = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 12)
        reviveBtn.fillColor = SKColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
        reviveBtn.strokeColor = .white
        reviveBtn.lineWidth = 2
        reviveBtn.position = CGPoint(x: 0, y: -30)
        reviveBtn.name = "reviveAdBtn"
        overlay.addChild(reviveBtn)
        
        let reviveLabel = SKLabelNode(text: "Watch Ad to Revive".localized)
        reviveLabel.fontName = "AvenirNext-Bold"
        reviveLabel.fontSize = 16
        reviveLabel.fontColor = .white
        reviveLabel.verticalAlignmentMode = .center
        reviveBtn.addChild(reviveLabel)
        
        // Pulse animation
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        reviveBtn.run(SKAction.repeatForever(pulse))
        
        // restartLbl removed
        
        // Close Button (Explicit restart)
        let closeBtn = SKShapeNode(circleOfRadius: 30) // Increased visual size
        closeBtn.fillColor = SKColor(white: 0.2, alpha: 0.9)
        closeBtn.strokeColor = .white
        closeBtn.lineWidth = 2
        closeBtn.position = CGPoint(x: 120, y: 180) 
        closeBtn.name = "closeGameOverBtn"
        closeBtn.zPosition = 100 // Ensure on top
        overlay.addChild(closeBtn)
        
        // Large Hit Area (Invisible)
        let hitArea = SKShapeNode(circleOfRadius: 50)
        hitArea.fillColor = .clear
        hitArea.strokeColor = .clear
        hitArea.name = "closeGameOverBtn" // Also responds to touch
        closeBtn.addChild(hitArea)
        
        let closeX = SKLabelNode(fontNamed: "AvenirNext-Bold")
        closeX.text = "X"
        closeX.fontSize = 24
        closeX.fontColor = .white
        closeX.verticalAlignmentMode = .center
        closeX.position = CGPoint(x: 0, y: 1)
        closeX.name = "closeGameOverBtn" // Ensure label also triggers it
        closeBtn.addChild(closeX)
        
        // Notify AdManager
        AdManager.shared.onGameOver()
    }
    
    // MARK: - Blade System
    
    private func setupBlade() {
        guard UpgradeManager.shared.isBladeUnlocked else { return }
        if bladeNode != nil { return }
        
        if let tex = SKTexture.fromSymbol(name: "fanblades.fill", pointSize: 30) {
            let blade = SKSpriteNode(texture: tex)
            blade.size = CGSize(width: 40, height: 40)
            blade.color = .cyan
            blade.colorBlendFactor = 1.0
            blade.position = CGPoint(x: 120, y: 0)
            blade.zPosition = 25
            
            bladeNode = blade
            addChild(blade)
        }
    }
    
    private func updateBlade(deltaTime: TimeInterval, enemies: [SKNode]) {
        guard let blade = bladeNode else {
            if UpgradeManager.shared.isBladeUnlocked { setupBlade() }
            return
        }
        
        // Rotation
        bladeAngle += CGFloat(deltaTime * 3.0) 
        let radius: CGFloat = 120.0
        
        let cx = tower.position.x
        let cy = tower.position.y
        let bx = cx + cos(bladeAngle) * radius
        let by = cy + sin(bladeAngle) * radius
        
        blade.position = CGPoint(x: bx, y: by)
        blade.zRotation = bladeAngle * 2 
        
        let damage = tower.damage * 0.5
        
        for (node, _) in bladeHitTimers {
            if node.parent == nil { bladeHitTimers.removeValue(forKey: node) }
        }
        
        for (node, time) in bladeHitTimers {
            bladeHitTimers[node] = max(0, time - deltaTime)
        }
        
        for enemyNode in enemies {
            guard let enemy = enemyNode as? Enemy else { continue }
            
            if blade.intersects(enemy) {
                if (bladeHitTimers[enemy] ?? 0) <= 0 {
                    enemy.takeDamage(damage)
                    showFloatingText("\(Int(damage))", at: enemy.position, color: .cyan)
                    
                    let spark = SKShapeNode(circleOfRadius: 5)
                    spark.fillColor = .white
                    spark.position = enemy.position
                    addChild(spark)
                    spark.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.2), SKAction.removeFromParent()]))
                    
                    bladeHitTimers[enemy] = 0.5 
                }
            }
        }
    }
    
    private func restartGame() {
        isGameOver = false
        isGamePaused = false
        physicsWorld.speed = 1.0 // Resume physics
        
        // Remove overlay
        childNode(withName: "gameOverOverlay")?.removeFromParent()
        
        // Reset Logic
        tower.currentHP = tower.maxHP
        projectileManager.reset()
        enemySpawner.reset()
        waveController.reset() // Should set wave to 1
        
        // Cleanup visuals
        for node in children {
            if node.name == "dead_particle" {
                node.removeFromParent()
            }
        }
        
        updateCoinsLabel()
        updateHPBar()
        updateStatPanel()
    }
    
    private func reviveFromAd() {
        // Show rewarded ad
        AdManager.shared.showRewardedAd(type: .rewardedRevive) { [weak self] success in
            guard let self = self else { return }
            
            if !success {
                DispatchQueue.main.async {
                    self.showFloatingText("AD FAILED!", at: self.tower.position, color: .red)
                    // Optional: Shake the button or provide more feedback
                }
                return 
            }
            
            // Must run on main thread for UI updates
            DispatchQueue.main.async {
                // Revive player
                self.isGameOver = false
                self.isGamePaused = false
                self.view?.isPaused = false
                self.physicsWorld.speed = 1.0 // Resume physics
                
                // Remove overlay
                self.childNode(withName: "gameOverOverlay")?.removeFromParent()
                
                // Restore 50% HP
                self.tower.currentHP = self.tower.maxHP * 0.5
                
                // Clear all enemies from screen (mercy)
                for enemy in self.enemySpawner.getEnemies() {
                    enemy.removeFromParent()
                }
                self.enemySpawner.clearEnemies()
                
                self.updateHPBar()
                
                self.showFloatingText("REVIVED!", at: self.tower.position, color: .green)
                AudioManager.shared.playUpgrade()
            }
        }
    }
    
    private func updateCoinsLabel() {
        coinsLabel.text = "$ \(currencyManager.coins)"
    }
    
    private func updateGemsLabel() {
        gemsLabel.text = "\(GemManager.shared.gems)"
    }
    
    // MARK: - Touch
    

    
    // MARK: - Lifecycle Handlers
    
    @objc private func onAppWillResignActive() {
        print("App resigning active - Pausing Game")
        isGamePaused = true
        self.scene?.view?.isPaused = true
        AudioManager.shared.pauseBackgroundMusic()
    }
    
    @objc private func onAppDidBecomeActive() {
        print("App became active")
        self.scene?.view?.isPaused = false
        
        // Show pause menu if active gameplay
        if !isGameOver && isGameStarted {
             showPauseMenu()
        }
        
        // Resume Audio
        if AudioManager.shared.isMusicEnabled && !AudioManager.shared.muted {
            AudioManager.shared.resumeBackgroundMusic()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let node = atPoint(location)
        
        // Splash Screen - Start Game button
        if splashOverlay != nil {
            if node.name == "startGameBtn" || node.parent?.name == "startGameBtn" {
                dismissSplashScreen()
            }
            return // Block all other touches while splash is showing
        }
        
        // Game Over State - Check revive button first
        if isGameOver {
            if node.name == "reviveAdBtn" || node.parent?.name == "reviveAdBtn" {
                reviveFromAd()
                return
            }
            if node.name == "closeGameOverBtn" || node.parent?.name == "closeGameOverBtn" {
                restartGame()
            }
            return
        }
        
        // Daily Reward Button
        if node.name == "dailyRewardBtn" || node.parent?.name == "dailyRewardBtn" {
            handleDailyRewardTap()
            return
        }
        
        // Perk Selection
        if !activePerkOptions.isEmpty {
            let node = atPoint(location)
            var target = node
            // Traverse up to find card
            while target.parent != nil && target.name == nil {
                target = target.parent!
            }
            if let name = target.name, name.starts(with: "perk_card_"),
               let index = Int(name.replacingOccurrences(of: "perk_card_", with: "")) {
                selectPerk(index: index)
            } else if let pName = target.parent?.name, pName.starts(with: "perk_card_"),
                      let index = Int(pName.replacingOccurrences(of: "perk_card_", with: "")) {
                selectPerk(index: index)
            }
            return
        }
        
        
        // Market Handling
        if isMarketOpen {
            if node.name == "closeMarket" {
                toggleMarket(false)
            } 
            

            
            // Stats Upgrade Logic
            if let name = node.name, name.starts(with: "upgrade_") || (node.parent?.name?.starts(with: "upgrade_") ?? false) {
                let upgradeName = name.starts(with: "upgrade_") ? name : node.parent!.name!
                let typeStr = upgradeName.replacingOccurrences(of: "upgrade_", with: "")
                if let type = UpgradeType(rawValue: typeStr) {
                    if upgradeManager.purchaseUpgrade(type, currency: currencyManager) {
                        updateMarketUI()
                        updateTowerStats()
                        AudioManager.shared.playUpgrade()
                    }
                }
            }

            return // Block game touches
        }
        
        // Pause Menu Handling
        // Pause Menu
        if isGamePaused {
            if let parentName = node.parent?.name, parentName.starts(with: "perk_") {
                 if let index = Int(parentName.components(separatedBy: "_").last ?? "") {
                    selectPerk(index: index)
                }
            }
            if let nodeName = node.name, nodeName.starts(with: "perk_") {
                 if let index = Int(nodeName.components(separatedBy: "_").last ?? "") {
                    selectPerk(index: index)
                }
            }
            
            // Check for pause menu buttons (including children of buttons)
            let isResumeButton = node.name == "resumeButton" || node.parent?.name == "resumeButton"
            let isPauseButton = node.name == "pauseButton" || node.parent?.name == "pauseButton"
            let isRestartButton = node.name == "restartFromPause" || node.parent?.name == "restartFromPause"
            let isMusicToggle = node.name == "musicToggle" || node.parent?.name == "musicToggle"
            let isSfxToggle = node.name == "sfxToggle" || node.parent?.name == "sfxToggle"
            
            // Volume slider handling
            let nodeName = node.name ?? node.parent?.name ?? ""
            
            if nodeName.contains("Volume_plus") || nodeName.contains("Volume_minus") {
                handleVolumeButton(nodeName)
                return
            }
            
            if isMusicToggle {
                AudioManager.shared.toggleMusic()
                hidePauseMenu()
                showPauseMenu()
                return
            } else if isSfxToggle {
                AudioManager.shared.toggleSFX()
                hidePauseMenu()
                showPauseMenu()
                return
            } else if isResumeButton || isPauseButton {
                hidePauseMenu()
            } else if isRestartButton {
                hidePauseMenu()
                restartGame()
            }
            return
        }
        
        // Main Game UI
        if node.name == "pauseButton" {
            togglePause()
        } else if node.name == "shopButton" || node.parent?.name == "shopButton" {
            handleShopTap()
        } else if node.name == "questButton" || node.parent?.name == "questButton" {
            handleQuestTap()
        } else if node.name == "socialButton" || node.parent?.name == "socialButton" {
            handleSocialTap()
        } else if node.name == "healButton" || node.parent?.name == "healButton" {
             if currencyManager.coins >= 300 {
                 if tower.currentHP < tower.maxHP {
                     // Purchase
                     _ = currencyManager.spendCoins(300)
                     updateCoinsLabel()
                     
                     // Heal
                     let healAmount = tower.maxHP * 0.5
                     tower.currentHP = min(tower.maxHP, tower.currentHP + healAmount)
                     updateHPBar()
                     
                     // Feedback
                     AudioManager.shared.playUpgrade() // Good sound for positive action
                     HapticsManager.shared.onStabilization()
                     
                     // Update vignette
                     let hpRatio = tower.currentHP / tower.maxHP
                     visualFeedback.updateVignetteForLoad(Float(1.0 - hpRatio) * 100)
                     
                     // Visual pop
                     let btn = (node.name == "healButton" ? node : node.parent!)
                     btn.run(SKAction.sequence([
                         SKAction.scale(to: 1.2, duration: 0.1),
                         SKAction.scale(to: 1.0, duration: 0.1)
                     ]))
                     
                     // Heal effect on tower
                     let healEffect = SKShapeNode(circleOfRadius: 50)
                     healEffect.fillColor = .green
                     healEffect.alpha = 0.5
                     healEffect.position = tower.position
                     healEffect.setScale(0.5)
                     addChild(healEffect)
                     healEffect.run(SKAction.sequence([
                         SKAction.group([
                            SKAction.scale(to: 1.5, duration: 0.3),
                            SKAction.fadeOut(withDuration: 0.3)
                         ]),
                         SKAction.removeFromParent()
                     ]))
                 } else {
                     // Full HP sound/shake?
                 }
             } else {
                 // No money sound
             }
        } else if node.name == "marketButton" || node.parent?.name == "marketButton" {
            toggleMarket(true)
        } else if node.name == "speedButton" {
             cycleSpeed()
        }
        

        
        // Skills
        handleSkillTouch(node: node)
    }
    
    // MARK: - Daily Rewards & Gems
    
    private func handleShopTap() {
        let shopUI = ShopUI(size: size)
        shopUI.zPosition = 2000
        
        // Center on camera if active, otherwise scene center
        if let cam = camera {
            shopUI.position = CGPoint.zero
            cam.addChild(shopUI)
        } else {
             shopUI.position = CGPoint(x: size.width/2, y: size.height/2)
             addChild(shopUI)
        }
        
        shopUI.onClose = { [weak self] in
             self?.updateGemsLabel()
        }
    }
    
    private func handleQuestTap() {
        let questUI = QuestPassUI(size: size)
        questUI.zPosition = 2000
        
        if let cam = camera {
            questUI.position = CGPoint.zero
            cam.addChild(questUI)
        } else {
             questUI.position = CGPoint(x: size.width/2, y: size.height/2)
             addChild(questUI)
        }
        
        questUI.onClose = { [weak self] in
            self?.updateCoinsLabel()
            self?.updateGemsLabel()
        }
    }
    
    private func handleSocialTap() {
        let socialUI = SocialUI(size: size)
        socialUI.zPosition = 2000
        
        if let cam = camera {
            socialUI.position = CGPoint.zero
            cam.addChild(socialUI)
        } else {
             socialUI.position = CGPoint(x: size.width/2, y: size.height/2)
             addChild(socialUI)
        }
        
        socialUI.onClose = { [weak self] in
            self?.updateCoinsLabel()
            self?.updateGemsLabel()
        }
    }
    
    private func handleDailyRewardTap() {
        guard DailyRewardManager.shared.canClaimToday else {
            // Already claimed - show message
            showFloatingText("Already claimed today!", at: dailyRewardBtn.position, color: .orange)
            return
        }
        
        if let reward = DailyRewardManager.shared.claimReward(currencyManager: currencyManager) {
            // Show reward popup
            showDailyRewardPopup(reward: reward)
            
            // Remove notification dot
            dailyRewardBtn.childNode(withName: "notificationDot")?.removeFromParent()
            
            // Update UI
            updateGemsLabel()
            updateCoinsLabel()
            
            AudioManager.shared.playUpgrade()
        }
    }
    
    private func showDailyRewardPopup(reward: DailyReward) {
        let overlay = SKShapeNode(rectOf: CGSize(width: 280, height: 200), cornerRadius: 20)
        overlay.fillColor = SKColor(white: 0.1, alpha: 0.95)
        overlay.strokeColor = .cyan
        overlay.lineWidth = 3
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = 500
        overlay.name = "dailyRewardPopup"
        
        let titleLabel = SKLabelNode(text: "🎁 Daily Reward!")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 24
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: 60)
        overlay.addChild(titleLabel)
        
        let dayLabel = SKLabelNode(text: "Day \(DailyRewardManager.shared.currentStreak)")
        dayLabel.fontName = "AvenirNext-Medium"
        dayLabel.fontSize = 18
        dayLabel.fontColor = .cyan
        dayLabel.position = CGPoint(x: 0, y: 30)
        overlay.addChild(dayLabel)
        
        let rewardLabel = SKLabelNode(text: reward.description)
        rewardLabel.fontName = "AvenirNext-Bold"
        rewardLabel.fontSize = 32
        rewardLabel.fontColor = reward.gems > 0 ? SKColor(red: 0.3, green: 0.9, blue: 0.95, alpha: 1) : .yellow
        rewardLabel.position = CGPoint(x: 0, y: -10)
        overlay.addChild(rewardLabel)
        
        let streakLabel = SKLabelNode(text: "🔥 \(DailyRewardManager.shared.currentStreak) day streak!")
        streakLabel.fontName = "AvenirNext-Medium"
        streakLabel.fontSize = 16
        streakLabel.fontColor = .orange
        streakLabel.position = CGPoint(x: 0, y: -50)
        overlay.addChild(streakLabel)
        
        addChild(overlay)
        
        // Auto-dismiss after 2 seconds
        overlay.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }
    

    
    private func showFloatingText(_ text: String, at position: CGPoint, color: SKColor) {
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 24
        label.fontColor = color
        label.position = position
        label.zPosition = 3000 // High zPosition
        addChild(label)
        
        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        label.run(SKAction.sequence([moveUp, fadeOut, SKAction.removeFromParent()]))
    }
    
    private func toggleMarket(_ show: Bool) {
        if show {
             AudioManager.shared.playShopOpen()
        }
        isMarketOpen = show
        marketNode.isHidden = !show
        
        if show {
            updateMarketUI()
             marketNode.run(SKAction.fadeIn(withDuration: 0.2))
             
             // Pause game logic while in market
             isGamePaused = true
             view?.isPaused = false
        } else {
            marketNode.run(SKAction.fadeOut(withDuration: 0.2))
            
            // Resume game logic
            isGamePaused = false
            view?.isPaused = false
        }
    }
    
    private func handleSkillTouch(node: SKNode) {
        // Traverse up to find button name
        var targetNode: SKNode? = node
        
        while let current = targetNode, current != self {
            if let name = current.name, name.hasPrefix("skill_") {
                // Found skill button
                if name == "skill_uzi" {
                    activateSkill(.uzi)
                } else if name == "skill_rocket" {
                    activateSkill(.rocket)
                } else if name == "skill_freeze" {
                    activateSkill(.freeze)
                } else if name == "skill_laser" {
                    activateSkill(.laser)
                } else if name == "skill_shield" {
                    activateSkill(.shield)
                } else if name == "skill_emp" {
                    activateSkill(.emp)
                }
                return
            }
            targetNode = current.parent
        }
    }
    
    private func activateSkill(_ type: SkillType) {
        
        AudioManager.shared.playSkillActivate()
        // Check unlock logic if implemented
        
        switch type {
        case .uzi:
            guard uziCooldown <= 0 else { return }
            tower.activateUziMode(duration: 10.0)
            uziCooldown = uziMaxCooldown
        case .rocket:
             guard rocketCooldown <= 0 else { return }
             fireRockets()
             rocketCooldown = rocketMaxCooldown
        case .freeze:
             guard freezeCooldown <= 0 else { return }
             fireFreeze()
             freezeCooldown = freezeMaxCooldown
        case .laser:
             guard laserCooldown <= 0 else { return }
             fireLaser()
             laserCooldown = laserMaxCooldown
        case .shield:
             guard shieldCooldown <= 0 else { return }
             activateShield()
             shieldCooldown = shieldMaxCooldown
        case .emp:
             guard empCooldown <= 0 else { return }
             fireEMP()
             empCooldown = empMaxCooldown
        }
    }
    
    private func fireRockets() {
        // Target 3 highest HP enemies
        let enemies = enemySpawner.getEnemies().sorted { $0.currentHP > $1.currentHP }
        let targets = enemies.prefix(3)
        
        // Haptic feedback for skill activation
        HapticsManager.shared.onExplosion()
        
        for enemy in targets {
            // Calculate direction to enemy
            let dx = enemy.position.x - tower.position.x
            let dy = enemy.position.y - tower.position.y
            let dist = max(sqrt(dx*dx + dy*dy), 1.0) // Avoid division by zero
            let dir = CGVector(dx: dx/dist, dy: dy/dist)
            
            let damage = tower.damage * 10.0 // Scaled heavily
            projectileManager.spawnProjectile(
                type: .player,
                damage: damage,
                position: tower.position,
                direction: dir,
                speed: 400,
                penetration: 1,
                explosionRadius: 50,
                isRocket: true
            )
        }
    }
    
    private func fireEMP() {
        // Clear screen / massive damage
        let enemies = enemySpawner.getEnemies()
        
        // Visual using EmpSprite
        let wave: SKSpriteNode
        if let tex = getCachedTexture(name: "EmpSprite") {
            wave = SKSpriteNode(texture: tex)
        } else {
            wave = SKSpriteNode(color: .cyan, size: CGSize(width: 150, height: 150))
        }
        
        wave.position = tower.position
        wave.zPosition = 60 // High Z to be on top
        wave.alpha = 0
        wave.setScale(0.1)
        wave.blendMode = .add
        addChild(wave)
        
        // Expanding shockwave animation
        let expand = SKAction.scale(to: 10.0, duration: 0.4) // Adjust scale based on sprite size 150px * 10 = 1500px coverage
        let fadeIn = SKAction.fadeIn(withDuration: 0.05)
        let rotate = SKAction.rotate(byAngle: -.pi * 2, duration: 0.4)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        
        wave.run(SKAction.sequence([
            SKAction.group([expand, fadeIn, rotate]),
            fadeOut,
            SKAction.removeFromParent()
        ]))
        
        // Haptic
        HapticsManager.shared.onExplosion()
        
        // EMP Damage scales with Wave HP
        let waveIdx = waveController.currentWave
        let baseEnemyHP = waveController.enemyHPForWave(waveIdx)
        let empDamage = baseEnemyHP * 20.0 
        
        for enemy in enemies {
            enemy.takeDamage(empDamage) 
        }
    }
    
    private func fireFreeze() {
        // Freeze/Slow all enemies
        let enemies = enemySpawner.getEnemies()
        
        // Visual using FreezeSprite
        let freezeNode: SKSpriteNode
        if let tex = getCachedTexture(name: "FreezeSprite") {
            freezeNode = SKSpriteNode(texture: tex)
        } else {
            freezeNode = SKSpriteNode(color: .cyan, size: CGSize(width: 150, height: 150))
        }
        
        freezeNode.position = tower.position
        freezeNode.zPosition = 60
        freezeNode.alpha = 0
        freezeNode.setScale(0.1)
        freezeNode.blendMode = .add
        addChild(freezeNode)
        
        // Expansion animation
        let expand = SKAction.scale(to: 12.0, duration: 0.5) // 150*12 = 1800 coverage
        let fadeIn = SKAction.fadeIn(withDuration: 0.1)
        let rotate = SKAction.rotate(byAngle: .pi, duration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        
        freezeNode.run(SKAction.sequence([
            SKAction.group([expand, fadeIn, rotate]),
            SKAction.wait(forDuration: 0.2),
            fadeOut,
            SKAction.removeFromParent()
        ]))
        
        // Display label
        let freezeLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        freezeLabel.text = "❄️ FREEZE! ❄️"
        freezeLabel.fontSize = 32
        freezeLabel.fontColor = .cyan
        freezeLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.6)
        freezeLabel.zPosition = 200
        freezeLabel.setScale(0.5)
        addChild(freezeLabel)
        
        let popIn = SKAction.scale(to: 1.1, duration: 0.15)
        popIn.timingMode = .easeOut
        let settle = SKAction.scale(to: 1.0, duration: 0.1)
        let hold = SKAction.wait(forDuration: 0.8)
        let labelFade = SKAction.fadeOut(withDuration: 0.3)
        
        freezeLabel.run(SKAction.sequence([popIn, settle, hold, labelFade, SKAction.removeFromParent()]))
        
        // Haptic
        HapticsManager.shared.onStabilization()
        
        // Apply slow to all enemies
        let freezeDamage = tower.damage * 2.0 // Impact damage
        for enemy in enemies {
            enemy.takeDamage(freezeDamage)
            enemy.applySlow(multiplier: 0.5, duration: 5.0)
        }
    }
    
    private func fireLaser() {
        // Find highest HP enemy in range
        let enemies = enemySpawner.getEnemies().sorted { $0.currentHP > $1.currentHP }
        guard var target = enemies.first else { return }
        
        // Haptic
        HapticsManager.shared.onExplosion()
        
        // Display label
        let laserLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        laserLabel.text = "🔴 LASER! 🔴"
        laserLabel.fontSize = 28
        laserLabel.fontColor = .red
        laserLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.6)
        laserLabel.zPosition = 200
        laserLabel.setScale(0.5)
        addChild(laserLabel)
        laserLabel.run(SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.wait(forDuration: 0.8),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
        
        // Create laser beam visual
        let beam: SKSpriteNode
        if let tex = getCachedTexture(name: "LaserSprite") {
            beam = SKSpriteNode(texture: tex)
        } else {
            beam = SKSpriteNode(color: .red, size: CGSize(width: 100, height: 40))
        }
        
        beam.anchorPoint = CGPoint(x: 0, y: 0.5) // Anchor at left-center (start of beam)
        beam.zPosition = 55
        beam.name = "laserBeam"
        beam.blendMode = .add // Make it glow
        beam.position = tower.position
        
        // Initial setup
        let dx = target.position.x - tower.position.x
        let dy = target.position.y - tower.position.y
        let dist = sqrt(dx*dx + dy*dy)
        let angle = atan2(dy, dx)
        
        beam.zRotation = angle
        beam.size = CGSize(width: dist, height: 40) // Width = length, Height = thickness
        
        addChild(beam)
        
        // Beam config
        let beamDuration: TimeInterval = 3.0
        let dpsPerSecond: CGFloat = tower.damage * 4.0 // Scale with tower damage
        let damageInterval: TimeInterval = 0.1
        
        // Deal damage over time with retargeting
        let damageAction = SKAction.repeat(SKAction.sequence([
            SKAction.wait(forDuration: damageInterval),
            SKAction.run { [weak self, weak beam] in
                guard let self = self, let beam = beam else { return }
                
                // Retarget if current target is dead
                if target.isDead {
                    let alive = self.enemySpawner.getEnemies().filter { !$0.isDead }
                    if let newTarget = alive.sorted(by: { $0.currentHP > $1.currentHP }).first {
                        target = newTarget
                    } else {
                        beam.removeFromParent()
                        return
                    }
                }
                
                // Deal damage
                target.takeDamage(dpsPerSecond * CGFloat(damageInterval), isCritical: false)
                
                // Update beam transform to follow target
                let dx = target.position.x - self.tower.position.x
                let dy = target.position.y - self.tower.position.y
                let dist = sqrt(dx*dx + dy*dy)
                let angle = atan2(dy, dx)
                
                beam.position = self.tower.position
                beam.zRotation = angle
                beam.size.width = dist
                
                // Flicker effect (Thickness)
                beam.size.height = CGFloat.random(in: 30...50)
                beam.alpha = CGFloat.random(in: 0.8...1.0)
            }
        ]), count: Int(beamDuration / damageInterval))
        
        beam.run(SKAction.sequence([
            damageAction,
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ]))
    }
    
    private func activateShield() {
        // Haptic
        HapticsManager.shared.onStabilization()
        
        // Display label
        let shieldLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        shieldLabel.text = "🛡️ SHIELD! 🛡️"
        shieldLabel.fontSize = 28
        shieldLabel.fontColor = .blue
        shieldLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.6)
        shieldLabel.zPosition = 200
        shieldLabel.setScale(0.5)
        addChild(shieldLabel)
        shieldLabel.run(SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.wait(forDuration: 0.8),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
        
        // Enable Shield
        isShieldActive = true
        
        // Create shield visual around tower
        let shieldDuration: TimeInterval = 5.0 // Increased duration
        
        // Disable after duration
        run(SKAction.sequence([
            SKAction.wait(forDuration: shieldDuration),
            SKAction.run { [weak self] in
                self?.isShieldActive = false
            }
        ]))
        
        let shieldNode: SKSpriteNode
        if let tex = getCachedTexture(name: "ShieldSprite") {
            shieldNode = SKSpriteNode(texture: tex)
        } else {
            shieldNode = SKSpriteNode(color: .blue, size: CGSize(width: 130, height: 130))
        }
        
        shieldNode.size = CGSize(width: 130, height: 130) // Slightly larger than tower
        shieldNode.blendMode = .add
        shieldNode.alpha = 0.8
        shieldNode.position = tower.position
        shieldNode.zPosition = 15
        shieldNode.name = "activeShield"
        addChild(shieldNode)
        
        // Store original defense
        let originalDefense = tower.defense
        
        // Activate invulnerability (set very high defense)
        tower.defense = 9999
        
        // Pulse animation while active
        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ]))
        shieldNode.run(pulse, withKey: "pulse")
        
        // Remove shield after duration
        run(SKAction.sequence([
            SKAction.wait(forDuration: shieldDuration),
            SKAction.run { [weak self, weak shieldNode] in
                self?.tower.defense = originalDefense
                shieldNode?.removeAllActions()
                shieldNode?.run(SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.removeFromParent()
                ]))
            }
        ]))
    }
    
    private func cycleSpeed() {
        speedIndex = (speedIndex + 1) % speedOptions.count
        gameSpeed = speedOptions[speedIndex]
        speedButton.text = String(format: "x%.1f", gameSpeed)
        
        // Animation
        let pop = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        speedButton.run(pop)
    }
}

    // MARK: - Perk Selection
    

    
extension GameScene {
    private func showPerkSelection() {
        isGamePaused = true
        // DO NOT pause view, otherwise animations won't run
        // self.scene?.view?.isPaused = true
        
        let perks = PerkManager.shared.getRandomPerks(count: 3)
        self.activePerkOptions = perks
        
        // Overlay
        let overlay = SKNode()
        overlay.name = "perkOverlay"
        overlay.zPosition = 5000 // Ensure it's on top of everything
        addChild(overlay)
        
        let bg = SKShapeNode(rectOf: size)
        bg.fillColor = SKColor.black.withAlphaComponent(0.85)
        bg.position = CGPoint(x: size.width/2, y: size.height/2)
        bg.strokeColor = .clear
        overlay.addChild(bg)
        
        let title = SKLabelNode(text: "🃏 CHOOSE A PERK 🃏")
        title.fontName = "AvenirNext-Heavy"
        title.fontSize = 36
        title.fontColor = .yellow
        title.position = CGPoint(x: size.width/2, y: size.height - 150)
        overlay.addChild(title)
        
        // Cards
        let cardWidth: CGFloat = 100
        let cardHeight: CGFloat = 160
        let spacing: CGFloat = 20
        let totalWidth = (cardWidth * 3) + (spacing * 2)
        let startX = (size.width - totalWidth) / 2 + cardWidth/2
        
        for (i, perk) in perks.enumerated() {
            let x = startX + CGFloat(i) * (cardWidth + spacing)
            let y = size.height / 2
            
            let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 12)
            card.fillColor = SKColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0)
            card.strokeColor = .cyan
            card.lineWidth = 2
            card.position = CGPoint(x: x, y: y)
            card.name = "perk_card_\(i)"
            overlay.addChild(card)
            
            // Icon
            if let texture = SKTexture.fromSymbol(name: perk.icon, pointSize: 40) {
                let icon = SKSpriteNode(texture: texture)
                icon.size = CGSize(width: 50, height: 50)
                icon.position = CGPoint(x: 0, y: 20)
                icon.color = .white
                icon.colorBlendFactor = 1.0
                card.addChild(icon)
            }
            
            // Name
            let nameLbl = SKLabelNode(text: perk.name)
            nameLbl.fontName = "AvenirNext-Bold"
            nameLbl.fontSize = 12
            nameLbl.fontColor = .white
            nameLbl.position = CGPoint(x: 0, y: -10)
            nameLbl.numberOfLines = 2
            nameLbl.preferredMaxLayoutWidth = cardWidth - 10
            nameLbl.verticalAlignmentMode = .top
            card.addChild(nameLbl)
            
            // Desc
            let descLbl = SKLabelNode(text: perk.description)
            descLbl.fontName = "AvenirNext-Regular"
            descLbl.fontSize = 10
            descLbl.fontColor = .gray
            descLbl.position = CGPoint(x: 0, y: -40)
            descLbl.preferredMaxLayoutWidth = cardWidth - 10
            descLbl.numberOfLines = 3
            descLbl.verticalAlignmentMode = .top
            card.addChild(descLbl)
            
            // Animation
            card.setScale(0)
            card.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.1),
                SKAction.scale(to: 1.1, duration: 0.2),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
        }
    }
    
    private func selectPerk(index: Int) {
        guard index < activePerkOptions.count else { return }
        let perk = activePerkOptions[index]
        
        PerkManager.shared.addPerk(perk.type)
        
        // Feedback
        AudioManager.shared.playUpgrade()
        HapticsManager.shared.onStabilization()
        
        // Toast with Particles
        // We can't put text + image easily in one label. Just text for name.
        let toast = SKLabelNode(text: "\(perk.name) Acquired!")
        toast.fontName = "AvenirNext-Bold"
        toast.fontSize = 24
        toast.fontColor = .green
        toast.position = CGPoint(x: size.width/2, y: size.height/2 + 200)
        toast.zPosition = 500
        addChild(toast)
        
        toast.run(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 50, duration: 1.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
        
        createDeathParticles(at: CGPoint(x: size.width/2, y: size.height/2), color: .cyan)

        // Close UI
        childNode(withName: "perkOverlay")?.removeFromParent()
        
        // Check for Gacha Promo (Every 10 waves) - MOVED TO didCompleteWave
        // if waveController.currentWave > 0 && waveController.currentWave % 10 == 0 { ... }
        
        isGamePaused = false
        self.scene?.view?.isPaused = false
        
        // Clear active perks so touchesBegan stops intercepting
        activePerkOptions.removeAll()
        
        // Refresh Stats
        updateTowerStats()
    }
    
    private func showGachaPromo() {
        let promo = GachaPromoUI(size: size)
        promo.position = CGPoint(x: size.width/2, y: size.height/2)
        promo.onOpenVault = { [weak self] in
            guard let self = self else { return }
            
            // Open ShopUI (Market & Vault) - NOT the old marketNode
            let shopUI = ShopUI(size: self.size)
            shopUI.zPosition = 2000
            
            // Force Gacha (Vault) tab
            shopUI.showGacha()
            
            // Center on camera if active
            if let cam = self.camera {
                shopUI.position = CGPoint.zero
                cam.addChild(shopUI)
            } else {
                shopUI.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
                self.addChild(shopUI)
            }
            
            shopUI.onClose = { [weak self] in
                self?.updateGemsLabel()
                // Unpause game when shop closes
                self?.isGamePaused = false
                self?.view?.isPaused = false
            }
            
            // Pause game while shop is open
            self.isGamePaused = true
            self.view?.isPaused = false
        }
        promo.onClose = { [weak self] in
            self?.isGamePaused = false
            self?.view?.isPaused = false
        }
        
        isGamePaused = true
        view?.isPaused = false
        addChild(promo)
    }
}

// MARK: - WaveControllerDelegate

extension GameScene: WaveControllerDelegate {
    func waveController(_ controller: WaveController, didStartWave wave: Int) {
        let chapter = controller.currentChapter
        if chapter > 1 {
            waveLabel.text = "Parti \(chapter) - Wave \(wave)"
        } else {
            waveLabel.text = "Wave \(wave)"
        }
        
        // Show chapter transition banner if this is wave 1 of a new chapter
        if wave == 1 && chapter > 1 {
            showChapterTransitionBanner(chapter: chapter)
        }
        
        AudioManager.shared.playWaveComplete()
        
        // Boss Warning
        if wave % 10 == 0 {
            showBossWarning()
        }
        
        // Configure spawner
        enemySpawner.baseHP = controller.enemyHPForWave(wave)
        enemySpawner.baseSpeed = controller.enemySpeedForWave(wave)
        enemySpawner.baseDamage = controller.enemyDamageForWave(wave)
        enemySpawner.baseCoinValue = controller.coinValueForWave(wave)
        
        enemySpawner.startWave(
            wave: wave,
            enemyCount: controller.enemyCountForWave(wave),
            spawnInterval: controller.spawnIntervalForWave(wave)
        )
        
        // Wave start animation
        let flash = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.2)
        ])
        waveLabel.run(flash)
    }
    
    func waveController(_ controller: WaveController, didCompleteWave wave: Int) {
        // Wave complete bonus
        let bonus = wave * 5
        currencyManager.addCoins(bonus)
        
        // Track for Battle Pass XP and Daily Quests
        BattlePassManager.shared.onWaveComplete(wave: wave)
        DailyQuestManager.shared.trackWaveComplete()
        DailyQuestManager.shared.trackCoinsEarned(bonus)
        
        // Haptic feedback
        if wave % 10 == 0 {
            HapticsManager.shared.onChapterComplete()
            
            // Trigger Gacha Promo (Boss Defeated / Chapter Complete)
            run(SKAction.sequence([
                SKAction.wait(forDuration: 3.0), // Wait for confetti/banner
                SKAction.run { [weak self] in
                    self?.showGachaPromo()
                }
            ]))
            
        } else {
            HapticsManager.shared.onStabilization()
        }
        
        // Wave complete celebration effect
        showWaveCompleteEffect(wave: wave, bonus: bonus)
        
        // Perk Selection (Every 5 waves)
        if wave % 5 == 0 {
            run(SKAction.sequence([
                SKAction.wait(forDuration: 2.5), // Wait for banner
                SKAction.run { [weak self] in
                    self?.showPerkSelection()
                }
            ]))
        }
    }
    
    private func showWaveCompleteEffect(wave: Int, bonus: Int) {
        // Wave complete banner
        let banner = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        banner.text = wave % 10 == 0 ? "🎉 CHAPTER COMPLETE! 🎉" : "WAVE CLEAR!"
        banner.fontSize = wave % 10 == 0 ? 34 : 28
        banner.fontColor = wave % 10 == 0 ? .yellow : .cyan
        banner.position = CGPoint(x: size.width / 2, y: size.height / 2 + 50)
        banner.zPosition = 300
        banner.setScale(0)
        addChild(banner)
        
        // Bonus label
        let bonusLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        bonusLabel.text = "+\(bonus) 💰"
        bonusLabel.fontSize = 22
        bonusLabel.fontColor = .yellow
        bonusLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bonusLabel.zPosition = 300
        bonusLabel.alpha = 0
        addChild(bonusLabel)
        
        // Animations
        let popIn = SKAction.scale(to: 1.1, duration: 0.2)
        popIn.timingMode = .easeOut
        let settle = SKAction.scale(to: 1.0, duration: 0.1)
        let hold = SKAction.wait(forDuration: 1.0)
        let fadeOut = SKAction.group([
            SKAction.fadeOut(withDuration: 0.4),
            SKAction.moveBy(x: 0, y: 30, duration: 0.4)
        ])
        
        banner.run(SKAction.sequence([popIn, settle, hold, fadeOut, SKAction.removeFromParent()]))
        
        bonusLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.wait(forDuration: 0.8),
            fadeOut,
            SKAction.removeFromParent()
        ]))
    }
}

// MARK: - ProjectileManagerDelegate

extension GameScene: ProjectileManagerDelegate {
    func projectileManager(_ manager: ProjectileManager, didHitEnemy enemy: Enemy, withDamage damage: CGFloat, isCritical: Bool) {
        // Create hit particles
        createHitEffect(at: enemy.position, isCritical: isCritical)
        
        // Damage number popup
        createDamageNumber(at: enemy.position, damage: damage, isCritical: isCritical)
        
        // On kill
        if enemy.isDead {
            // Combo system (Delegated to Manager)
            ComboManager.shared.addKill(at: enemy.position, on: self, speed: self.gameSpeed)
            
            // Track kill for quests and achievements
            let isBoss = enemy.enemyType == .boss
            DailyQuestManager.shared.trackKill(isBoss: isBoss)
            if isBoss {
                BattlePassManager.shared.onBossKill()
            }
            
            // Coin collection
            let baseCoins = Int(Double(enemy.coinValue) * PerkManager.shared.coinMultiplier)
            currencyManager.addCoins(baseCoins)
            
            animateCoinCollection(from: enemy.position)
            createDeathParticles(at: enemy.position, color: enemy.enemyType.color)
            
            // Haptic feedback on kill (only for boss to avoid spam)
            if isBoss {
                HapticsManager.shared.onExplosion()
                visualFeedback.screenShake(camera: camera)
            }
        }
        
        // Tesla Chain Trigger (On Hit)
        if PerkManager.shared.teslaChainCount > 0 {
             triggerTeslaChain(from: enemy, damage: damage)
        }
    }
    
    private func triggerTeslaChain(from sourceEnemy: Enemy, damage: CGFloat) {
        // 25% Chance to proc
        guard CGFloat.random(in: 0...1) <= 0.25 else { return }
        
        let chainLevel = PerkManager.shared.teslaChainCount
        let maxJumps = 2 + chainLevel
        let jumpRange: CGFloat = 200
        let chainDamage = damage * 0.4
        
        // We'll run this async-like recursively to simulate travel speed? 
        // Or just instant. Instant is better for performance, maybe sequential delays for visual.
        
        let currentSource = sourceEnemy
        let hitEnemies: Set<Enemy> = [sourceEnemy]
        
        // Use a recursive sequence to create "jump" delays
        chainRecursive(source: currentSource, jumpsLeft: maxJumps, range: jumpRange, damage: chainDamage, hitList: hitEnemies)
    }
    
    private func chainRecursive(source: Enemy, jumpsLeft: Int, range: CGFloat, damage: CGFloat, hitList: Set<Enemy>) {
        guard jumpsLeft > 0 else { return }
        
        let allEnemies = enemySpawner.getEnemies()
        var bestTarget: Enemy?
        var bestDist: CGFloat = range
        
        for enemy in allEnemies {
            if enemy.isDead || hitList.contains(enemy) { continue }
            
            let dx = enemy.position.x - source.position.x
            let dy = enemy.position.y - source.position.y
            let dist = sqrt(dx*dx + dy*dy)
            
            if dist < bestDist {
                bestDist = dist
                bestTarget = enemy
            }
        }
        
        guard let target = bestTarget else { return }
        
        // Zap effect
        createLightningEffect(from: source.position, to: target.position)
        AudioManager.shared.playSpark() // Need to ensure this exists or use generic hit
        
        // Damage
        target.takeDamage(damage)
        createDamageNumber(at: target.position, damage: damage, isCritical: false) // Cyan color maybe?
        
        // Next Jump
        var newHitList = hitList
        newHitList.insert(target)
        
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.1),
            SKAction.run { [weak self] in
                self?.chainRecursive(source: target, jumpsLeft: jumpsLeft - 1, range: range, damage: damage, hitList: newHitList)
            }
        ]))
    }
    
    private func createLightningEffect(from start: CGPoint, to end: CGPoint) {
        let path = CGMutablePath()
        path.move(to: start)
        
        // Simple ZigZag: Midpoint displacement
        let midX = (start.x + end.x) / 2
        let midY = (start.y + end.y) / 2
        
        // Add random jitter
        let jitter: CGFloat = 20
        let jX = CGFloat.random(in: -jitter...jitter)
        let jY = CGFloat.random(in: -jitter...jitter)
        
        path.addLine(to: CGPoint(x: midX + jX, y: midY + jY))
        path.addLine(to: end)
        
        let bolt = SKShapeNode(path: path)
        bolt.strokeColor = .cyan
        bolt.lineWidth = 3
        bolt.glowWidth = 5
        bolt.zPosition = 60
        bolt.blendMode = .add
        addChild(bolt)
        
        // Fade out
        bolt.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.1),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ]))
    }
    
    private func createHitEffect(at position: CGPoint, isCritical: Bool) {
        // Sound
        AudioManager.shared.playEnemyHit()
        
        // Flash
        let flash = SKShapeNode(circleOfRadius: isCritical ? 15 : 8)
        flash.fillColor = isCritical ? SKColor(red: 1.0, green: 0.42, blue: 0.0, alpha: 1.0) : .white
        flash.strokeColor = .clear
        flash.glowWidth = isCritical ? 10 : 5
        flash.blendMode = .add
        flash.position = position
        flash.zPosition = 50
        addChild(flash)
        
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: isCritical ? 2.0 : 1.5, duration: 0.1),
                SKAction.fadeOut(withDuration: 0.1)
            ]),
            SKAction.removeFromParent()
        ]))
        
        // Sparks (Juice)
        for _ in 0..<(isCritical ? 8 : 4) {
            let spark = SKShapeNode(rectOf: CGSize(width: 2, height: 6))
            spark.fillColor = .yellow
            spark.strokeColor = .clear
            spark.position = position
            spark.zPosition = 51
            addChild(spark)
            
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let speed = CGFloat.random(in: 50...150)
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed
            
            spark.zRotation = angle - .pi/2
            
            let move = SKAction.move(by: CGVector(dx: dx * 0.2, dy: dy * 0.2), duration: 0.2)
            let shrink = SKAction.scale(to: 0, duration: 0.2)
            
            spark.run(SKAction.sequence([
                SKAction.group([move, shrink]),
                SKAction.removeFromParent()
            ]))
        }
    }
    
    private func createDeathParticles(at position: CGPoint, color: SKColor) {
        // Spawn 8 particles in random directions
        for _ in 0..<8 {
            let particle = SKShapeNode(rectOf: CGSize(width: 4, height: 4))
            particle.fillColor = color
            particle.strokeColor = .clear
            particle.glowWidth = 2
            particle.position = position
            particle.zPosition = 40
            addChild(particle)
            
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let distance = CGFloat.random(in: 30...60)
            let destination = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )
            
            particle.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: destination, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.scale(to: 0.3, duration: 0.3)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }
    
    // MARK: - Damage Numbers & Combo
    
    private func createDamageNumber(at position: CGPoint, damage: CGFloat, isCritical: Bool) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = isCritical ? "\(Int(damage))!" : "\(Int(damage))"
        label.fontSize = isCritical ? 22 : 16
        label.fontColor = isCritical ? SKColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0) : .white
        label.position = CGPoint(x: position.x + CGFloat.random(in: -10...10), y: position.y + 20)
        label.zPosition = 150
        label.setScale(0.5)
        addChild(label)
        
        let rise = SKAction.moveBy(x: 0, y: 40, duration: 0.6)
        let grow = SKAction.scale(to: isCritical ? 1.2 : 1.0, duration: 0.1)
        let shrink = SKAction.scale(to: 0.3, duration: 0.5)
        let fade = SKAction.fadeOut(withDuration: 0.3)
        
        label.run(SKAction.sequence([
            grow,
            SKAction.group([rise, SKAction.sequence([SKAction.wait(forDuration: 0.3), shrink, fade])]),
            SKAction.removeFromParent()
        ]))
    }
    
    private func createHealBeam(from start: CGPoint, to end: CGPoint) {
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)
        
        let beam = SKShapeNode(path: path)
        beam.strokeColor = .green
        beam.lineWidth = 3
        beam.blendMode = .add
        beam.zPosition = 60
        addChild(beam)
        
        beam.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
        
        // Plus symbols
        let plus = SKLabelNode(text: "➕")
        plus.fontSize = 16
        plus.position = end
        plus.zPosition = 61
        addChild(plus)
        
        plus.run(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 20, duration: 0.5),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ]))
    }
    
    private func showComboLabel(count: Int, at position: CGPoint) {
        let comboLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        comboLabel.text = "\(count)x COMBO!"
        comboLabel.name = "comboLabel"  // For duplicate check
        comboLabel.fontSize = 28
        comboLabel.fontColor = .orange
        comboLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.7)
        comboLabel.zPosition = 200
        comboLabel.setScale(0.3)
        addChild(comboLabel)
        
        // Neon glow effect
        let glowLabel = comboLabel.copy() as! SKLabelNode
        glowLabel.fontColor = .yellow
        glowLabel.alpha = 0.5
        glowLabel.setScale(1.05)
        comboLabel.addChild(glowLabel)
        
        let popIn = SKAction.scale(to: 1.2, duration: 0.15)
        popIn.timingMode = .easeOut
        let settle = SKAction.scale(to: 1.0, duration: 0.1)
        let wait = SKAction.wait(forDuration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        
        comboLabel.run(SKAction.sequence([popIn, settle, wait, fadeOut, SKAction.removeFromParent()]))
    }
    
    // MARK: - Pause Menu
    
    private func togglePause() {
        if isGamePaused {
            hidePauseMenu()
        } else {
            showPauseMenu()
        }
    }
    
    private func showPauseMenu() {
        isGamePaused = true
        self.scene?.view?.isPaused = true
        
        // Create overlay
        let overlay = SKNode()
        overlay.name = "pauseOverlay"
        overlay.zPosition = 3000
        
        // Dark background
        let bg = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        bg.fillColor = SKColor.black.withAlphaComponent(0.85)
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(bg)
        
        // MARK: - Glassmorphism Panel
        let panelWidth: CGFloat = size.width * 0.88
        let panelHeight: CGFloat = 520  // Taller for sliders
        let panelCenter = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // Outer glow
        let panelGlow = SKShapeNode(rectOf: CGSize(width: panelWidth + 8, height: panelHeight + 8), cornerRadius: 22)
        panelGlow.fillColor = .clear
        panelGlow.strokeColor = SKColor.cyan.withAlphaComponent(0.4)
        panelGlow.lineWidth = 3
        panelGlow.glowWidth = 15
        panelGlow.position = panelCenter
        overlay.addChild(panelGlow)
        
        // Main panel
        let panel = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 18)
        panel.fillColor = SKColor(red: 0.03, green: 0.05, blue: 0.12, alpha: 0.97)
        panel.strokeColor = SKColor.cyan.withAlphaComponent(0.6)
        panel.lineWidth = 2
        panel.position = panelCenter
        panel.name = "pausePanel"
        overlay.addChild(panel)
        
        // Title
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleLabel.text = "PAUSED"
        titleLabel.fontSize = 32
        titleLabel.fontColor = .cyan
        titleLabel.position = CGPoint(x: 0, y: panelHeight/2 - 45)
        panel.addChild(titleLabel)
        
        if let pauseIcon = SKTexture.fromSymbol(name: "pause.circle.fill", pointSize: 26) {
            let icon = SKSpriteNode(texture: pauseIcon)
            icon.size = CGSize(width: 26, height: 26)
            icon.position = CGPoint(x: -75, y: panelHeight/2 - 45)
            icon.color = .cyan
            icon.colorBlendFactor = 1.0
            panel.addChild(icon)
        }
        
        // MARK: - Volume Sliders Section
        let sliderStartY: CGFloat = panelHeight/2 - 100
        
        // Section title
        let audioTitle = SKLabelNode(fontNamed: "AvenirNext-Bold")
        audioTitle.text = "AUDIO SETTINGS"
        audioTitle.fontSize = 14
        audioTitle.fontColor = SKColor(white: 0.5, alpha: 1)
        audioTitle.position = CGPoint(x: 0, y: sliderStartY + 15)
        panel.addChild(audioTitle)
        
        // Master Volume
        let masterSlider = createVolumeSlider(
            label: "Master",
            iconName: "speaker.wave.3.fill",
            value: AudioManager.shared.masterVolume,
            yPos: sliderStartY - 30,
            sliderName: "masterVolume"
        )
        panel.addChild(masterSlider)
        
        // Music Volume
        let musicSlider = createVolumeSlider(
            label: "Music",
            iconName: "music.note",
            value: AudioManager.shared.musicVolume,
            yPos: sliderStartY - 80,
            sliderName: "musicVolume"
        )
        panel.addChild(musicSlider)
        
        // SFX Volume
        let sfxSlider = createVolumeSlider(
            label: "SFX",
            iconName: "speaker.wave.2.fill",
            value: AudioManager.shared.sfxVolume,
            yPos: sliderStartY - 130,
            sliderName: "sfxVolume"
        )
        panel.addChild(sfxSlider)
        
        // Separator
        let separator = SKShapeNode(rectOf: CGSize(width: panelWidth - 50, height: 1))
        separator.fillColor = SKColor.cyan.withAlphaComponent(0.2)
        separator.strokeColor = .clear
        separator.position = CGPoint(x: 0, y: sliderStartY - 175)
        panel.addChild(separator)
        
        // MARK: - Stats Section
        let statsTitle = SKLabelNode(fontNamed: "AvenirNext-Bold")
        statsTitle.text = "SESSION STATS"
        statsTitle.fontSize = 14
        statsTitle.fontColor = SKColor(white: 0.5, alpha: 1)
        statsTitle.position = CGPoint(x: 0, y: sliderStartY - 200)
        panel.addChild(statsTitle)
        
        let stats = GameStats.shared
        let statsY: CGFloat = sliderStartY - 240
        
        let statsData = [
            ("Kills", "\(stats.enemiesKilled)", "target"),
            ("Bosses", "\(stats.bossesKilled)", "crown.fill"),
            ("Combo", "\(stats.maxCombo)", "flame.fill"),
            ("Time", stats.formattedTime, "clock.fill")
        ]
        
        for (i, stat) in statsData.enumerated() {
            let xPos = (i % 2 == 0) ? -70 : 70
            let yPos = statsY - CGFloat(i / 2) * 30
            
            if let iconTexture = SKTexture.fromSymbol(name: stat.2, pointSize: 12) {
                let icon = SKSpriteNode(texture: iconTexture)
                icon.size = CGSize(width: 12, height: 12)
                icon.position = CGPoint(x: CGFloat(xPos) - 45, y: yPos)
                icon.color = .gray
                icon.colorBlendFactor = 1.0
                panel.addChild(icon)
            }
            
            let label = SKLabelNode(text: "\(stat.0): \(stat.1)")
            label.fontName = "AvenirNext-Medium"
            label.fontSize = 12
            label.fontColor = SKColor(white: 0.7, alpha: 1)
            label.horizontalAlignmentMode = .left
            label.position = CGPoint(x: CGFloat(xPos) - 30, y: yPos - 4)
            panel.addChild(label)
        }
        
        // MARK: - Action Buttons
        let resumeBtn = createActionButton(
            text: "RESUME",
            iconName: "play.fill",
            color: .green,
            position: CGPoint(x: 0, y: -panelHeight/2 + 90)
        )
        resumeBtn.name = "resumeButton"
        panel.addChild(resumeBtn)
        
        let restartBtn = createActionButton(
            text: "RESTART",
            iconName: "arrow.counterclockwise",
            color: .orange,
            position: CGPoint(x: 0, y: -panelHeight/2 + 45)
        )
        restartBtn.name = "restartFromPause"
        panel.addChild(restartBtn)
        
        pauseOverlay = overlay
        addChild(overlay)
        
        self.scene?.view?.isPaused = false
    }
    
    private func createVolumeSlider(label: String, iconName: String, value: Float, yPos: CGFloat, sliderName: String) -> SKNode {
        let container = SKNode()
        container.position = CGPoint(x: 0, y: yPos)
        container.name = sliderName
        
        // Icon
        if let iconTexture = SKTexture.fromSymbol(name: iconName, pointSize: 18) {
            let icon = SKSpriteNode(texture: iconTexture)
            icon.size = CGSize(width: 18, height: 18)
            icon.position = CGPoint(x: -120, y: 0)
            icon.color = .cyan
            icon.colorBlendFactor = 1.0
            container.addChild(icon)
        }
        
        // Label
        let lbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        lbl.text = label
        lbl.fontSize = 14
        lbl.fontColor = .white
        lbl.horizontalAlignmentMode = .left
        lbl.position = CGPoint(x: -95, y: -5)
        container.addChild(lbl)
        
        // Minus button
        let minusBtn = SKShapeNode(circleOfRadius: 15)
        minusBtn.fillColor = SKColor(white: 0.2, alpha: 1)
        minusBtn.strokeColor = .gray
        minusBtn.lineWidth = 1
        minusBtn.position = CGPoint(x: -20, y: 0)
        minusBtn.name = "\(sliderName)_minus"
        container.addChild(minusBtn)
        
        let minusLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        minusLabel.text = "-"
        minusLabel.fontSize = 18
        minusLabel.fontColor = .white
        minusLabel.verticalAlignmentMode = .center
        minusBtn.addChild(minusLabel)
        
        // Slider track
        let trackWidth: CGFloat = 80
        let track = SKShapeNode(rectOf: CGSize(width: trackWidth, height: 6), cornerRadius: 3)
        track.fillColor = SKColor(white: 0.2, alpha: 1)
        track.strokeColor = .clear
        track.position = CGPoint(x: 45, y: 0)
        container.addChild(track)
        
        // Slider fill
        let fillWidth = trackWidth * CGFloat(value)
        let fill = SKShapeNode(rectOf: CGSize(width: fillWidth, height: 6), cornerRadius: 3)
        fill.fillColor = .cyan
        fill.strokeColor = .clear
        fill.position = CGPoint(x: 45 - (trackWidth - fillWidth) / 2, y: 0)
        fill.name = "\(sliderName)_fill"
        container.addChild(fill)
        
        // Plus button
        let plusBtn = SKShapeNode(circleOfRadius: 15)
        plusBtn.fillColor = SKColor(white: 0.2, alpha: 1)
        plusBtn.strokeColor = .gray
        plusBtn.lineWidth = 1
        plusBtn.position = CGPoint(x: 110, y: 0)
        plusBtn.name = "\(sliderName)_plus"
        container.addChild(plusBtn)
        
        let plusLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        plusLabel.text = "+"
        plusLabel.fontSize = 18
        plusLabel.fontColor = .white
        plusLabel.verticalAlignmentMode = .center
        plusBtn.addChild(plusLabel)
        
        // Value label
        let valueLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        valueLbl.text = "\(Int(value * 100))%"
        valueLbl.fontSize = 12
        valueLbl.fontColor = .cyan
        valueLbl.position = CGPoint(x: 45, y: -18)
        valueLbl.name = "\(sliderName)_value"
        container.addChild(valueLbl)
        
        return container
    }
    
    private func createToggleButton(label: String, isOn: Bool, iconName: String, position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        
        let bg = SKShapeNode(rectOf: CGSize(width: 120, height: 60), cornerRadius: 10)
        bg.fillColor = isOn ? SKColor.cyan.withAlphaComponent(0.2) : SKColor.gray.withAlphaComponent(0.2)
        bg.strokeColor = isOn ? .cyan : .gray
        bg.lineWidth = 1.5
        container.addChild(bg)
        
        if let iconTexture = SKTexture.fromSymbol(name: iconName, pointSize: 20) {
            let icon = SKSpriteNode(texture: iconTexture)
            icon.size = CGSize(width: 20, height: 20)
            icon.position = CGPoint(x: 0, y: 10)
            icon.color = isOn ? .cyan : .gray
            icon.colorBlendFactor = 1.0
            icon.name = "icon"
            container.addChild(icon)
        }
        
        let labelNode = SKLabelNode(text: label)
        labelNode.fontName = "AvenirNext-Bold"
        labelNode.fontSize = 12
        labelNode.fontColor = isOn ? .cyan : .gray
        labelNode.position = CGPoint(x: 0, y: -20)
        labelNode.name = "label"
        container.addChild(labelNode)
        
        let statusLabel = SKLabelNode(text: isOn ? "ON" : "OFF")
        statusLabel.fontName = "AvenirNext-Heavy"
        statusLabel.fontSize = 10
        statusLabel.fontColor = isOn ? .green : .red
        statusLabel.position = CGPoint(x: 45, y: -8)
        statusLabel.name = "status"
        container.addChild(statusLabel)
        
        return container
    }
    

    
    private func createActionButton(text: String, iconName: String, color: SKColor, position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        
        let bg = SKShapeNode(rectOf: CGSize(width: 180, height: 36), cornerRadius: 8)
        bg.fillColor = color.withAlphaComponent(0.2)
        bg.strokeColor = color
        bg.lineWidth = 1.5
        bg.glowWidth = 3
        container.addChild(bg)
        
        if let iconTexture = SKTexture.fromSymbol(name: iconName, pointSize: 16) {
            let icon = SKSpriteNode(texture: iconTexture)
            icon.size = CGSize(width: 16, height: 16)
            icon.position = CGPoint(x: -65, y: 0)
            icon.color = color
            icon.colorBlendFactor = 1.0
            container.addChild(icon)
        }
        
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 16
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 10, y: 0)
        container.addChild(label)
        
        return container
    }
    
    private func hidePauseMenu() {
        isGamePaused = false
        pauseOverlay?.removeFromParent()
        pauseOverlay = nil
    }
    
    private func handleVolumeButton(_ buttonName: String) {
        let isPlus = buttonName.contains("_plus")
        let change: Float = isPlus ? 0.1 : -0.1
        
        if buttonName.contains("masterVolume") {
            AudioManager.shared.masterVolume = max(0, min(1, AudioManager.shared.masterVolume + change))
        } else if buttonName.contains("musicVolume") {
            AudioManager.shared.musicVolume = max(0, min(1, AudioManager.shared.musicVolume + change))
        } else if buttonName.contains("sfxVolume") {
            AudioManager.shared.sfxVolume = max(0, min(1, AudioManager.shared.sfxVolume + change))
        }
        
        // Play feedback sound
        AudioManager.shared.playButtonTap()
        
        // Refresh pause menu to update slider
        hidePauseMenu()
        showPauseMenu()
    }

    // MARK: - Boss Effects
    
    private func showBossWarning() {
        // Sound
        AudioManager.shared.playBossSpawn()
        
        // Haptic (Heavy)
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        // Shake Screen (View)
        if let view = self.view {
            let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
            shake.timingFunction = CAMediaTimingFunction(name: .linear)
            shake.duration = 0.6
            shake.values = [-10.0, 10.0, -10.0, 10.0, -5.0, 5.0, 0.0]
            view.layer.add(shake, forKey: "shake")
        }
        
        // Warning Label
        let warningNode = SKNode()
        warningNode.position = CGPoint(x: size.width/2, y: size.height/2 + 100)
        warningNode.zPosition = 300
        addChild(warningNode)
        
        // Red Strip background
        let strip = SKShapeNode(rectOf: CGSize(width: size.width, height: 80))
        strip.fillColor = SKColor.red.withAlphaComponent(0.6)
        strip.strokeColor = .clear
        warningNode.addChild(strip)
        
        // Text
        let lbl = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        lbl.text = "⚠️ BOSS IS COMING ⚠️"
        lbl.fontSize = 32
        lbl.fontColor = .white
        lbl.verticalAlignmentMode = .center
        warningNode.addChild(lbl)
        
        // Animations
        warningNode.setScale(0)
        warningNode.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.wait(forDuration: 2.0),
            SKAction.scale(to: 0.0, duration: 0.2),
            SKAction.removeFromParent()
        ]))
        
        // Pulse text
        lbl.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.3)
        ])))
        
        // Flash strip
        strip.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.8, duration: 0.2),
            SKAction.fadeAlpha(to: 0.4, duration: 0.2)
        ])))
    }
}

// MARK: - CurrencyManagerDelegate

extension GameScene: CurrencyManagerDelegate {
    func currencyManager(_ manager: CurrencyManager, didUpdateCoins coins: Int) {
        updateCoinsLabel()
    }
}


// MARK: - Combo Delegate
extension GameScene: ComboManagerDelegate {
    func onComboUpdated(count: Int, bonus: Int) {
        DailyQuestManager.shared.trackCombo(count)
    }
    
    func onComboEnded(finalCount: Int) {
        // Optional: Show summary?
    }
}

// MARK: - Test Chapter Jump (Dev Only)
extension GameScene {
    private func showChapterTransitionBanner(chapter: Int) {
        let bannerNode = SKNode()
        bannerNode.position = CGPoint(x: size.width/2, y: size.height/2 + 80)
        bannerNode.zPosition = 350
        addChild(bannerNode)
        
        // Gradient background strip
        let strip = SKShapeNode(rectOf: CGSize(width: size.width, height: 100))
        strip.fillColor = SKColor.magenta.withAlphaComponent(0.7)
        strip.strokeColor = .clear
        bannerNode.addChild(strip)
        
        // Main Title
        let titleLbl = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleLbl.text = "🎯 PARTİ \(chapter) 🎯"
        titleLbl.fontSize = 42
        titleLbl.fontColor = .white
        titleLbl.verticalAlignmentMode = .center
        titleLbl.position = CGPoint(x: 0, y: 12)
        bannerNode.addChild(titleLbl)
        
        // Subtitle
        let subLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        subLbl.text = "Zorluk arttı!"
        subLbl.fontSize = 18
        subLbl.fontColor = SKColor.yellow
        subLbl.verticalAlignmentMode = .center
        subLbl.position = CGPoint(x: 0, y: -20)
        bannerNode.addChild(subLbl)
        
        // Animations
        bannerNode.setScale(0)
        bannerNode.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.25),
            SKAction.scale(to: 1.0, duration: 0.15),
            SKAction.wait(forDuration: 2.5),
            SKAction.group([
                SKAction.scale(to: 0.0, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))
        
        // Pulse title
        titleLbl.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.4),
            SKAction.scale(to: 1.0, duration: 0.4)
        ])))
        
        // Strong haptic
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    func jumpToChapter(_ chapter: Int) {
        // Clear current wave state and enemies
        enemySpawner.clearEnemies()
        projectileManager.reset()
        
        // Use WaveController's jump method
        waveController.jumpToChapter(chapter)
        
        // Update wave label immediately
        if chapter > 1 {
            waveLabel.text = "Parti \(chapter) - Wave 1"
        } else {
            waveLabel.text = "Wave 1"
        }
        
        // Show banner
        if chapter > 1 {
            showChapterTransitionBanner(chapter: chapter)
        }
        
        // Start the first wave of the chapter
        waveController.startNextWave()
        
        showFloatingText("Parti \(chapter)'e atlandı!", at: CGPoint(x: size.width/2, y: size.height/2), color: .magenta)
    }
}
