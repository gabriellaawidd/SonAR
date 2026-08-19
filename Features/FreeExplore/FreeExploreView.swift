//
//  FreeExploreView.swift
//  SonAR
//
//  Created by Tiffany Michelle on 13/08/26.
//

import SwiftUI

struct FreeExploreView: View {
    @Binding var appState: AppState

    @State private var model = ARSessionModel()
    @State private var showHowItWorks = false
    @State private var showLeaveConfirm = false
    @State private var hasPlacedOnce = false
    @State private var showAnnotationHint = false

    var body: some View {
        ZStack {
            ARViewContainer(model: model)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ToolBarView(
                    onHome: { showLeaveConfirm = true },
                    onHowItWorks: { showHowItWorks = true }
                )

                content
                    .allowsHitTesting(false)

                Spacer(minLength: 0)

                footer
            }
            .padding(.horizontal, 20)
        }
        .animation(.easeInOut(duration: 0.25), value: model.phase)
        .animation(.easeInOut(duration: 0.25), value: showAnnotationHint)
        .task {
            model.onAnnotationTapped = { revealRobot() }
        }
        .onChange(of: model.phase) { _, newPhase in
            showAnnotationHint = false
            if newPhase == .placed {
                hasPlacedOnce = true
                scheduleAnnotation()
            } else {
                model.dismissFeedbackRobot()
            }
        }
        .onDisappear { model.teardown() }
        .sheet(isPresented: $showHowItWorks) {
            HowItWorksSheetView()
        }
        .alert(
            FreeExploreCopy.leaveTitle,
            isPresented: $showLeaveConfirm
        ) {
            Button(FreeExploreCopy.leaveConfirm, role: .destructive) {
                model.teardown()
                appState = .home
            }
            Button(GuidedCopy.cancel, role: .cancel) {
                showLeaveConfirm = false
            }
        } message: {
            Text(FreeExploreCopy.leaveMessage)
        }
    }

    @ViewBuilder
    private var content: some View {
        if model.phase == .carrying && !hasPlacedOnce {
            MascotPromptView(
                mascot: MascotAsset.neutral,
                text: FreeExploreCopy.placePrompt,
                mascotHeight: 120
            )
            .padding(.top, 12)
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private var footer: some View {
        Group {
            if model.phase == .carrying {
                if model.isAssetReady {
                    HintCapsule(text: FreeExploreCopy.tapHint)
                        .allowsHitTesting(false)
                }
            } else if model.isAnnotationVisible {
                if showAnnotationHint {
                    HintCapsule(text: FreeExploreCopy.annotationHint, systemImage: "hand.tap.fill")
                        .allowsHitTesting(false)
                }
            } else {
                CapsuleActionButton(title: FreeExploreCopy.reposition) {
                    showAnnotationHint = false
                    model.dismissFeedbackRobot()
                    model.placeAgain()
                }
            }
        }
        .padding(.bottom, 32)
        .transition(.opacity)
    }

    private var currentFeedback: FeedbackPresentation? {
        guard model.phase == .placed, let pulse = model.lastPulse else { return nil }

        if model.surfaceReading?.materialCategory == .soft {
            return FeedbackPresentation.soft(report: pulse)
        }

        let lesson: GuidedLesson = pulse.isBounceBack ? .bounceBack : .bounceAway
        return FeedbackPresentation(lesson: lesson, report: pulse)
    }

    private func scheduleAnnotation() {
        Task {
            let waveStart = ContinuousClock.now

            try? await Task.sleep(for: GuidedTiming.annotationDelay)
            guard model.phase == .placed, !model.isFeedbackRobotVisible else { return }
            model.showAnnotation()

            let remaining = GuidedTiming.annotationHintDelay - (ContinuousClock.now - waveStart)
            if remaining > .zero {
                try? await Task.sleep(for: remaining)
            }
            guard model.phase == .placed, model.isAnnotationVisible else { return }
            showAnnotationHint = true
        }
    }

    private func revealRobot() {
        showAnnotationHint = false
        guard let presentation = currentFeedback else { return }
        model.presentFeedbackRobot(presentation)
    }
}

enum FreeExploreCopy {
    static let placePrompt = "Place your sensor to begin exploring."
    static let tapHint = "Tap anywhere to place"
    static let annotationHint = "Tap the ? to see what happened"
    static let reposition = "Reposition Sensor"
    static let leaveTitle = "Back to Menu?"
    static let leaveMessage = "Do you want to stop exploring and go back home?"
    static let leaveConfirm = "Go Home"
}
