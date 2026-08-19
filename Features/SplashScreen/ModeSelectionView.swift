//
//  ModeSelectionView.swift
//  SonAR
//
//  Created by Gabriella Angelina Widjaja on 17/08/26.
//

import SwiftUI

struct ModeSelectionView: View {
    @Binding var appState: AppState
    var mascotNamespace: Namespace.ID
    @Binding var isGuidedIntro: Bool

    private let sonGradient = LinearGradient(
        colors: [Color("sonGrad1"), Color("sonGrad2"), Color("sonGrad3")],
        startPoint: .leading,
        endPoint: .trailing
    )

    private let arGradient = LinearGradient(
        colors: [Color("arGrad1"), Color("arGrad2"), Color("arGrad3")],
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        NavigationStack {
            ZStack {
                Color("bgMain").ignoresSafeArea()

                VStack {
                    HStack {
                        Image("cloudTop")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120)
                            .padding(.top, 40)
                            .padding(.leading, -20)
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        Image("cloudBottom")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140)
                            .padding(.trailing, -30)
                    }
                }

                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    Image("mascotHome")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 260)
                        .offset(y: 28)
                        .zIndex(1)
                        .matchedGeometryEffect(id: "mascotHero", in: mascotNamespace)

                    VStack(spacing: 4) {
                        ZStack(alignment: .center) {
                            HStack(spacing: 2) {
                                Text("Son")
                                Text("AR")
                            }
                            .font(.system(size: 72, weight: .black, design: .rounded))
                            .foregroundStyle(Color("bgMain"))
                            .shadow(color: .white, radius: 1, x: -1.5, y: -1.5)
                            .shadow(color: .white, radius: 1, x: 1.5, y: -1.5)
                            .shadow(color: .white, radius: 1, x: -1.5, y: 1.5)
                            .shadow(color: .white, radius: 1, x: 1.5, y: 1.5)

                            HStack(spacing: 2) {
                                Text("Son")
                                    .foregroundStyle(sonGradient)
                                Text("AR")
                                    .foregroundStyle(arGradient)
                            }
                            .font(.system(size: 72, weight: .black, design: .rounded))
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                        }
                        Text("Learn how a robot sees with\nultrasonic wave")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.black.opacity(0.75))
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)

                        Button {
                            isGuidedIntro = true
                            appState = .sensorIntro
                        } label: {
                            HStack(spacing: 12) {
                                Image("quickTour")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 60)
                                
                                VStack (alignment: .leading) {
                                    Text("Guided tour")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color("buttonCyan"))
                                    
                                    Text("Learn key concepts step-by-step")
                                        .font(.caption)
                                        .multilineTextAlignment(.leading)
                                        .foregroundStyle(Color.black)
                                }
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 20)
                            .background(
                                Capsule()
                                    .stroke(Color("buttonCyan"), lineWidth: 2)
                                    .background(Capsule().fill(.white))
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 8)

                        Button {
                            isGuidedIntro = false
                            appState = .sensorIntro
                        } label: {
                            HStack(spacing: 12) {
                                Image("freeExplore")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 60)
                             
                                VStack (alignment: .leading){
                                    Text("Free Exploration")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color("buttonModeText"))
                                    
                                    Text("Express your curiosity")
                                        .font(.caption)
                                        .multilineTextAlignment(.leading)
                                        .foregroundStyle(Color.black)
                                }
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 20)
                            .background(
                                Capsule()
                                    .stroke(Color("buttonModeText"), lineWidth: 2)
                                    .background(Capsule().fill(.white))
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 28)
                    }
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
                    )
                    .padding(.horizontal, 20)

                    Spacer(minLength: 0)
                }
            }
        }
    }
}

#Preview {
    PreviewWrapper()
}

private struct PreviewWrapper: View {
    @Namespace private var ns
    @State private var isGuided = true
    var body: some View {
        ModeSelectionView(appState: .constant(.home), mascotNamespace: ns, isGuidedIntro: $isGuided)
    }
}
