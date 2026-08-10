//
//  ContentView.swift
//  SonAR
//
//  Created by Gabriella Angelina Widjaja on 05/08/26.
//

import SwiftUI

enum AppState {
    case splash
    case sensorIntro
    case modeSelection
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
            case .sensorIntro:
                SensorIntroView(appState: $currentAppState)
            case .modeSelection:
                ModeSelectionView(appState: $currentAppState)
            case .guidedWalkthrough:
                Text("Guided Walkthrough Screen")
            case .freeExplore:
                Text("Free Explore Screen")
            }
        }
        .animation(.easeInOut, value: currentAppState)
    }
}

#Preview {
    ContentView()
}
