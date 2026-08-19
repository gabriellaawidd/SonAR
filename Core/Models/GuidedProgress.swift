//
//  GuidedProgress.swift
//  SonAR
//
//  Created by Tiffany Michelle on 12/08/26.
//

import Foundation

enum GuidedResolution: Equatable {

    case lesson(GuidedLesson)

    case retry(GuidedRetryReason)
}

struct GuidedProgress: Equatable {

    private(set) var completed: Set<GuidedLesson> = []
    private(set) var objective: GuidedObjective = .anyAngle

    private(set) var attempts: Int = 0

    init() {}

    var usesMaterialDetection: Bool { objective.usesMaterialDetection }

    var forcedMaterial: MaterialCategory? { objective.forcedMaterial }

    var isFinished: Bool { objective == .finished }

    var prompt: GuidedPrompt {
        switch objective {
        case .anyAngle:
            return .findFlat
        case .angle(.bounceBack):
            return completed.isEmpty ? .findFlat : .findStraight
        case .angle(.bounceAway), .angle(.absorbed):
            return .findSteep
        case .soft:
            return attempts >= 2 ? .findSoftRetry : .findSoft
        case .finished:
            return .findSoft
        }
    }

    var fraction: Double {
        Double(completed.count) / Double(GuidedLesson.allCases.count)
    }

    mutating func record(_ outcome: PlacementOutcome) -> GuidedResolution {
        attempts += 1

        switch objective {

        case .anyAngle:

            let lesson: GuidedLesson = (outcome == .bounceBack) ? .bounceBack : .bounceAway
            complete(lesson)
            return .lesson(lesson)

        case .angle(let target):
            if outcome.lesson == target {
                complete(target)
                return .lesson(target)
            }
            return .retry(target == .bounceBack ? .tooSteep : .notSteepEnough)

        case .soft:
            if outcome == .absorbed {
                complete(.absorbed)
                return .lesson(.absorbed)
            }
            return .retry(.notSoft)

        case .finished:
            return .lesson(.absorbed)
        }
    }

    mutating func reset() {
        completed.removeAll()
        objective = .anyAngle
        attempts = 0
    }

    private mutating func complete(_ lesson: GuidedLesson) {
        completed.insert(lesson)
        objective = nextObjective()
        attempts = 0
    }

    private func nextObjective() -> GuidedObjective {
        if !completed.contains(.bounceBack) { return .angle(.bounceBack) }
        if !completed.contains(.bounceAway) { return .angle(.bounceAway) }
        if !completed.contains(.absorbed) { return .soft }
        return .finished
    }
}
