//
//  FeedbackPresentation.swift
//  SonAR
//
//  Created by Tiffany Michelle on 13/08/26.
//

import Foundation

struct FeedbackPresentation: Equatable {
    let badge: String
    let message: String
    let distanceText: String

    static let unknownDistance = "Distance: Unknown"

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
    }

    init(badge: String, message: String, distanceText: String) {
        self.badge = badge
        self.message = message
        self.distanceText = distanceText
    }
}
