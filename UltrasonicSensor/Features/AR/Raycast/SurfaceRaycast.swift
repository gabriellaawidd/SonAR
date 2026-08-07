import Foundation
import simd

struct RaycastHit {
    let worldPosition: simd_float3
    let normal: simd_float3
    let distance: Float
    let screenPoint: CGPoint?
    let timestamp: TimeInterval

    func incidenceAngleDegrees(incoming direction: simd_float3) -> Float {
        let incoming = simd_normalize(direction)
        let surfaceNormal = simd_normalize(normal)
        let cosine = simd_clamp(simd_dot(-incoming, surfaceNormal), -1, 1)
        return acos(cosine) * 180 / .pi
    }
}

struct PlacementLock: Identifiable {
    let id: UUID
    let sensorPosition: simd_float3
    let sensorOrientation: simd_quatf
    let facingDirection: simd_float3
    let hit: RaycastHit?
    let timestamp: TimeInterval

    var incidenceAngleDegrees: Float? {
        hit?.incidenceAngleDegrees(incoming: facingDirection)
    }
}

protocol SurfaceRaycastProviding: AnyObject {
    func currentHit() -> RaycastHit?

    var onHitUpdate: ((RaycastHit) -> Void)? { get set }
    var locks: [PlacementLock] { get }
    var latestLock: PlacementLock? { get }
    var onLockCreated: ((PlacementLock) -> Void)? { get set }

    @discardableResult
    func refreshLock(id: UUID) -> RaycastHit?
}
