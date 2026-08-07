import Foundation
import RealityKit
import simd

struct PlacementAnimator {
    func settle(
        entity: Entity,
        anchor: AnchorEntity,
        position: SIMD3<Float>,
        orientation: simd_quatf,
        onSettle: @escaping () -> Void
    ) {
        typealias S = PlacementSolver.Settle

        let facing = PlacementSolver.facingDirection(of: orientation)
        let towardUser = -facing

        entity.position = position + towardUser * S.launchBackset
        entity.orientation = orientation * simd_quatf(
            angle: S.launchTilt,
            axis: SIMD3<Float>(1, 0, 0)
        )
        entity.scale = SIMD3<Float>(repeating: S.launchScale)

        var overshoot = Transform()
        overshoot.translation = position + facing * S.overshoot
        overshoot.rotation = orientation
        overshoot.scale = SIMD3<Float>(repeating: S.overshootScale)
        entity.move(
            to: overshoot,
            relativeTo: anchor,
            duration: S.launchDuration,
            timingFunction: .easeOut
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + S.launchDuration) {
            guard entity.parent != nil else { return }

            var settled = Transform()
            settled.translation = position
            settled.rotation = orientation
            settled.scale = SIMD3<Float>(repeating: 1.0)
            entity.move(
                to: settled,
                relativeTo: anchor,
                duration: S.settleDuration,
                timingFunction: .easeInOut
            )
            onSettle()
        }
    }
}
