import SwiftUI

final class ARSessionModel: ObservableObject {
    @Published var phase: AppPhase = .carrying
    @Published var isAssetReady = false

    weak var controller: ARSceneController?

    var raycastProvider: SurfaceRaycastProviding? {
        controller
    }

    func placeAgain() {
        controller?.restartCarrying()
    }
}
