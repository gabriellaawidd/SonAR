//
//  TransparentRealityView.swift
//  SonAR
//
//  Created by Gabriella Angelina Widjaja on 17/08/26.
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
        camera.position = [0, 0, 0.4]
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
        var modelEntity: Entity?
        
        var angleX: Float = 0.0
        var angleY: Float = 0.0
        
        var displayLink: CADisplayLink?
        var velocity: CGPoint = .zero
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view as? ARView,
                  let model = modelEntity else { return }
            
            if gesture.state == .began {
                displayLink?.invalidate()
                displayLink = nil
                velocity = .zero
                
            } else if gesture.state == .changed {
                let translation = gesture.translation(in: view)
                
                angleY += Float(translation.x) * 0.01
                angleX += Float(translation.y) * 0.01
                applyRotation(to: model)
                
                gesture.setTranslation(.zero, in: view)
                
            } else if gesture.state == .ended || gesture.state == .cancelled {
                let gestureVelocity = gesture.velocity(in: view)
                
                velocity = CGPoint(x: gestureVelocity.x * 0.0002, y: gestureVelocity.y * 0.0002)
                
                displayLink = CADisplayLink(target: self, selector: #selector(applyMomentum))
                displayLink?.add(to: .main, forMode: .common)
            }
        }
        
        @objc func applyMomentum() {
            guard let model = modelEntity else { return }
            
            angleY += Float(velocity.x)
            angleX += Float(velocity.y)
            applyRotation(to: model)
            
            velocity.x *= 0.92
            velocity.y *= 0.92
            
            if abs(velocity.x) < 0.001 && abs(velocity.y) < 0.001 {
                displayLink?.invalidate()
                displayLink = nil
            }
        }
        
        func applyRotation(to model: Entity) {
            let rotationY = simd_quatf(angle: angleY, axis: [0, 1, 0])
            let rotationX = simd_quatf(angle: angleX, axis: [1, 0, 0])
            model.transform.rotation = rotationY * rotationX
        }
    }
}
