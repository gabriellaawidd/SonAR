//
//  SensorIntroView.swift
//  SonAR
//
//  Created by Gabriella Angelina Widjaja on 10/08/26.
//

import SwiftUI
import SceneKit

struct TransparentSceneView: UIViewRepresentable {
    var sceneName: String
    
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = SCNScene(named: sceneName)
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.backgroundColor = UIColor.clear
        view.scene?.background.contents = UIColor.clear
        
        return view
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
    }
}

struct SensorIntroView: View {
    @Binding var appState: AppState
    
    var body: some View {
        ZStack {
            Color("bgMain").ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("Meet Your\nRobot's Eyes")
                        .font(.largeTitle)
                        .bold()
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                    
                    Text("Your robot sees with this")
                        .font(.body)
                        .foregroundColor(.black)
                }
                .padding(.top, 60)
                
                Spacer()
                
                VStack {
                    Image("rotate")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160)
                        .foregroundColor(Color("buttonCyan"))
                    
                    VStack(spacing: 2) {
                        Text("360°")
                            .font(.system(size: 14, weight: .bold))
                        Text("Drag to Rotate")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.black)
                }
     
                .padding(.bottom, 40)
                
                TransparentSceneView(sceneName: "Sensor_Ultrasonik_3D.usdz")
                    .frame(height: 250)
                
                Spacer()
                
                Button(action: {
                    appState = .modeSelection
                }) {
                    Text("Try it in AR")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .frame(width: 220)
                        .background(
                            Capsule()
                                .fill(Color("buttonCyan"))
                                .shadow(color: Color("buttonCyan").opacity(0.5), radius: 15, x: 0, y: 8)
                        )
                }
                .padding(.bottom, 60)
            }
        }
    }
}

#Preview {
    SensorIntroView(appState: .constant(.sensorIntro))
}
