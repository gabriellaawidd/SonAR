import ARKit
import RealityKit
import simd
import CoreVideo

final class ARRaycastManager {
    private weak var arView: ARView?
    private(set) var latestHit: RaycastHit?
    private(set) var locks: [PlacementLock] = []
    private(set) var latestFrameTimestamp: TimeInterval = 0

    var onHitUpdate: ((RaycastHit) -> Void)?
    var onLockCreated: ((PlacementLock, CVPixelBuffer?) -> Void)?

    func attach(to arView: ARView) {
        self.arView = arView
    }

    func update(frame: ARFrame) {
        latestFrameTimestamp = frame.timestamp
        guard let arView else { return }

        let center = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
        guard center.x > 0, center.y > 0 else { return }

        guard let result = arView.raycast(
            from: center,
            allowing: .estimatedPlane,
            alignment: .any
        ).first else {
            latestHit = nil
            return
        }

        let worldPosition = Self.position(from: result.worldTransform)
        let normal = Self.normal(from: result.worldTransform)
        let cameraPosition = Self.position(from: frame.camera.transform)

        let hit = RaycastHit(
            worldPosition: worldPosition,
            normal: normal,
            distance: simd_distance(cameraPosition, worldPosition),
            screenPoint: center,
            timestamp: frame.timestamp,
            pixelBuffer: frame.capturedImage
        )

        latestHit = hit
        onHitUpdate?(hit)
    }

    func createLock(
        position: SIMD3<Float>,
        orientation: simd_quatf,
        pixelBuffer: CVPixelBuffer?
    ) -> PlacementLock {
        let lock = PlacementLock(
            id: UUID(),
            sensorPosition: position,
            sensorOrientation: orientation,
            facingDirection: PlacementSolver.facingDirection(of: orientation),
            hit: latestHit,
            timestamp: latestFrameTimestamp
        )
        locks.append(lock)
        onLockCreated?(lock, pixelBuffer)
        return lock
    }

    func clear() {
        latestHit = nil
        locks.removeAll()
    }

    @discardableResult
    func refreshLock(id: UUID, directions: [SIMD3<Float>]) -> [RaycastHit?] {
        guard let index = locks.firstIndex(where: { $0.id == id }) else { return [] }
        let lock = locks[index]

        let hits = directions.map { direction in
            worldRaycast(origin: lock.sensorPosition, direction: direction)
        }

        // Keep the central hit as the primary hit for the lock state
        locks[index] = PlacementLock(
            id: lock.id,
            sensorPosition: lock.sensorPosition,
            sensorOrientation: lock.sensorOrientation,
            facingDirection: lock.facingDirection,
            hit: hits.first ?? nil,
            timestamp: lock.timestamp
        )
        return hits
    }

    private func worldRaycast(
        origin: SIMD3<Float>,
        direction: SIMD3<Float>
    ) -> RaycastHit? {
        guard let session = arView?.session else { return nil }

        let query = ARRaycastQuery(
            origin: origin,
            direction: simd_normalize(direction),
            allowing: .estimatedPlane,
            alignment: .any
        )
        guard let result = session.raycast(query).first else { return nil }

        let worldPosition = Self.position(from: result.worldTransform)
        return RaycastHit(
            worldPosition: worldPosition,
            normal: Self.normal(from: result.worldTransform),
            distance: simd_distance(origin, worldPosition),
            screenPoint: nil,
            timestamp: latestFrameTimestamp,
            pixelBuffer: session.currentFrame?.capturedImage
        )
    }

    private static func position(from transform: simd_float4x4) -> SIMD3<Float> {
        SIMD3<Float>(
            transform.columns.3.x,
            transform.columns.3.y,
            transform.columns.3.z
        )
    }

    private static func normal(from transform: simd_float4x4) -> SIMD3<Float> {
        simd_normalize(SIMD3<Float>(
            transform.columns.1.x,
            transform.columns.1.y,
            transform.columns.1.z
        ))
    }
}
