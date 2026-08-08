import ARKit
import RealityKit
import simd
import UIKit
import CoreVideo

final class ARSceneController: NSObject, ARSessionDelegate {
    private let model: ARSessionModel
    private weak var arView: ARView?

    private let previewManager = ARPreviewManager()
    private let placementManager = ARPlacementManager()
    private let raycastManager = ARRaycastManager()
    private let tapFeedback = UIImpactFeedbackGenerator(style: .light)

    private var materialDetectionManager: MaterialDetectionManager?

    private var lastFrameTime: TimeInterval?
    private var waveTask: Task<Void, Never>?

    init(model: ARSessionModel) {
        self.model = model
        super.init()
        tapFeedback.prepare()

        materialDetectionManager = MaterialDetectionManager(raycastProvider: self)
        materialDetectionManager?.onReadingReady = { lock, reading in
        
        }
    }

    func attach(to arView: ARView) {
        self.arView = arView
        raycastManager.attach(to: arView)
        arView.session.delegate = self

        guard ARSessionConfigurator.run(on: arView) else { return }

        arView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handleTap))
        )
        beginCarrying()
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard model.phase == .carrying else { return }

        raycastManager.update(frame: frame)
        previewManager.update(
            frame: frame,
            deltaTime: deltaTime(from: frame.timestamp)
        )
    }

    func beginCarrying() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.beginCarrying()
            }
            return
        }
        guard let arView else { return }

        previewManager.reset()
        raycastManager.clear()
        lastFrameTime = nil
        model.phase = .carrying
        model.isAssetReady = false

        previewManager.prepare(in: arView) { [weak self] isReady in
            self?.model.isAssetReady = isReady
        }
    }

    func restartCarrying() {
        guard model.phase == .placed else { return }
        waveTask?.cancel()
        waveTask = nil
        placementManager.removeAll()
        beginCarrying()
    }

    private func deltaTime(from timestamp: TimeInterval) -> Float {
        defer { lastFrameTime = timestamp }
        guard let lastFrameTime else { return 1.0 / 60.0 }
        return Float(min(max(timestamp - lastFrameTime, 0.0001), 0.1))
    }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard model.phase == .carrying else { return }
        guard
            let arView,
            let position = previewManager.currentPosition,
            let orientation = previewManager.currentOrientation
        else { return }
        
        let pixelBuffer = arView.session.currentFrame?.capturedImage

        let lock = raycastManager.createLock(
            position: position,
            orientation: orientation,
            pixelBuffer: pixelBuffer
            )
        tapFeedback.impactOccurred()
        previewManager.dismiss()
        model.isAssetReady = false

        placementManager.place(
            in: arView,
            position: position,
            orientation: orientation
        ) { [weak self] anchor, sensor in
            guard let self else { return }
            self.waveTask = Wave.startLoop(
                sensor: sensor,
                anchor: anchor,
                lockID: lock.id,
                refreshHit: { [weak self] id in self?.raycastManager.refreshLock(id: id) }
            )
        }
        model.phase = .placed
    }
}

extension ARSceneController: SurfaceRaycastProviding {
    func currentHit() -> RaycastHit? {
        raycastManager.latestHit
    }

    var onHitUpdate: ((RaycastHit) -> Void)? {
        get { raycastManager.onHitUpdate }
        set { raycastManager.onHitUpdate = newValue }
    }

    var locks: [PlacementLock] {
        raycastManager.locks
    }

    var latestLock: PlacementLock? {
        raycastManager.locks.last
    }

    var onLockCreated: ((PlacementLock, CVPixelBuffer?) -> Void)? {
        get { raycastManager.onLockCreated }
        set { raycastManager.onLockCreated = newValue }
    }

    @discardableResult
    func refreshLock(id: UUID) -> RaycastHit? {
        raycastManager.refreshLock(id: id)
    }
}
