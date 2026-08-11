//
//  SplashScreenView.swift
//  SonAR
//
//  Created by Gabriella Angelina Widjaja on 10/08/26.
//

import SwiftUI

struct SplashScreenView: View {
    @Binding var appState: AppState
    
    let sonGradient = LinearGradient(
        colors: [Color("sonGrad1"), Color("sonGrad2"), Color("sonGrad3")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    let arGradient = LinearGradient(
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
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image("cloudBottom")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140)
                        .padding(.trailing, -50)
                }
            }
            
            VStack(spacing: 20) {
                Image("mascotRobot")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                
                VStack(spacing: 4) {
                    HStack(spacing: 0) {
                        Text("Son")
                            .foregroundStyle(sonGradient)
                        Text("AR")
                            .foregroundStyle(arGradient)
                    }
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    
                    Text("Ultrasonic wave visualization")
                        .font(.headline)
                        .foregroundColor(.black) 
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                appState = .sensorIntro
            }
        }
    }
}

#Preview {
    SplashScreenView(appState: .constant(.splash))
}
