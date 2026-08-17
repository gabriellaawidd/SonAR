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
    
    var body: some View {
        Group {
            switch currentAppState {
            case .splash:
                SplashScreenView(appState: $currentAppState)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))

            case .home:
                ModeSelectionView(appState: $currentAppState)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .scale(scale: 0.92).combined(with: .opacity)
                    ))

            case .sensorIntro:
                SensorIntroView(appState: $currentAppState)
                    .transition(.scale(scale: 1.1).combined(with: .opacity))

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
