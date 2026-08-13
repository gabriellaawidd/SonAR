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
    var isAnnotationVisible = false

    @ObservationIgnored var onAnnotationTapped: (() -> Void)?

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

    func annotationTapped() {
        onAnnotationTapped?()
    }

    func showAnnotation() {
        controller?.showAnnotation()
    }

    func hideAnnotation() {
        controller?.hideAnnotation()
    }

    func dismissFeedbackRobot() {
        isFeedbackRobotVisible = false
        controller?.dismissFeedbackRobot()
    }
}
