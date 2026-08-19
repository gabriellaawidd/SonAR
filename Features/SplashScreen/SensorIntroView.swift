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
    var mascotNamespace: Namespace.ID
    var onBack: () -> Void

    @State private var mascotState: MascotAnimState = .normal
    @State private var showSensor: Bool = false
    @State private var showButton: Bool = false
    @State private var isWiggling: Bool = false

    enum MascotAnimState {
        case normal
        case movingDownAndGrowing
    }

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
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(.black.opacity(0.35)))
                    }
                    .padding(.leading, 16)
                    .padding(.top, 8)
                    Spacer()
                }

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
                .padding(.top, 12)

                Spacer()

                ZStack {
                    if showSensor {
                        TransparentRealityView(sceneName: "Sensor_Ultrasonik_3D")
                            .frame(height: 180)
                            .rotationEffect(.degrees(isWiggling ? 10 : -10))
                            .scaleEffect(isWiggling ? 1.04 : 1.0)
                            .transition(.opacity)
                    }
                }
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
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 20)
            }
            Image("mascotHome")
                .resizable()
                .scaledToFit()
                .frame(height: 180)
                .scaleEffect(mascotState == .movingDownAndGrowing ? 3.0 : 1.0, anchor: .bottom)
                .offset(y: mascotState == .movingDownAndGrowing ? 320 : 0)
                .opacity(showSensor ? 0 : 1)
                .matchedGeometryEffect(id: "mascotHero", in: mascotNamespace)
        }
        .tint(.white)
        .task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            withAnimation(.spring(response: 1, dampingFraction: 0.85, blendDuration: 0)) {
                mascotState = .movingDownAndGrowing
            }

            try? await Task.sleep(nanoseconds: 800_000_000)
            withAnimation(.easeInOut(duration: 0.7)) {
                showSensor = true
            }

            withAnimation(.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true).delay(0.2)) {
                isWiggling = true
            }

            try? await Task.sleep(nanoseconds: 400_000_000)
            withAnimation(.easeInOut(duration: 0.6)) {
                showButton = true
            }
        }
    }
}

#Preview {
    PreviewWrapper()
}

private struct PreviewWrapper: View {
    @Namespace private var ns
    var body: some View {
        SensorIntroView(isGuided: true, appState: .constant(.home), mascotNamespace: ns, onBack: {})
    }
}
