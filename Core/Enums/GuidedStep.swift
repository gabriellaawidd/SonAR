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

enum GuidedPrompt: Equatable {
    case findFlat
    case findFlatAgain
    case findSteep
    case findSoft

    var bubbleText: String {
        switch self {
        case .findFlat:
            return "Point at a flat surface and tap to place"
        case .findFlatAgain:
            return "Now try pointing at a flat surface and tap to place again!"
        case .findSteep:
            return "Now try pointing at a steep surface and tap to place again!"
        case .findSoft:
            return "Try pointing it to a soft objects (e.g. sofa, pillow)"
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
            return "Still feels hard. Aim it at something soft, then tap Place"
        }
    }

    var mascot: String { MascotAsset.sad }
    var mascotHeight: CGFloat { 96 }
    var actionTitle: String { "Try another spot" }
}

enum GuidedStep: Equatable {
    case placePrompt(GuidedPrompt)
    case feedback(GuidedLesson)
    case retry(GuidedRetryReason)
    case finale

    var helpText: String {
        switch self {
        case .placePrompt(let prompt): return prompt.bubbleText
        case .retry(let reason): return reason.bubbleText
        case .feedback(let lesson): return lesson.feedbackMessage
        case .finale: return GuidedCopy.finale
        }
    }
}

enum GuidedCopy {
    static let finale = "All done! Now you can freely test any surface you want."
    static let leaveTitle = "Leave the Tour?"
    static let leaveMessage = "You'll have to start the tour over next time."
    static let leaveConfirm = "End Tour"
    static let cancel = "Cancel"
    static let continueTitle = "Try another spot"
    static let exploreTitle = "Explore on my own"
}
