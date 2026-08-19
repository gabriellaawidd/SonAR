//
//  RobotFeedbackPresenter.swift
//  SonAR
//
//  Created by Tiffany Michelle on 12/08/26.
//

import ARKit
import RealityKit
import simd
import UIKit

enum RobotFeedbackLayout {

    static let robotHeight: Float = 0.24

    static let assumedNativeHeight: Float = 1.4423399

    static let distanceFromCamera: Float = 0.80

    static let lateralOffset: Float = 0.19

    static let verticalOffset: Float = 0.05

    static let pitchVerticalCompensation: Float = 0.10

    static let maxOnScreenAngleDegrees: Float = 20

    static let minDistanceFromCamera: Float = 0.28

    static let minDistanceScale: Float = 0.35

    static let clearanceFromSurface: Float = 0.10

    static let hintCardWidth: Float = 0.28

    static let hintCardLift: Float = 0.0

    static let billboardSmoothing: Float = 0.12

    static let cardAppearDuration: TimeInterval = 0.32

    static let bounceHeight: Float = 0.1
    static let bounceUpDuration: TimeInterval = 1.49
    static let bounceDownDuration: TimeInterval = 1.51

    static let facesPositiveZ = true
}

final class RobotFeedbackPresenter {

    private weak var arView: ARView?

    private var anchor: AnchorEntity?
    private var root: Entity?
    private var robot: Entity?
    private var hintCard: Entity?
    private var rootScale: Float = 1
    private var distanceScale: Float = 1
    private var loadGeneration = 0
    private var isPresenting = false

    private var hoverController: AnimationPlaybackController?
    private var bounceGeneration = 0

    var isVisible: Bool { isPresenting }

    func attach(to arView: ARView) {
        self.arView = arView
    }

