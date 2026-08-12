import SwiftUI

@Observable
final class ARSessionModel {
    var phase: AppPhase = .carrying
    var isAssetReady = false
    var surfaceReading: SurfaceReading?
    var isLowLight = false
    var lastPulse: Wave.PulseReport?
    var isFeedbackRobotVisible = false
    var materialOverride: MaterialCategory?

    @ObservationIgnored weak var controller: ARSceneController?

    var raycastProvider: SurfaceRaycastProviding? {
        controller
    }

    var effectiveMaterial: MaterialCategory? {
        materialOverride ?? surfaceReading?.materialCategory
    }

    func placeAgain() {
        controller?.restartCarrying()
    }

    func teardown() {
        isFeedbackRobotVisible = false
        controller?.teardown()
    }

    func presentFeedbackRobot(_ presentation: FeedbackPresentation) {
        isFeedbackRobotVisible = true
        controller?.presentFeedbackRobot(presentation)
    }

    func dismissFeedbackRobot() {
        isFeedbackRobotVisible = false
        controller?.dismissFeedbackRobot()
    }
}
