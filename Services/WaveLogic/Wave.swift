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
    private static let travelSpeed: Float = 0.85
    private static let minLegDuration: TimeInterval = 0.15
    private static let pulseGap: TimeInterval = 0.05
    /// Beyond this incidence angle a real echo's specular reflection no longer sweeps back
    /// near the sensor, so it never returns to the receiver.
    private static let echoReturnAngleLimitDeg: Float = 10

    /// Fires one pulse: a beam from the transmitter to the hit point (or `maxRange` if nothing
    /// hit), then, only if the surface angle allows an echo, a return beam to the receiver.
    /// Returns how long the pulse takes to fully finish, so a loop can wait before firing again.
    @discardableResult
    static func fire(from sensor: Entity, anchor: AnchorEntity, hits: [RaycastHit?], directions: [SIMD3<Float>], material: MaterialCategory?) -> TimeInterval {
        guard let transmitter = sensor.findEntity(named: transmitterName),
              let receiver = sensor.findEntity(named: receiverName) else {
            return 0
        }

        let origin = transmitter.position(relativeTo: nil)
        var maxDuration: TimeInterval = 0
        
        let centerHit = hits.first ?? nil
        let centerPosition = centerHit?.worldPosition ?? origin // origin = transmitter.position(relativeTo: nil)
        print("[waveAsset] center point: \(centerPosition)")
        
        let centerDirection = directions.first ?? SIMD3<Float>(0, 0, -1)
        let centerAngle = centerHit?.incidenceAngleDegrees(incoming: centerDirection)
        print("[waveAsset] center angle: \(centerAngle.map { "\($0)°" } ?? "no hit")")
        
        let centerAngleCategory: AngleCategory
        if let centerAngle {
            centerAngleCategory = centerAngle <= echoReturnAngleLimitDeg ? .flat : .angled
        } else {
            centerAngleCategory = .unknown
        }
        
        print("[waveAsset] center angle category: \(centerAngleCategory.rawValue)")

        for (hit, forward) in zip(hits, directions) {
            let distance = min(hit?.distance ?? maxRange, maxRange)
            let hitPoint = hit?.worldPosition ?? origin + forward * distance
//            print("[waveAsset] distance: \(distance) -> hitPoint: \(hitPoint)")

            let outDuration = legDuration(distance)
            WaveRenderer.spawnPulse(color: .cyan, from: origin, to: hitPoint, anchor: anchor, duration: outDuration)

            var totalDuration = outDuration
            if let hit = hit {
                if hit.incidenceAngleDegrees(incoming: forward) <= echoReturnAngleLimitDeg {
                    // Return echo
                    let receiverPosition = receiver.position(relativeTo: nil)
                    let fullDist = simd_distance(hitPoint, receiverPosition)
                    let bounceDistance = material == .soft ? min(fullDist, 0.5) : fullDist
                    let speedMult: Float = 1.0
                    let backDuration = legDuration(bounceDistance, speedMultiplier: speedMult)
                    
                    let targetPos = material == .soft && fullDist > 0.5
                        ? hitPoint + simd_normalize(receiverPosition - hitPoint) * 0.5
                        : receiverPosition
                        
                    let opacity: Float = material == .soft ? 1.0 : 1.0
                    let scale: Float = material == .soft ? 0.5 : 1.0
            
                    DispatchQueue.main.asyncAfter(deadline: .now() + outDuration) {
                        WaveRenderer.spawnPulse(color: .green, from: hitPoint, to: targetPos, anchor: anchor, duration: backDuration, opacity: opacity, scale: scale)
                    }
                    totalDuration += backDuration
                } else {
                    // Specular reflection bouncing away
                    let reflectedDirection = simd_reflect(simd_normalize(forward), simd_normalize(hit.normal))
                    let remainingDistance = max(maxRange - distance, 0)
                    let bounceDistance = material == .soft ? min(remainingDistance, 0.5) : remainingDistance
                    
                    let bounceTarget = hit.worldPosition + reflectedDirection * bounceDistance
                    let speedMult: Float = 1.0
                    let bounceDuration = legDuration(bounceDistance, speedMultiplier: speedMult)
                    
                    let opacity: Float = material == .soft ? 1.0 : 1.0
                    let scale: Float = material == .soft ? 0.5 : 1.0
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + outDuration) {
                        WaveRenderer.spawnPulse(color: .red, from: hitPoint, to: bounceTarget, anchor: anchor, duration: bounceDuration, opacity: opacity, scale: scale)
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
        refreshHit: @escaping (UUID, [SIMD3<Float>]) -> [RaycastHit?],
        getMaterial: @escaping () -> MaterialCategory?
    ) -> Task<Void, Never> {
        Task { @MainActor in
            while !Task.isCancelled {
                // Generate dynamically: 1 Center + layers of varying counts
                let orientation = sensor.orientation(relativeTo: nil)
                
                let layerConfigs: [(angle: Float, count: Int)] = [
                    (3.75, 8),
                    (7.5, 12),
                    (11.25, 16),
                    (15.0, 20)
                ]
                
                var angles: [(Float, SIMD3<Float>)] = [(0, [1, 0, 0])] // Center
                for config in layerConfigs {
                    for i in 0..<config.count {
                        let theta = Float(i) * 2.0 * .pi / Float(config.count)
                        let axis = SIMD3<Float>(cos(theta), sin(theta), 0)
                        angles.append((config.angle, axis))
                    }
                }
                
                let directions = angles.map { angle, axis in
                    let rotation = simd_quatf(angle: angle * .pi / 180, axis: axis)
                    return (orientation * rotation).act(SIMD3<Float>(0, 0, -1))
                }
                
                let hits = refreshHit(lockID, directions)
                let material = getMaterial()
                BeepSynthesizer.shared.playLowBeep()
                fire(from: sensor, anchor: anchor, hits: hits, directions: directions, material: material)
                try? await Task.sleep(for: .seconds(1.0))
            }
        }
    }

    private static func legDuration(_ distance: Float, speedMultiplier: Float = 1.0) -> TimeInterval {
        max(TimeInterval(distance / (travelSpeed * speedMultiplier)), minLegDuration)
    }
}
