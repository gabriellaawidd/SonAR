import Foundation
import simd

enum PlacementSolver {
    static let previewDistance: Float = 0.20
    static let boardRoll: Float = .pi / 2

    static func previewPosition(
        cameraTransform: simd_float4x4,
        distance: Float = previewDistance
    ) -> SIMD3<Float> {
        let origin = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )
        let forward = -SIMD3<Float>(
            cameraTransform.columns.2.x,
            cameraTransform.columns.2.y,
            cameraTransform.columns.2.z
        )
        return origin + normalize(forward) * distance
    }

    static func previewOrientation(cameraTransform: simd_float4x4) -> simd_quatf {
        let cameraRotation = simd_quatf(simd_float3x3(
            SIMD3<Float>(cameraTransform.columns.0.x, cameraTransform.columns.0.y, cameraTransform.columns.0.z),
            SIMD3<Float>(cameraTransform.columns.1.x, cameraTransform.columns.1.y, cameraTransform.columns.1.z),
            SIMD3<Float>(cameraTransform.columns.2.x, cameraTransform.columns.2.y, cameraTransform.columns.2.z)
        ))

        return cameraRotation * simd_quatf(
            angle: boardRoll,
            axis: SIMD3<Float>(0, 0, 1)
        )
    }

    static func lerpFactor(deltaTime: Float, smoothing: Float = 0.0008) -> Float {
        1 - pow(smoothing, max(deltaTime, 0.0001))
    }

    static func facingDirection(of orientation: simd_quatf) -> SIMD3<Float> {
        orientation.act(SIMD3<Float>(0, 0, -1))
    }

    enum Settle {
        static let launchBackset: Float = 0.028
        static let launchScale: Float = 1.10
        static let launchTilt: Float = 0.10
        static let overshoot: Float = 0.012
        static let overshootScale: Float = 0.965
        static let launchDuration: TimeInterval = 0.20
        static let settleDuration: TimeInterval = 0.18
    }
}
