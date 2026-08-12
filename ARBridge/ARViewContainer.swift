import RealityKit
import SwiftUI

struct ARViewContainer: UIViewRepresentable {
    var model: ARSessionModel

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(
            frame: .zero,
            cameraMode: .ar,
            automaticallyConfigureSession: false
        )

        context.coordinator.attach(to: arView)
        model.controller = context.coordinator
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> ARSceneController {
        ARSceneController(model: model)
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: ARSceneController) {
        coordinator.teardown()
    }
}
