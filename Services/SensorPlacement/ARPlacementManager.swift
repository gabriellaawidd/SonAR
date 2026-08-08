import RealityKit
import simd
import UIKit

final class ARPlacementManager {
    private var anchors: [AnchorEntity] = []
    private let animator = PlacementAnimator()
    private let settleFeedback = UIImpactFeedbackGenerator(style: .soft)

    init() {
        settleFeedback.prepare()
    }

    func place(
        in arView: ARView,
        position: SIMD3<Float>,
        orientation: simd_quatf,
        onSettled: ((AnchorEntity, Entity) -> Void)? = nil
    ) {
        SensorAsset.load { [weak self, weak arView] entity in
            guard let self, let entity, let arView else { return }

            let anchor = AnchorEntity(world: matrix_identity_float4x4)
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)
            self.anchors.append(anchor)

            self.animator.settle(
                entity: entity,
                anchor: anchor,
                position: position,
                orientation: orientation
            ) { [weak self] in
                self?.settleFeedback.impactOccurred(intensity: 0.7)
                onSettled?(anchor, entity)
            }
        }
    }

    func removeAll() {
        anchors.forEach { $0.removeFromParent() }
        anchors.removeAll()
    }
}
