import ARKit
import RealityKit
import simd
import UIKit

final class ARPreviewManager {
    private var anchor: AnchorEntity?
    private var sensor: Entity?
    private var smoothPosition: SIMD3<Float>?
    private var smoothOrientation: simd_quatf?
    private var loadGeneration = 0

    private let opacity: CGFloat = 0.35

    var currentPosition: SIMD3<Float>? { smoothPosition }
    var currentOrientation: simd_quatf? { smoothOrientation }

    func prepare(in arView: ARView, completion: @escaping (Bool) -> Void) {
        reset()
        loadGeneration += 1
        let generation = loadGeneration

        SensorAsset.load { [weak self, weak arView] entity in
            guard let self, generation == self.loadGeneration else { return }
            guard let entity, let arView else {
                completion(false)
                return
            }

            let anchor = AnchorEntity(world: matrix_identity_float4x4)
            SensorAsset.applyPreviewTint(entity, color: .systemTeal, alpha: self.opacity)
            entity.isEnabled = false
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)

            self.anchor = anchor
            self.sensor = entity
            completion(true)
        }
    }

    func update(frame: ARFrame, deltaTime: Float) {
        guard let sensor else { return }

        let targetPosition = PlacementSolver.previewPosition(
            cameraTransform: frame.camera.transform
        )
        let targetOrientation = PlacementSolver.previewOrientation(
            cameraTransform: frame.camera.transform
        )

        if smoothPosition == nil {
            smoothPosition = targetPosition
            smoothOrientation = targetOrientation
        }

        let factor = PlacementSolver.lerpFactor(deltaTime: deltaTime)
        smoothPosition = simd_mix(
            smoothPosition!,
            targetPosition,
            SIMD3<Float>(repeating: factor)
        )
        smoothOrientation = simd_slerp(
            smoothOrientation!,
            targetOrientation,
            factor
        )

        sensor.isEnabled = true
        sensor.position = smoothPosition!
        sensor.orientation = smoothOrientation!
    }

    func dismiss(animated: Bool = true) {
        loadGeneration += 1
        guard let anchor, let sensor else {
            resetState()
            return
        }

        self.anchor = nil
        self.sensor = nil
        smoothPosition = nil
        smoothOrientation = nil

        guard animated else {
            anchor.removeFromParent()
            return
        }

        var shrunk = sensor.transform
        shrunk.scale = SIMD3<Float>(repeating: 0.7)
        sensor.move(
            to: shrunk,
            relativeTo: sensor.parent,
            duration: 0.14,
            timingFunction: .easeIn
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            anchor.removeFromParent()
        }
    }

    func reset() {
        loadGeneration += 1
        anchor?.removeFromParent()
        resetState()
    }

    private func resetState() {
        anchor = nil
        sensor = nil
        smoothPosition = nil
        smoothOrientation = nil
    }
}
