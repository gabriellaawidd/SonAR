//
//  SensorIntroView.swift
//  SonAR
//
//  Created by Gabriella Angelina Widjaja on 10/08/26.
//

import SwiftUI
import RealityKit

struct TransparentRealityView: UIViewRepresentable {
    var sceneName: String
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        arView.backgroundColor = .clear
        arView.environment.background = .color(.clear)
        
        let camera = PerspectiveCamera()
        let cameraAnchor = AnchorEntity(world: .zero)
        camera.position = [0, 0, 0.8]
        cameraAnchor.addChild(camera)
        arView.scene.addAnchor(cameraAnchor)
        
        let light = DirectionalLight()
        light.light.color = .white
        light.light.intensity = 1000
        light.look(at: [0,0,0], from: [1, 1, 1], relativeTo: nil)
        cameraAnchor.addChild(light)
        
        let cleanName = sceneName.replacingOccurrences(of: ".usdz", with: "")
        if let modelEntity = try? Entity.load(named: cleanName) {
            let modelAnchor = AnchorEntity(world: .zero)
            modelAnchor.addChild(modelEntity)
            arView.scene.addAnchor(modelAnchor)
            
            context.coordinator.modelEntity = modelEntity
        }
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePan(_:)))
        arView.addGestureRecognizer(panGesture)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var panStartX: Float = 0.0
        var currentAngleY: Float = 0.0
        var modelEntity: Entity?
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view as? ARView,
                  let model = modelEntity else { return }
            
            let translation = gesture.translation(in: view)
            
            if gesture.state == .began {
                panStartX = currentAngleY
            } else if gesture.state == .changed {
                currentAngleY = panStartX + Float(translation.x) * 0.01
                
                let rotation = simd_quatf(angle: currentAngleY, axis: [0, 1, 0])
                model.transform.rotation = rotation
            }
        }
    }
}

struct SensorIntroView: View {
    @Binding var appState: AppState
    
    var body: some View {
        NavigationStack {
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
                    
                    TransparentRealityView(sceneName: "Sensor_Ultrasonik_3D")
                        .frame(height: 250)
                    
                    Spacer()
                    
                    NavigationLink(destination: ModeSelectionView(appState: $appState)) {
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
}

#Preview {
    SensorIntroView(appState: .constant(.sensorIntro))
}
