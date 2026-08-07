import ARKit
import RealityKit

enum ARSessionConfigurator {
    static func run(on arView: ARView) -> Bool {
        guard ARWorldTrackingConfiguration.isSupported else {
            print("[ARSession] Perangkat tidak mendukung world tracking.")
            return false
        }

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]

        let supportsMesh = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
        if supportsMesh {
            configuration.sceneReconstruction = .mesh
            arView.environment.sceneUnderstanding.options.insert(.occlusion)
        }

        if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
            configuration.frameSemantics.insert(.smoothedSceneDepth)
        } else if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }

        arView.session.run(
            configuration,
            options: [.resetTracking, .removeExistingAnchors]
        )
        return true
    }
}
