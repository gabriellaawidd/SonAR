//
//  FeedbackPresentation.swift
//  SonAR
//
//  Created by Tiffany Michelle on 13/08/26.
//

import Foundation
import SwiftUI
import UIKit

struct FeedbackPresentation: Equatable {
    let badge: String
    let message: String
    let distanceText: String
    let badgeColor: UIColor

    static let unknownDistance = "Distance: Unknown"
    static let defaultBadgeColor = UIColor.black

    static func distanceText(from report: Wave.PulseReport?, reportsDistance: Bool) -> String {
        guard reportsDistance, let centimeters = report?.distanceCentimeters else {
            return unknownDistance
        }
        return "Distance: \(centimeters) cm"
    }

    init(lesson: GuidedLesson, report: Wave.PulseReport?) {
        badge = lesson.badge
        message = lesson.feedbackMessage
        distanceText = Self.distanceText(from: report, reportsDistance: lesson.reportsDistance)
        badgeColor = UIColor(lesson.badgeColor)
    }

    init(badge: String, message: String, distanceText: String, badgeColor: UIColor = defaultBadgeColor) {
        self.badge = badge
        self.message = message
        self.distanceText = distanceText
        self.badgeColor = badgeColor
    }

    static func soft(report: Wave.PulseReport?) -> FeedbackPresentation {
        let isFar = (report?.distanceCentimeters == nil)

        if isFar {
            return FeedbackPresentation(
                badge: GuidedLesson.bounceAway.badge,
                message: "Sound absorbed by soft material. Try to move closer!",
                distanceText: Self.unknownDistance,
                badgeColor: UIColor(GuidedLesson.bounceAway.badgeColor)
            )
        } else {
            return FeedbackPresentation(
                badge: GuidedLesson.absorbed.badge,
                message: "Soft material absorbs soundwave and limits detection range",
                distanceText: Self.distanceText(from: report, reportsDistance: true),
                badgeColor: UIColor(GuidedLesson.absorbed.badgeColor)
            )
        }
    }
}
