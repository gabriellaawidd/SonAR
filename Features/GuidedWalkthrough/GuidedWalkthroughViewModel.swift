//
//  GuidedWalkthroughViewModel.swift
//  SonAR
//
//  Created by Tiffany Michelle on 12/08/26.
//

import Foundation

@MainActor
@Observable
final class GuidedWalkthroughViewModel {

    private(set) var step: GuidedStep = .placePrompt(.findFlat)
    private(set) var progress = GuidedProgress()
    private(set) var feedback: FeedbackPresentation?

    @ObservationIgnored private weak var model: ARSessionModel?
    @ObservationIgnored private var measurementTask: Task<Void, Never>?
    @ObservationIgnored private var isAdvancing = false

    var helpText: String { step.helpText }

    func bind(to model: ARSessionModel) {
        guard self.model !== model else { return }
        self.model = model
        syncMaterialOverride()
    }

    func tearDown() {
        measurementTask?.cancel()
        measurementTask = nil
        isAdvancing = false
        model?.dismissFeedbackRobot()
    }

    func handle(phase: AppPhase) {
        switch phase {
        case .carrying:
            measurementTask?.cancel()
            measurementTask = nil
            feedback = nil
            syncMaterialOverride()
            if !progress.isFinished {
                step = .placePrompt(progress.prompt)
            }
        case .placed:
            beginMeasurement()
        }
    }

    func homeTapped(onExit: () -> Void) {
        tearDown()
        onExit()
    }

    func continueTapped() {
        advanceFromFeedback()
    }

    func retryTapped() {
        measurementTask?.cancel()
        model?.dismissFeedbackRobot()
        model?.placeAgain()
    }

    func restart() {
        measurementTask?.cancel()
        progress.reset()
        syncMaterialOverride()
        isAdvancing = false
        feedback = nil
        step = .placePrompt(progress.prompt)
        model?.dismissFeedbackRobot()
        model?.placeAgain()
    }

    private func syncMaterialOverride() {
        model?.materialOverride = progress.forcedMaterial
    }

    private func beginMeasurement() {
        measurementTask?.cancel()
        measurementTask = Task { [weak self] in
            guard let self else { return }
            let waveStart = ContinuousClock.now

            try? await Task.sleep(for: GuidedTiming.verdictDelay)
            guard !Task.isCancelled, let model = self.model else { return }

            let outcome = self.readOutcome(from: model)
            let resolution = self.progress.record(outcome)
            self.syncMaterialOverride()

            switch resolution {
            case .lesson(let lesson):
                let presentation = FeedbackPresentation(lesson: lesson, report: model.lastPulse)
                self.feedback = presentation
                self.step = .feedback(lesson)

                let elapsed = ContinuousClock.now - waveStart
                let remaining = GuidedTiming.robotDelay - elapsed
                if remaining > .zero {
                    try? await Task.sleep(for: remaining)
                }
                guard !Task.isCancelled else { return }
                model.presentFeedbackRobot(presentation)

            case .retry(let reason):
                self.step = .retry(reason)
            }
        }
    }

    private func readOutcome(from model: ARSessionModel) -> PlacementOutcome {
        if progress.usesMaterialDetection {
            logMaterial(model)
            if model.surfaceReading?.materialCategory == .soft {
                return .absorbed
            }
        }

        let returned = model.lastPulse?.returned ?? 0
        return returned >= Wave.minReturningRays ? .bounceBack : .bounceAway
    }

    private func logMaterial(_ model: ARSessionModel) {
        guard let reading = model.surfaceReading else {
            print("[Guided] surfaceReading NIL -> raycast tidak kena permukaan, Vision tidak pernah dipanggil")
            return
        }
        print(String(
            format: "[Guided] material=%@ confidence=%.3f sudut=%.1f",
            reading.materialCategory.rawValue,
            reading.materialConfidence,
            reading.angleDegrees ?? -1
        ))
    }

    private func advanceFromFeedback() {
        guard let model, !isAdvancing else { return }
        isAdvancing = true
        model.dismissFeedbackRobot()

        Task { [weak self] in
            try? await Task.sleep(for: GuidedTiming.robotExitDuration)
            guard let self, let model = self.model else { return }
            self.isAdvancing = false
            self.feedback = nil

            if self.progress.isFinished {
                self.step = .finale
            } else {
                self.step = .placePrompt(self.progress.prompt)
                model.placeAgain()
            }
        }
    }
}