    func present(
        _ presentation: FeedbackPresentation,
        cameraTransform: simd_float4x4?,
        surfaceDistance: Float? = nil
    ) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.present(
                    presentation,
                    cameraTransform: cameraTransform,
                    surfaceDistance: surfaceDistance
                )
            }
            return
        }

        removeImmediately()
        loadGeneration += 1
        let generation = loadGeneration
        isPresenting = true

        let spawn = spawnTransform(
            cameraTransform: cameraTransform,
            surfaceDistance: surfaceDistance
        )

        Task { @MainActor [weak self] in
            guard let self else { return }
            let entity = await RobotFeedbackAsset.load()
            guard generation == self.loadGeneration, self.isPresenting else { return }
            guard let root = entity, let arView = self.arView else {
                self.isPresenting = false
                return
            }

            self.install(root: root, in: arView, at: spawn, presentation: presentation)
        }
    }

    func dismiss() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in self?.dismiss() }
            return
        }
        guard isPresenting else { return }

        loadGeneration += 1
        isPresenting = false

        guard let root, let robot, let anchor else {
            removeImmediately()
            return
        }

        bounceGeneration += 1
        hoverController?.stop()
        hoverController = nil

        let exitingHintCard = hintCard

        if let exit = RobotFeedbackAsset.animation(named: RobotFeedbackAsset.disappearanceTimeline, in: root) {
            root.playAnimation(exit)
            animateScale(
                exitingHintCard,
                to: 0.001,
                duration: RobotFeedbackAsset.disappearanceDuration,
                timing: .easeIn
            )
        } else {

            animateScale(
                robot,
                to: 0.001,
                duration: RobotFeedbackAsset.disappearanceDuration,
                timing: .easeIn
            )
            animateScale(
                exitingHintCard,
                to: 0.001,
                duration: RobotFeedbackAsset.disappearanceDuration,
                timing: .easeIn
            )
        }

        self.anchor = nil
        self.root = nil
        self.robot = nil
        self.hintCard = nil

        DispatchQueue.main.asyncAfter(
            deadline: .now() + RobotFeedbackAsset.disappearanceDuration + 0.05
        ) {
            anchor.removeFromParent()
        }
    }

    func update(cameraTransform: simd_float4x4, deltaTime: Float) {
        guard isPresenting, let root else { return }

        let cameraPosition = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )

        let target = Self.billboardOrientation(
            of: root.position(relativeTo: nil),
            facing: cameraPosition,
            facesPositiveZ: RobotFeedbackLayout.facesPositiveZ
        )
        guard let targetOrientation = target else { return }

        let factor = PlacementSolver.lerpFactor(
            deltaTime: deltaTime,
            smoothing: RobotFeedbackLayout.billboardSmoothing
        )
        root.orientation = simd_slerp(root.orientation, targetOrientation, factor)
    }

    static func billboardOrientation(
        of entityPosition: SIMD3<Float>,
        facing cameraPosition: SIMD3<Float>,
        facesPositiveZ: Bool
    ) -> simd_quatf? {
        var toCamera = cameraPosition - entityPosition
        guard simd_length_squared(toCamera) > 1e-6 else { return nil }
        toCamera = simd_normalize(toCamera)

        let forward = facesPositiveZ ? toCamera : -toCamera

        let worldUp = SIMD3<Float>(0, 1, 0)
        var right = simd_cross(worldUp, forward)
        if simd_length_squared(right) < 1e-6 {
            right = SIMD3<Float>(1, 0, 0)
        }
        right = simd_normalize(right)
        let up = simd_normalize(simd_cross(forward, right))

        let basis = simd_float3x3(right, up, forward)
        return simd_quatf(basis)
    }

    private func install(
        root: Entity,
        in arView: ARView,
        at spawn: SpawnPlacement,
        presentation: FeedbackPresentation
    ) {
        let robot = root.findEntity(named: RobotFeedbackAsset.robotName) ?? root

        distanceScale = spawn.scale
        rootScale = resolveScale(for: robot, in: root)

        root.scale = SIMD3<Float>(repeating: rootScale)
        root.position = spawn.position
        root.orientation = spawn.yaw

        attachHintCard(presentation, to: root)

        robot.scale = SIMD3<Float>(repeating: 0.001)

        let anchor = AnchorEntity(world: matrix_identity_float4x4)
        anchor.addChild(root)
        arView.scene.addAnchor(anchor)

        self.anchor = anchor
        self.root = root
        self.robot = robot

        if let appear = RobotFeedbackAsset.animation(named: RobotFeedbackAsset.appearanceTimeline, in: root) {
            root.playAnimation(appear)
        } else {

            animateScale(
                robot,
                to: 1,
                duration: RobotFeedbackAsset.appearanceDuration,
                timing: .easeOut
            )
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + RobotFeedbackAsset.appearanceDuration + 0.02
        ) { [weak self] in
            guard let self, self.isPresenting, self.root === root else { return }

            self.correctScaleIfNeeded(robot: robot, root: root)
            self.revealHintCard()

            if let hover = RobotFeedbackAsset.animation(named: RobotFeedbackAsset.hoverTimeline, in: root) {
                self.hoverController = root.playAnimation(hover.repeat())
            } else {
                print("[RobotFeedbackPresenter] Timeline \(RobotFeedbackAsset.hoverTimeline) tidak terbaca, memakai bounce manual.")
                RobotFeedbackAsset.listAnimations(in: root)
                self.startManualBounce(robot: robot, root: root)
            }
        }
    }

    private var targetHeight: Float {
        RobotFeedbackLayout.robotHeight * distanceScale
    }

    private func resolveScale(for robot: Entity, in root: Entity) -> Float {
        let measured = robot.visualBounds(relativeTo: root).extents.y

        let native: Float
        let mode: String
        if measured.isFinite && measured > 0.05 {
            native = measured
            mode = "terukur"
        } else {
            native = RobotFeedbackLayout.assumedNativeHeight
            mode = "acuan Scene.usda"
        }

        let scale = targetHeight / native
        print(String(
            format: "[RobotFeedbackPresenter] tinggi mentah %.4f (%@) -> skala %.5f -> akhir %.3f m",
            measured, mode, scale, native * scale
        ))
        return scale
    }

    private func startManualBounce(robot: Entity, root: Entity) {
        bounceGeneration += 1
        let generation = bounceGeneration
        let base = robot.transform
        var lifted = base
        lifted.translation.y += RobotFeedbackLayout.bounceHeight

        scheduleBounce(
            robot: robot,
            root: root,
            generation: generation,
            base: base,
            lifted: lifted,
            goingUp: true
        )
    }

    private func scheduleBounce(
        robot: Entity,
        root: Entity,
        generation: Int,
        base: Transform,
        lifted: Transform,
        goingUp: Bool
    ) {
        guard isPresenting, self.root === root, generation == bounceGeneration else { return }

        let target = goingUp ? lifted : base
        let duration = goingUp
            ? RobotFeedbackLayout.bounceUpDuration
            : RobotFeedbackLayout.bounceDownDuration

        robot.move(
            to: target,
            relativeTo: robot.parent,
            duration: duration,
            timingFunction: goingUp ? .easeIn : .easeOut
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.scheduleBounce(
                robot: robot,
                root: root,
                generation: generation,
                base: base,
                lifted: lifted,
                goingUp: !goingUp
            )
        }
    }

    private func correctScaleIfNeeded(robot: Entity, root: Entity) {
        let actual = robot.visualBounds(relativeTo: nil).extents.y
        guard actual.isFinite, actual > 1e-4 else { return }

        let correction = targetHeight / actual
        guard correction < 0.9 || correction > 1.1 else { return }

        rootScale *= correction
        root.scale = SIMD3<Float>(repeating: rootScale)

        print(String(
            format: "[RobotFeedbackPresenter] koreksi lanjutan x%.5f -> tinggi %.3f m",
            correction, targetHeight
        ))
    }

    private func animateScale(
        _ entity: Entity?,
        to scale: Float,
        duration: TimeInterval,
        timing: AnimationTimingFunction
    ) {
        guard let entity else { return }
        var target = entity.transform
        target.scale = SIMD3<Float>(repeating: scale)
        entity.move(
            to: target,
            relativeTo: entity.parent,
            duration: duration,
            timingFunction: timing
        )
    }

    private func attachHintCard(_ presentation: FeedbackPresentation, to root: Entity) {
        guard let anchorPoint = root.findEntity(named: RobotFeedbackAsset.hintAnchorName) else {
            print("[RobotFeedbackPresenter] \(RobotFeedbackAsset.hintAnchorName) tidak ditemukan di scene.")
            return
        }

        anchorPoint.children.filter { $0.name == "robotHintCard" }.forEach { $0.removeFromParent() }

        guard let card = RobotHintCard.makeEntity(
            for: presentation,
            width: RobotFeedbackLayout.hintCardWidth * distanceScale
        ) else { return }

        if !RobotFeedbackLayout.facesPositiveZ {
            card.orientation = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))
        }

        card.scale = SIMD3<Float>(repeating: 0.001)
        anchorPoint.addChild(card)
        hintCard = card
    }

    private func revealHintCard() {
        guard let hintCard else { return }
        let inverse = 1 / max(rootScale, 1e-6)
        hintCard.position = SIMD3<Float>(0, RobotFeedbackLayout.hintCardLift * distanceScale * inverse, 0)

        var target = hintCard.transform
        target.scale = SIMD3<Float>(repeating: inverse)
        hintCard.move(
            to: target,
            relativeTo: hintCard.parent,
            duration: RobotFeedbackLayout.cardAppearDuration,
            timingFunction: .easeOut
        )
    }

    private struct SpawnPlacement {
        var position: SIMD3<Float>
        var yaw: simd_quatf
        var scale: Float
        var distance: Float
    }

    private func spawnTransform(
        cameraTransform: simd_float4x4?,
        surfaceDistance: Float?
    ) -> SpawnPlacement {
        guard let cameraTransform else {
            return SpawnPlacement(
                position: SIMD3<Float>(0, 0, -RobotFeedbackLayout.distanceFromCamera),
                yaw: simd_quatf(),
                scale: 1,
                distance: RobotFeedbackLayout.distanceFromCamera
            )
        }

        var distance = RobotFeedbackLayout.distanceFromCamera
        if let surfaceDistance, surfaceDistance.isFinite, surfaceDistance > 0 {
            distance = surfaceDistance - RobotFeedbackLayout.clearanceFromSurface
        }
        distance = max(distance, RobotFeedbackLayout.minDistanceFromCamera)

        let scale = min(
            max(distance / RobotFeedbackLayout.distanceFromCamera, RobotFeedbackLayout.minDistanceScale),
            1
        )

        let solved = placement(
            cameraTransform: cameraTransform,
            distance: distance,
            scale: scale
        )

        return SpawnPlacement(
            position: solved.position,
            yaw: solved.yaw,
            scale: scale,
            distance: distance
        )
    }

    private func placement(
        cameraTransform: simd_float4x4,
        distance: Float,
        scale: Float
    ) -> (position: SIMD3<Float>, yaw: simd_quatf) {
        let origin = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )

        let viewDirection = -SIMD3<Float>(
            cameraTransform.columns.2.x,
            cameraTransform.columns.2.y,
            cameraTransform.columns.2.z
        )

        var flattened = viewDirection
        flattened.y = 0
        let horizontal = simd_length_squared(flattened) > 1e-6
            ? simd_normalize(flattened)
            : SIMD3<Float>(0, 0, -1)

        let aim = simd_length_squared(viewDirection) > 1e-6
            ? simd_normalize(viewDirection)
            : horizontal

        let base = origin + aim * distance

        var lateral = simd_cross(horizontal, SIMD3<Float>(0, 1, 0))
        lateral = simd_length_squared(lateral) > 1e-6
            ? simd_normalize(lateral)
            : SIMD3<Float>(1, 0, 0)

        var screenUp = simd_cross(lateral, aim)
        screenUp = simd_length_squared(screenUp) > 1e-6
            ? simd_normalize(screenUp)
            : SIMD3<Float>(0, 1, 0)

        let pitch = aim.y
        let verticalBias = RobotFeedbackLayout.verticalOffset
            - pitch * RobotFeedbackLayout.pitchVerticalCompensation

        var offset = lateral * (RobotFeedbackLayout.lateralOffset * scale)
            + screenUp * (verticalBias * scale)

        let maxOffset = distance * tan(RobotFeedbackLayout.maxOnScreenAngleDegrees * .pi / 180)
        let offsetLength = simd_length(offset)
        if offsetLength > maxOffset, offsetLength > 1e-6 {
            offset *= (maxOffset / offsetLength)
        }

        let position = base + offset

        let yaw = Self.billboardOrientation(
            of: position,
            facing: origin,
            facesPositiveZ: RobotFeedbackLayout.facesPositiveZ
        ) ?? simd_quatf(angle: atan2(-horizontal.x, -horizontal.z), axis: SIMD3<Float>(0, 1, 0))

        return (position, yaw)
    }

    private func removeImmediately() {
        bounceGeneration += 1
        hoverController?.stop()
        hoverController = nil
        anchor?.removeFromParent()
        anchor = nil
        root = nil
        robot = nil
        hintCard = nil
    }
}
