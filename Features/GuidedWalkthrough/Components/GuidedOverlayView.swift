//
//  GuidedOverlayView.swift
//  SonAR
//
//  Created by Tiffany Michelle on 12/08/26.
//

import SwiftUI

struct GuidedOverlayView: View {
    let step: GuidedStep

    let onHome: () -> Void
    let onHowItWorks: () -> Void
    let onBriefingContinue: () -> Void
    let onContinue: () -> Void
    let onRetry: () -> Void
    let onFinish: () -> Void

    @State private var showBriefingButton = false

    private var isBriefing: Bool {
        if case .briefing = step { return true }
        return false
    }

    var body: some View {
        ZStack {
            if isBriefing {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            VStack(spacing: 0) {
                ToolBarView(onHome: onHome, onHowItWorks: onHowItWorks)

                stepContent
                    .allowsHitTesting(false)

                Spacer(minLength: 0)

                footer
            }
            .padding(.horizontal, 20)
        }
        .animation(.easeInOut(duration: 0.28), value: step)
        .animation(.easeInOut(duration: 0.25), value: showBriefingButton)
        .task(id: step) {
            showBriefingButton = false
            guard isBriefing else { return }
            try? await Task.sleep(for: GuidedTiming.briefingButtonDelay)
            guard !Task.isCancelled else { return }
            showBriefingButton = true
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .briefing(let prompt):
            MascotPromptView(
                mascot: prompt.mascot,
                text: prompt.bubbleText,
                mascotHeight: prompt.mascotHeight
            )
            .padding(.top, 40)
            .transition(.opacity.combined(with: .move(edge: .top)))

        case .placePrompt(let prompt):
            if !prompt.needsBriefing {
                MascotPromptView(
                    mascot: prompt.mascot,
                    text: prompt.bubbleText,
                    mascotHeight: prompt.mascotHeight
                )
                .padding(.top, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

        case .retry(let reason):
            MascotPromptView(
                mascot: reason.mascot,
                text: reason.bubbleText,
                mascotHeight: reason.mascotHeight
            )
            .padding(.top, 12)
            .transition(.opacity)

        case .feedback:
            EmptyView()

        case .finale:
            MascotPromptView(
                mascot: MascotAsset.neutral,
                text: GuidedCopy.finale,
                mascotHeight: 120
            )
            .padding(.top, 12)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    @ViewBuilder
    private var footer: some View {
        Group {
            switch step {
            case .briefing:
                if showBriefingButton {
                    CapsuleActionButton(
                        title: GuidedCopy.briefingContinue,
                        action: onBriefingContinue
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }

            case .placePrompt(let prompt):
                HintCapsule(text: prompt.footerHint)
                    .allowsHitTesting(false)

            case .retry(let reason):
                CapsuleActionButton(title: reason.actionTitle, action: onRetry)

            case .feedback:
                CapsuleActionButton(title: GuidedCopy.continueTitle, action: onContinue)

            case .finale:
                CapsuleActionButton(title: GuidedCopy.exploreTitle, action: onFinish)
            }
        }
        .padding(.bottom, 32)
        .transition(.opacity)
    }
}
