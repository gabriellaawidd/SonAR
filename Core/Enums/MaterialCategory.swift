//
//  MaterialCategory.swift
//  SonAR
//
//  Created by Gabriella Angelina Widjaja on 07/08/26.
//

import Foundation

enum MaterialCategory: String, Codable {
    case soft
    case hard
    case unknown
    case lowConfidence
    
    var acousticImpedanceMRayl: Float {
        switch self {
            case .soft:
                return 0.15
            case .hard:
                return 2.9
            case .unknown, .lowConfidence:
                return 0.0012
        }
    }
}

