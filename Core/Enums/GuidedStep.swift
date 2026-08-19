//
//  GuidedStep.swift
//  SonAR
//
//  Created by Tiffany Michelle on 12/08/26.
//

import CoreGraphics
import Foundation

enum GuidedObjective: Equatable {
    case anyAngle
    case angle(GuidedLesson)
    case soft
    case finished

    var usesMaterialDetection: Bool { self == .soft }

    var forcedMaterial: MaterialCategory? {
        usesMaterialDetection ? nil : .hard
    }
}

enum GuidedPrompt: Equatable, Hashable {
    case findFlat
    case findFlatAgain
    case findSteep
    case findStraight
    case findSoft
    case findSoftRetry

    var bubbleText: String {
        switch self {
        case .findFlat:
            return "Point to a flat surface and place the sensor"
        case .findFlatAgain:
            return "Now try pointing at a flat surface and tap to place again!"
        case .findSteep:
            return "Now point it at a steep surface and place it!"
        case .findStraight:
            return "Point straight at the wall, then place it"
        case .findSoft:
            return "Try pointing it to a soft objects, like shoes or carpet"
        case .findSoftRetry:
            return "Try pointing it directly to a shoe or carpet"
        }
    }

    var needsBriefing: Bool {
        switch self {
        case .findFlat:
            return false
        case .findFlatAgain, .findSteep, .findStraight, .findSoft, .findSoftRetry:
            return true
        }
    }

    var mascot: String { MascotAsset.neutral }

    var mascotHeight: CGFloat { 120 }

    var footerHint: String { "Tap anywhere to place" }
}

enum GuidedRetryReason: Equatable {
    case tooSteep
    case notSteepEnough
    case notSoft

    var bubbleText: String {
        switch self {
        case .tooSteep:
            return "Move your phone and try from a different angle"
        case .notSteepEnough:
            return "Move your sensor to a new spot"
        case .notSoft:
            return "Still feels hard. Aim it at something soft!"
        }
    }

    var mascot: String { MascotAsset.sad }
    var mascotHeight: CGFloat { 96 }
    var actionTitle: String { "Try another spot" }
}

enum GuidedStep: Equatable {
    case briefing(GuidedPrompt)
    case placePrompt(GuidedPrompt)
    case feedback(GuidedLesson)
    case retry(GuidedRetryReason)
    case finale

    var helpText: String {
        switch self {
        case .briefing(let prompt): return prompt.bubbleText
        case .placePrompt(let prompt): return prompt.bubbleText
        case .retry(let reason): return reason.bubbleText
        case .feedback(let lesson): return lesson.feedbackMessage
        case .finale: return GuidedCopy.finale
        }
    }
}

enum GuidedCopy {
    static let finale = "All done! Now, test any surface!"
    static let leaveTitle = "Leave the Tour?"
    static let leaveMessage = "You'll have to start the tour over next time."
    static let leaveConfirm = "End Tour"
    static let cancel = "Cancel"
    static let continueTitle = "Try another spot"
    static let briefingContinue = "Continue"
    static let gotIt = "Got it"
    static let exploreTitle = "Explore on my own"
}
