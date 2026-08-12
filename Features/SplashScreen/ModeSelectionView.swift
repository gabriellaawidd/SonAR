//
//  ModeSelectionView.swift
//  SonAR
//
//  Created by Gabriella Angelina Widjaja on 10/08/26.
//

import SwiftUI

struct ModeSelectionView: View {
    @Binding var appState: AppState
    
    var body: some View {
        ZStack {
            Color("bgMain").ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image("mascot2")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)
                    .padding(.top, 40)
                
                VStack(spacing: 8) {
                    Text("See Sound in AR")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(Color.black)
                    
                    Text("Sends a tiny sound and\nlistens for the bounce")
                        .font(.body)
                        .foregroundColor(Color.black)
                        .multilineTextAlignment(.center)
                }
                
                VStack {
                    MenuCardView(
                        title: "Quick tour",
                        subtitle: "A quick guide to get\nyou started",
                        iconName: "quickTour",
                        accentColor: Color("buttonModeText"),
                        action: { appState = .guidedWalkthrough }
                    )
                    
                    MenuCardView(
                        title: "Let me explore",
                        subtitle: "I know how it works!",
                        iconName: "freeExplore",
                        accentColor: Color("buttonModeText"),
                        action: { appState = .freeExplore }
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
            }
        }
        .gesture(
            DragGesture().onEnded { value in
                if value.translation.width > 50 {
                    appState = .sensorIntro
                }
            }
        )
    }
}

#Preview {
    ModeSelectionView(appState: .constant(.modeSelection))
}
