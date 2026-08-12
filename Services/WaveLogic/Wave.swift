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

    private static let maxRange: Float = 2   // Dikecilin dari 4 jadi 2 supaya jeda antar spawnPulse gak terlalu lama (UX things)
    private static let travelSpeed: Float = 0.7
    private static let minLegDuration: TimeInterval = 0.15
    private static let pulseGap: TimeInterval = 0.05
    /// Beyond this incidence angle a real echo's specular reflection no longer sweeps back
    /// near the sensor, so it never returns to the receiver.
    private static let echoReturnAngleLimitDeg: Float = 10

    /// Minimum returning rays for the walkthrough to call a surface flat. Only read by the
    /// guided flow — the visualisation itself is unaffected.
    static let minReturningRays = 3

    /// Soft surfaces scatter sound inside their pores, so only a couple of rays make it back.
    private static let softMaxEchoes = 2

    /// Summary of one pulse, used by the guided walkthrough to judge a placement.
    struct PulseReport: Equatable {
        let returned: Int
        let total: Int
        let centerDistance: Float?
        let centerAngle: Float?

        var isBounceBack: Bool { returned >= Wave.minReturningRays }

        var distanceCentimeters: Int? {
            guard let centerDistance else { return nil }
            return Int((centerDistance * 100).rounded())
        }
    }

    /// Fires one pulse: a beam from the transmitter to the hit point (or `maxRange` if nothing
    /// hit), then, only if the surface angle allows an echo, a return beam to the receiver.
    /// Returns how long the pulse takes to fully finish, so a loop can wait before firing again.
    @discardableResult
    static func fire(from sensor: Entity, anchor: AnchorEntity, hits: [RaycastHit?], directions: [SIMD3<Float>], material: MaterialCategory?, onReport: ((PulseReport) -> Void)? = nil) -> TimeInterval {
        guard let transmitter = sensor.findEntity(named: transmitterName),
              let receiver = sensor.findEntity(named: receiverName) else {
            return 0
        }

        let origin = transmitter.position(relativeTo: nil)
        let absorbent = (material == .soft)
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

        for (originalHit, forward) in zip(hits, directions) {
            let hit = originalHit.flatMap { $0.distance <= maxRange ? $0 : nil }
            
            let distance = hit?.distance ?? maxRange
            let hitPoint = hit?.worldPosition ?? origin + forward * distance
//            print("[waveAsset] distance: \(distance) -> hitPoint: \(hitPoint)")

            let outDuration = legDuration(distance)
            WaveRenderer.spawnPulse(color: .cyan, from: origin, to: hitPoint, anchor: anchor, duration: outDuration)

            var totalDuration = outDuration
            if let hit = hit {
                DispatchQueue.main.asyncAfter(deadline: .now() + outDuration) {
                    WaveRenderer.spawnHitDecal(at: hit.worldPosition, normal: hit.normal, anchor: anchor)
                }
                
                if hit.incidenceAngleDegrees(incoming: forward) <= echoReturnAngleLimitDeg {
                    // Return echo
                    returnedCount += 1
                    let receiverPosition = receiver.position(relativeTo: nil)
                    let fullDist = simd_distance(hitPoint, receiverPosition)
                    
                    let remainingDistance = max(maxRange - distance, 0)
                    let maxBounceDist = material == .soft ? min(remainingDistance, 0.5) : remainingDistance
                    let bounceDistance = min(fullDist, maxBounceDist)
                    
                    let speedMult: Float = 1.0
                    let backDuration = legDuration(bounceDistance, speedMultiplier: speedMult)
                    
                    let targetPos = hitPoint + simd_normalize(receiverPosition - hitPoint) * bounceDistance
                        
                    let opacity: Float = material == .soft ? 1.0 : 1.0
                    let scale: Float = material == .soft ? 0.5 : 1.0
            
                    DispatchQueue.main.asyncAfter(deadline: .now() + outDuration) {
                        WaveRenderer.spawnPulse(color: .green, from: hitPoint, to: targetPos, anchor: anchor, duration: backDuration, opacity: opacity, scale: scale)
                    }
                    totalDuration += backDuration
                } else if !absorbent {
                    // Specular reflection bouncing away. Soft surfaces skip this entirely:
                    // they diffuse the sound rather than deflecting it like a mirror.
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

        // Distance only means something when enough echoes actually came back.
        let measurable = returnedCount >= minReturningRays
        onReport?(PulseReport(
            returned: returnedCount,
            total: directions.count,
            centerDistance: measurable ? centerHit?.distance : nil,
            centerAngle: centerAngle
        ))

        return maxDuration
    }

    /// Fires repeatedly, re-raycasting `lockID` before each pulse, until cancelled — mirrors a
    /// real HC-SR04 not firing again until the previous echo window closes.
    static func startLoop(
        sensor: Entity,
        anchor: AnchorEntity,
        lockID: UUID,
        refreshHit: @escaping (UUID, [SIMD3<Float>]) async -> [RaycastHit?],
        getMaterial: @escaping () -> MaterialCategory?,
        onPulse: ((PulseReport) -> Void)? = nil
    ) -> Task<Void, Never> {
        Task { @MainActor in
            while !Task.isCancelled {
                guard sensor.parent != nil else { break }

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
                
                let hits = await refreshHit(lockID, directions)
                let material = getMaterial()
                BeepSynthesizer.shared.playLowBeep()
                fire(from: sensor, anchor: anchor, hits: hits, directions: directions, material: material, onReport: onPulse)
                try? await Task.sleep(for: .seconds(1.0))
            }
        }
    }

    private static func legDuration(_ distance: Float, speedMultiplier: Float = 1.0) -> TimeInterval {
        max(TimeInterval(distance / (travelSpeed * speedMultiplier)), minLegDuration)
    }
}
