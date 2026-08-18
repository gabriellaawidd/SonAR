//
//  ContentView.swift
//  SonAR
//
//  Created by Gabriella Angelina Widjaja on 17/08/26.
//

import SwiftUI

enum AppState {
    case splash
    case home
    case sensorIntro
    case guidedWalkthrough
    case freeExplore
}

struct ContentView: View {
    @State private var currentAppState: AppState = .splash
    @State private var isGuidedIntro: Bool = true

    @Namespace private var mascotNamespace

    var body: some View {
        Group {
            switch currentAppState {
            case .splash:
                SplashScreenView(appState: $currentAppState)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))

            case .home:
                ModeSelectionView(
                    appState: $currentAppState,
                    mascotNamespace: mascotNamespace,
                    isGuidedIntro: $isGuidedIntro
                )
                .transition(.opacity)


            case .sensorIntro:
                SensorIntroView(
                    isGuided: isGuidedIntro,
                    appState: $currentAppState,
                    mascotNamespace: mascotNamespace,
                    onBack: { currentAppState = .home }
                )
                .transition(.opacity)

            case .guidedWalkthrough:
                GuidedWalkthroughView(appState: $currentAppState)
                    .transition(.opacity)

            case .freeExplore:
                FreeExploreView(appState: $currentAppState)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.65, dampingFraction: 0.8), value: currentAppState)
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
