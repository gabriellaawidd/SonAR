import SwiftUI

final class ARSessionModel: Observable {
    var phase: AppPhase = .carrying
    var isAssetReady = false
    var surfaceReading: SurfaceReading?
    var isLowLight = false

    weak var controller: ARSceneController?

    var raycastProvider: SurfaceRaycastProviding? {
        controller
    }

    func placeAgain() {
        controller?.restartCarrying()
    }
}
