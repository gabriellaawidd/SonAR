//
//  PlacementOutcome.swift
//  SonAR
//
//  Created by Tiffany Michelle on 12/08/26.
//

import Foundation

enum PlacementOutcome: Equatable {

    case bounceBack

    case bounceAway

    case absorbed

    var lesson: GuidedLesson {
        switch self {
        case .bounceBack: return .bounceBack
        case .bounceAway: return .bounceAway
        case .absorbed: return .absorbed
        }
    }
}
