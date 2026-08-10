import SwiftUI

final class ARSessionModel: ObservableObject {
    @Published var phase: AppPhase = .carrying
    @Published var isAssetReady = false
    @Published var surfaceReading: SurfaceReading?
    @Published var isLowLight = false

    weak var controller: ARSceneController?

    var raycastProvider: SurfaceRaycastProviding? {
        controller
    }

    func placeAgain() {
        controller?.restartCarrying()
    }
}
