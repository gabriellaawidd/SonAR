//
//  SensorIntroView.swift
//  SonAR
//
//  Created by Gabriella Angelina Widjaja on 17/08/26.
//

import SwiftUI

struct SensorIntroView: View {
    var isGuided: Bool = true
    
    @Binding var appState: AppState
    
    var body: some View {
        ZStack {
            CameraPreviewBackdrop()
                .ignoresSafeArea()
            LinearGradient(
                colors: [
                    Color.black.opacity(0.65),
                    Color.black.opacity(0.25),
                    Color.black.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("Meet Your\nRobot's Eyes")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                    Text("Your robot sees with this")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.top, 20)
                
                Spacer()
                
                VStack(spacing: 6) {
                    Image("rotate")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 140)
                        .foregroundStyle(.white.opacity(0.9))
                    VStack(spacing: 2) {
                        Text("360°")
                            .font(.system(size: 13, weight: .bold))
                        Text("Drag to Rotate")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(.white)
                }
                .padding(.bottom, 12)
               
                TransparentRealityView(sceneName: "Sensor_Ultrasonik_3D")
                    .frame(height: 240)
                Spacer()
              
                Button {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        appState = isGuided ? .guidedWalkthrough : .freeExplore
                    }
                } label: {
                    Text("Let's Start")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color("buttonCyan"), Color("sonGrad1")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color("buttonCyan").opacity(0.5), radius: 15, y: 6)
                        )
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 36)
            }
        }
        .tint(.white) 
    }
}
#Preview {
    NavigationStack {
        SensorIntroView(isGuided: true, appState: .constant(.home))
    }
}
