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

    var body: some View {
        ZStack {
            ARViewContainer(model: model)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                NavBarView(
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
        .onChange(of: model.phase) { _, newPhase in
            if newPhase == .placed {
                scheduleRobot()
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
                appState = .modeSelection
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
        if model.phase == .carrying {
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
            } else {
                CapsuleActionButton(title: FreeExploreCopy.reposition) {
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
        let lesson: GuidedLesson
        if model.surfaceReading?.materialCategory == .soft {
            lesson = .absorbed
        } else if pulse.isBounceBack {
            lesson = .bounceBack
        } else {
            lesson = .bounceAway
        }
        return FeedbackPresentation(lesson: lesson, report: pulse)
    }

    private func scheduleRobot() {
        Task {
            try? await Task.sleep(for: GuidedTiming.robotDelay)
            guard model.phase == .placed, let presentation = currentFeedback else { return }
            model.presentFeedbackRobot(presentation)
        }
    }
}

enum FreeExploreCopy {
    static let placePrompt = "Place your sensor to begin exploring."
    static let tapHint = "Tap anywhere to place"
    static let reposition = "Reposition Sensor"
    static let leaveTitle = "Back to Menu?"
    static let leaveMessage = "Do you want to stop exploring and go back home?"
    static let leaveConfirm = "Go Home"
}
