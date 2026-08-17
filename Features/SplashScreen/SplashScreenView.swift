//
//  SplashScreenView.swift
//  SonAR
//
//  Created by Gabriella Angelina Widjaja on 17/08/26.
//

import SwiftUI

struct SplashScreenView: View {
    @Binding var appState: AppState

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

            VStack(spacing: 16) {
                Spacer()

                Image("mascot2")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 280)

                HStack(spacing: 2) {
                    Text("Son")
                        .foregroundStyle(sonGradient)
                    Text("AR")
                        .foregroundStyle(arGradient)
                }
                .font(.system(size: 72, weight: .black, design: .rounded))

                Text("Learn how a robot sees with\nultrasonic wave")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.black.opacity(0.8))

                Spacer()

                Text("Generative AI is used for the assets")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.black.opacity(0.4))
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                    appState = .home
                }
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appState = .home
            }
        }
    }
}

#Preview {
    SplashScreenView(appState: .constant(.splash))
}
