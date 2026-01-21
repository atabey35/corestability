// ChapterController.swift
// CoreStability
// 10-chapter progression with FULL RESET between chapters
// Each chapter = separate run with different system parameters

import Foundation
import QuartzCore

struct ChapterConfiguration {
    let chapter: Int
    let stabilizationsRequired: Int
    let systemDecayModifier: Float      // Higher = nodes decay faster
    let chaosRecoveryModifier: Float    // Lower = chaos recovers slower
    let penaltySeverityModifier: Float  // Higher = harsher penalties
    let marginOfError: Float            // Lower = less forgiveness
}

protocol ChapterControllerDelegate: AnyObject {
    func chapterControllerDidCompleteChapter(_ controller: ChapterController)
    func chapterControllerRequestsFullReset(_ controller: ChapterController)
    func chapterControllerDidTriggerVictory(_ controller: ChapterController)
}

/// Manages 10-chapter progression
/// CRITICAL: Each chapter completion = FULL RESET
final class ChapterController {
    
    weak var delegate: ChapterControllerDelegate?
    
    private(set) var currentChapter: Int = 1
    private(set) var currentConfig: ChapterConfiguration
    
    private(set) var stabilizationsThisChapter: Int = 0
    private(set) var isInTransition: Bool = false
    
    private var transitionStartTime: TimeInterval = 0
    private let transitionDuration: TimeInterval = 2.0
    
    // MARK: - Chapter Configs (DIFFICULTY VIA REDUCED FORGIVENESS)
    
    private static let chapters: [ChapterConfiguration] = [
        // Chapter 1: Very forgiving - learn basics
        ChapterConfiguration(chapter: 1, stabilizationsRequired: 2,
                           systemDecayModifier: 0.6, chaosRecoveryModifier: 1.4,
                           penaltySeverityModifier: 0.4, marginOfError: 1.5),
        
        // Chapter 2: Still easy
        ChapterConfiguration(chapter: 2, stabilizationsRequired: 3,
                           systemDecayModifier: 0.7, chaosRecoveryModifier: 1.3,
                           penaltySeverityModifier: 0.5, marginOfError: 1.4),
        
        // Chapter 3: Introduce challenge
        ChapterConfiguration(chapter: 3, stabilizationsRequired: 4,
                           systemDecayModifier: 0.8, chaosRecoveryModifier: 1.2,
                           penaltySeverityModifier: 0.6, marginOfError: 1.3),
        
        // Chapter 4: Building skill
        ChapterConfiguration(chapter: 4, stabilizationsRequired: 5,
                           systemDecayModifier: 0.9, chaosRecoveryModifier: 1.1,
                           penaltySeverityModifier: 0.7, marginOfError: 1.2),
        
        // Chapter 5: Mid-point
        ChapterConfiguration(chapter: 5, stabilizationsRequired: 6,
                           systemDecayModifier: 1.0, chaosRecoveryModifier: 1.0,
                           penaltySeverityModifier: 0.8, marginOfError: 1.1),
        
        // Chapter 6: Pressure increases
        ChapterConfiguration(chapter: 6, stabilizationsRequired: 7,
                           systemDecayModifier: 1.1, chaosRecoveryModifier: 0.95,
                           penaltySeverityModifier: 0.9, marginOfError: 1.0),
        
        // Chapter 7: Expert territory
        ChapterConfiguration(chapter: 7, stabilizationsRequired: 8,
                           systemDecayModifier: 1.2, chaosRecoveryModifier: 0.9,
                           penaltySeverityModifier: 1.0, marginOfError: 0.9),
        
        // Chapter 8: Mastery required
        ChapterConfiguration(chapter: 8, stabilizationsRequired: 9,
                           systemDecayModifier: 1.3, chaosRecoveryModifier: 0.85,
                           penaltySeverityModifier: 1.1, marginOfError: 0.8),
        
        // Chapter 9: The crucible
        ChapterConfiguration(chapter: 9, stabilizationsRequired: 10,
                           systemDecayModifier: 1.4, chaosRecoveryModifier: 0.8,
                           penaltySeverityModifier: 1.2, marginOfError: 0.7),
        
        // Chapter 10: FINAL
        ChapterConfiguration(chapter: 10, stabilizationsRequired: 12,
                           systemDecayModifier: 1.5, chaosRecoveryModifier: 0.75,
                           penaltySeverityModifier: 1.3, marginOfError: 0.6)
    ]
    
    init() {
        currentConfig = ChapterController.chapters[0]
    }
    
    func startChapter(_ chapter: Int) {
        guard chapter >= 1 && chapter <= 10 else { return }
        currentChapter = chapter
        currentConfig = ChapterController.chapters[chapter - 1]
        stabilizationsThisChapter = 0
        isInTransition = false
    }
    
    func resetToChapterOne() {
        startChapter(1)
    }
    
    func update(deltaTime: TimeInterval) {
        guard isInTransition else { return }
        
        let elapsed = CACurrentMediaTime() - transitionStartTime
        if elapsed >= transitionDuration {
            if currentChapter >= 10 {
                delegate?.chapterControllerDidTriggerVictory(self)
            } else {
                // FULL RESET then advance
                delegate?.chapterControllerRequestsFullReset(self)
                startChapter(currentChapter + 1)
            }
            isInTransition = false
        }
    }
    
    func onNodeStabilized() {
        guard !isInTransition else { return }
        stabilizationsThisChapter += 1
        
        if stabilizationsThisChapter >= currentConfig.stabilizationsRequired {
            triggerChapterComplete()
        }
    }
    
    private func triggerChapterComplete() {
        isInTransition = true
        transitionStartTime = CACurrentMediaTime()
        delegate?.chapterControllerDidCompleteChapter(self)
    }
    
    func onGameOver() {
        // Reset to chapter 1
    }
    
    var chapterProgress: Float {
        return Float(stabilizationsThisChapter) / Float(currentConfig.stabilizationsRequired)
    }
}
