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

    init() {}

    var usesMaterialDetection: Bool { objective.usesMaterialDetection }

    var forcedMaterial: MaterialCategory? { objective.forcedMaterial }

    var isFinished: Bool { objective == .finished }

    var prompt: GuidedPrompt {
        switch objective {
        case .anyAngle:
            return .findFlat
        case .angle(.bounceBack):
            return completed.isEmpty ? .findFlat : .findFlatAgain
        case .angle(.bounceAway), .angle(.absorbed):
            return .findSteep
        case .soft:
            return .findSoft
        case .finished:
            return .findSoft
        }
    }

    var fraction: Double {
        Double(completed.count) / Double(GuidedLesson.allCases.count)
    }

    mutating func record(_ outcome: PlacementOutcome) -> GuidedResolution {
        switch objective {

        case .anyAngle:

            let lesson: GuidedLesson = (outcome == .bounceBack) ? .bounceBack : .bounceAway
            complete(lesson)
            return .lesson(lesson)

        case .angle(let target):
            guard outcome.lesson == target else {
                return .retry(target == .bounceBack ? .tooSteep : .notSteepEnough)
            }
            complete(target)
            return .lesson(target)

        case .soft:
            guard outcome == .absorbed else {
                return .retry(.notSoft)
            }
            complete(.absorbed)
            return .lesson(.absorbed)

        case .finished:
            return .lesson(.absorbed)
        }
    }

    mutating func reset() {
        completed.removeAll()
        objective = .anyAngle
    }

    private mutating func complete(_ lesson: GuidedLesson) {
        completed.insert(lesson)
        objective = nextObjective()
    }

    private func nextObjective() -> GuidedObjective {
        if !completed.contains(.bounceBack) { return .angle(.bounceBack) }
        if !completed.contains(.bounceAway) { return .angle(.bounceAway) }
        if !completed.contains(.absorbed) { return .soft }
        return .finished
    }
}
