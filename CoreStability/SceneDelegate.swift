// SceneDelegate.swift
// CoreStability

import UIKit
import AVFoundation
import AppTrackingTransparency

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = GameViewController()
        window?.makeKeyAndVisible()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Pause audio when app goes to background / app switcher / interrupted
        AudioManager.shared.pauseBackgroundMusic()
        
        // Notify Game to Pause (if active)
        NotificationCenter.default.post(name: .appWillResignActive, object: nil)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Resume audio when app comes back
        AudioManager.shared.resumeBackgroundMusic()
        
        // Request App Tracking Transparency
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { status in
                // Handle status if needed
            }
        }
        
        // Notify Game (Optional, maybe keep paused for user safety)
        NotificationCenter.default.post(name: .appDidBecomeActive, object: nil)
    }
}

extension Notification.Name {
    static let appWillResignActive = Notification.Name("appWillResignActive")
    static let appDidBecomeActive = Notification.Name("appDidBecomeActive")
}
