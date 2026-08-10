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

    private static let maxRange: Float = 2 // Dikecilin dari 4 jadi 2 supaya jeda antar spawnPulse gak terlalu lama (UX things)
    private static let travelSpeed: Float = 0.75
    private static let minLegDuration: TimeInterval = 0.15
    private static let pulseGap: TimeInterval = 0.20
    /// Beyond this incidence angle a real echo's specular reflection no longer sweeps back
    /// near the sensor, so it never returns to the receiver.
    private static let echoReturnAngleLimitDeg: Float = 10
    private static let pulseRadius: Float = 0.003

    /// Fires one pulse: a beam from the transmitter to the hit point (or `maxRange` if nothing
    /// hit), then, only if the surface angle allows an echo, a return beam to the receiver.
    /// Returns how long the pulse takes to fully finish, so a loop can wait before firing again.
    @discardableResult
    static func fire(from sensor: Entity, anchor: AnchorEntity, hits: [RaycastHit?], directions: [SIMD3<Float>]) -> TimeInterval {
        guard let transmitter = sensor.findEntity(named: transmitterName),
              let receiver = sensor.findEntity(named: receiverName) else {
            return 0
        }

        let origin = transmitter.position(relativeTo: nil)
        var maxDuration: TimeInterval = 0

        for (hit, forward) in zip(hits, directions) {
            let distance = min(hit?.distance ?? maxRange, maxRange)
            let hitPoint = hit?.worldPosition ?? origin + forward * distance

            let outDuration = legDuration(distance)
            spawnPulse(color: .cyan, from: origin, to: hitPoint, anchor: anchor, duration: outDuration)

            var totalDuration = outDuration
            if let hit = hit {
                if hit.incidenceAngleDegrees(incoming: forward) <= echoReturnAngleLimitDeg {
                    // Return echo
                    let receiverPosition = receiver.position(relativeTo: nil)
                    let backDuration = legDuration(simd_distance(hitPoint, receiverPosition))
            
                    DispatchQueue.main.asyncAfter(deadline: .now() + outDuration) {
                        spawnPulse(color: .green, from: hitPoint, to: receiverPosition, anchor: anchor, duration: backDuration)
                    }
                    totalDuration += backDuration
                } else {
                    // Specular reflection bouncing away
                    let reflectedDirection = simd_reflect(simd_normalize(forward), simd_normalize(hit.normal))
                    let remainingDistance = max(maxRange - distance, 0)
                    let bounceTarget = hit.worldPosition + reflectedDirection * remainingDistance
                    let bounceDuration = legDuration(remainingDistance)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + outDuration) {
                        spawnPulse(color: .red, from: hitPoint, to: bounceTarget, anchor: anchor, duration: bounceDuration)
                    }
                    totalDuration += bounceDuration
                }
            }
            maxDuration = max(maxDuration, totalDuration)
        }

        return maxDuration
    }

    /// Fires repeatedly, re-raycasting `lockID` before each pulse, until cancelled — mirrors a
    /// real HC-SR04 not firing again until the previous echo window closes.
    static func startLoop(
        sensor: Entity,
        anchor: AnchorEntity,
        lockID: UUID,
        refreshHit: @escaping (UUID, [SIMD3<Float>]) -> [RaycastHit?]
    ) -> Task<Void, Never> {
        Task { @MainActor in
            while !Task.isCancelled {
                // Generate 25 directions: 1 Center + 3 layers of 8 (5, 10, and 15 deg)
                let orientation = sensor.orientation(relativeTo: nil)
                let invSqrt2: Float = 0.70710678
                let axes: [SIMD3<Float>] = [
                    [1, 0, 0], // Up
                    [invSqrt2, invSqrt2, 0], // Up-Right
                    [0, 1, 0], // Right
                    [-invSqrt2, invSqrt2, 0], // Down-Right
                    [-1, 0, 0], // Down
                    [-invSqrt2, -invSqrt2, 0], // Down-Left
                    [0, -1, 0], // Left
                    [invSqrt2, -invSqrt2, 0] // Up-Left
                ]
                
                var angles: [(Float, SIMD3<Float>)] = [(0, [1, 0, 0])] // Center
                for angle in [5.0, 10.0, 15.0] as [Float] {
                    for axis in axes {
                        angles.append((angle, axis))
                    }
                }
                
                let directions = angles.map { angle, axis in
                    let rotation = simd_quatf(angle: angle * .pi / 180, axis: axis)
                    return (orientation * rotation).act(SIMD3<Float>(0, 0, -1))
                }
                
                let hits = refreshHit(lockID, directions)
                let pulseDuration = fire(from: sensor, anchor: anchor, hits: hits, directions: directions)
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
