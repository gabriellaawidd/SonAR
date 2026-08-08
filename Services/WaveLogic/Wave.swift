//
//  Wave.swift
//  SonAR
//
//  Created by Maula Izza Azizi on 08/08/26.
//

import Foundation
import RealityKit
import UIKit
import simd

enum Wave {
    // ponytail: geometry doesn't say which dome is T vs R, swap if it's backwards
    static let transmitterName = "_0"
    static let receiverName = "_1"

    private static let maxRange: Float = 4
    private static let travelSpeed: Float = 1.5
    private static let minLegDuration: TimeInterval = 0.15
    private static let pulseGap: TimeInterval = 0.35
    /// Beyond this incidence angle a real echo's specular reflection no longer sweeps back
    /// near the sensor, so it never returns to the receiver.
    private static let echoReturnAngleLimitDeg: Float = 35
    private static let pulseRadius: Float = 0.006

    /// Fires one pulse: a beam from the transmitter to the hit point (or `maxRange` if nothing
    /// hit), then, only if the surface angle allows an echo, a return beam to the receiver.
    /// Returns how long the pulse takes to fully finish, so a loop can wait before firing again.
    @discardableResult
    static func fire(from sensor: Entity, anchor: AnchorEntity, hit: RaycastHit?) -> TimeInterval {
        guard let transmitter = sensor.findEntity(named: transmitterName),
              let receiver = sensor.findEntity(named: receiverName) else {
            return 0
        }

        let forward = PlacementSolver.facingDirection(of: sensor.orientation(relativeTo: nil))
        let origin = transmitter.position(relativeTo: nil)
        let distance = min(hit?.distance ?? maxRange, maxRange)
        let hitPoint = hit?.worldPosition ?? origin + forward * distance

        let outDuration = legDuration(distance)
        spawnPulse(color: .cyan, from: origin, to: hitPoint, anchor: anchor, duration: outDuration)

        guard let hit, hit.incidenceAngleDegrees(incoming: forward) <= echoReturnAngleLimitDeg else {
            return outDuration
        }

        let receiverPosition = receiver.position(relativeTo: nil)
        let backDuration = legDuration(simd_distance(hitPoint, receiverPosition))

        DispatchQueue.main.asyncAfter(deadline: .now() + outDuration) {
            spawnPulse(color: .systemTeal, from: hitPoint, to: receiverPosition, anchor: anchor, duration: backDuration)
        }

        return outDuration + backDuration
    }

    /// Fires repeatedly, re-raycasting `lockID` before each pulse, until cancelled — mirrors a
    /// real HC-SR04 not firing again until the previous echo window closes.
    static func startLoop(
        sensor: Entity,
        anchor: AnchorEntity,
        lockID: UUID,
        refreshHit: @escaping (UUID) -> RaycastHit?
    ) -> Task<Void, Never> {
        Task { @MainActor in
            while !Task.isCancelled {
                let hit = refreshHit(lockID)
                let pulseDuration = fire(from: sensor, anchor: anchor, hit: hit)
                try? await Task.sleep(for: .seconds(pulseDuration + pulseGap))
            }
        }
    }

    private static func legDuration(_ distance: Float) -> TimeInterval {
        max(TimeInterval(distance / travelSpeed), minLegDuration)
    }

    private static func spawnPulse(
        color: UIColor, from start: SIMD3<Float>, to end: SIMD3<Float>, anchor: AnchorEntity, duration: TimeInterval
    ) {
        let pulse = ModelEntity(
            mesh: .generateSphere(radius: pulseRadius),
            materials: [UnlitMaterial(color: color)]
        )
        pulse.setPosition(start, relativeTo: nil)
        anchor.addChild(pulse)

        pulse.move(to: Transform(translation: end), relativeTo: nil, duration: duration, timingFunction: .easeInOut)

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            pulse.removeFromParent()
        }
    }
}
