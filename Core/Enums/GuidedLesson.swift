//
//  GuidedLesson.swift
//  SonAR
//
//  Created by Tiffany Michelle on 12/08/26.
//

import Foundation

enum GuidedLesson: String, CaseIterable, Codable, Equatable {
    case bounceBack
    case bounceAway
    case absorbed

    var badge: String {
        switch self {
        case .bounceBack: return "ECHO DETECTED"
        case .bounceAway: return "SIGNAL LOST"
        case .absorbed: return "WEAK ECHO"
        }
    }

    var feedbackMessage: String {
        switch self {
        case .bounceBack:
            return "Flat surfaces act like a mirror, bouncing the sound wave straight back to the sensor."
        case .bounceAway:
            return "Sloped surfaces deflect the wave away. Without a returning echo, distance cannot be measured."
        case .absorbed:
            return "Soft materials absorb sound. The sensor can only detect them from a close distance!"
        }
    }

    var reportsDistance: Bool {
        self != .bounceAway
    }
}
