//
//  GuidedWalkthroughView.swift
//  SonAR
//
//  Created by Tiffany Michelle on 12/08/26.
//

import SwiftUI

struct GuidedWalkthroughView: View {
    @Binding var appState: AppState

    @State private var model = ARSessionModel()
    @State private var flow = GuidedWalkthroughViewModel()
    @State private var showHowItWorks = false
    @State private var showLeaveConfirm = false

    var body: some View {
        ZStack {
            ARViewContainer(model: model)
                .ignoresSafeArea()

            GuidedOverlayView(
                step: flow.step,
                onHome: { showLeaveConfirm = true },
                onHowItWorks: { showHowItWorks = true },
                onBriefingContinue: { flow.briefingContinueTapped() },
                onContinue: { flow.continueTapped() },
                onRetry: { flow.retryTapped() },
                onFinish: {
                    flow.tearDown()
                    appState = .freeExplore
                }
            )
        }
        .task { flow.bind(to: model) }
        .onChange(of: model.phase) { _, newPhase in
            flow.handle(phase: newPhase)
        }
        .onDisappear {
            flow.tearDown()
            model.teardown()
        }
        .sheet(isPresented: $showHowItWorks) {
            HowItWorksSheetView()
                .presentationDetents([.fraction(0.85), .large])
                .presentationDragIndicator(.visible)
        }
        .alert(
            GuidedCopy.leaveTitle,
            isPresented: $showLeaveConfirm
        ) {
            Button(GuidedCopy.leaveConfirm, role: .destructive) {
                flow.homeTapped { appState = .home }
            }
            Button(GuidedCopy.cancel, role: .cancel) {
                showLeaveConfirm = false
            }
        } message: {
            Text(GuidedCopy.leaveMessage)
        }

    }
}
