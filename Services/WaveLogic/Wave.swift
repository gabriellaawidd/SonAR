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
    static let transmitterName = "_0"
    static let receiverName = "_1"

    private static let maxRange: Float = 2
    private static let travelSpeed: Float = 0.7
    private static let minLegDuration: TimeInterval = 0.15
    private static let pulseGap: TimeInterval = 0.05
   
    private static let echoReturnAngleLimitDeg: Float = 10

    static let minReturningRays = 3

    private static let softMaxEchoes = 2

    private static let arrowVisualScale: Float = 1.8
    private static let decalVisualScale: Float = 1.6

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

    @discardableResult
    static func fire(from sensor: Entity, anchor: AnchorEntity, hits: [RaycastHit?], directions: [SIMD3<Float>], material: MaterialCategory?, onReport: ((PulseReport) -> Void)? = nil) -> TimeInterval {
        guard let transmitter = sensor.findEntity(named: transmitterName),
              let receiver = sensor.findEntity(named: receiverName) else {
            return 0
        }

        let origin = transmitter.position(relativeTo: nil)
        let absorbent = (material == .soft)
        var maxDuration: TimeInterval = 0
        var returnedCount = 0

        var nearestValidDistance: Float?
        
        let centerHit = hits.first ?? nil
        let centerPosition = centerHit?.worldPosition ?? origin
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

            if let hit {
                nearestValidDistance = min(nearestValidDistance ?? hit.distance, hit.distance)
            }

            let distance = hit?.distance ?? maxRange
            let hitPoint = hit?.worldPosition ?? origin + forward * distance

            let outDuration = legDuration(distance)
            WaveRenderer.spawnPulse(color: .cyan, from: origin, to: hitPoint, anchor: anchor, duration: outDuration, scale: arrowVisualScale)

            var totalDuration = outDuration
            if let hit = hit {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(outDuration))
                    WaveRenderer.spawnHitDecal(at: hit.worldPosition, normal: hit.normal, anchor: anchor, scale: decalVisualScale)
                }
                
                if hit.incidenceAngleDegrees(incoming: forward) <= echoReturnAngleLimitDeg,
                   !absorbent || returnedCount < softMaxEchoes {
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
                    let scale: Float = (material == .soft ? 0.5 : 1.0) * arrowVisualScale
            
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(outDuration))
                        WaveRenderer.spawnPulse(color: .green, from: hitPoint, to: targetPos, anchor: anchor, duration: backDuration, opacity: opacity, scale: scale)
                    }
                    totalDuration += backDuration
                } else if !absorbent {
                    let reflectedDirection = simd_reflect(simd_normalize(forward), simd_normalize(hit.normal))
                    let remainingDistance = max(maxRange - distance, 0)
                    let bounceDistance = material == .soft ? min(remainingDistance, 0.5) : remainingDistance
                    
                    let bounceTarget = hit.worldPosition + reflectedDirection * bounceDistance
                    let speedMult: Float = 1.0
                    let bounceDuration = legDuration(bounceDistance, speedMultiplier: speedMult)
                    
                    let opacity: Float = material == .soft ? 1.0 : 1.0
                    let scale: Float = (material == .soft ? 0.5 : 1.0) * arrowVisualScale
                    
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(outDuration))
                        WaveRenderer.spawnPulse(color: .red, from: hitPoint, to: bounceTarget, anchor: anchor, duration: bounceDuration, opacity: opacity, scale: scale)
                    }
                    totalDuration += bounceDuration
                }
            }
            maxDuration = max(maxDuration, totalDuration)
        }

        let measurable = absorbent ? (centerHit != nil) : returnedCount >= minReturningRays

        let reportedDistance = centerHit?.distance ?? nearestValidDistance

        onReport?(PulseReport(
            returned: returnedCount,
            total: directions.count,
            centerDistance: measurable ? reportedDistance : nil,
            centerAngle: centerAngle
        ))

        return maxDuration
    }

    static func startLoop(
        sensor: Entity,
        anchor: AnchorEntity,
        lockID: UUID,
        refreshHit: @escaping (UUID, [SIMD3<Float>]) async -> [RaycastHit?],
        getMaterial: @escaping () -> MaterialCategory?,
        onPulse: ((PulseReport) -> Void)? = nil
    ) -> Task<Void, Never> {
        Task { @MainActor in
            let orientation = sensor.orientation(relativeTo: nil)

            let ringConfigs: [(angle: Float, count: Int)] = [
                (5.0, 8),
                (10.0, 14)
            ]

            var angles: [(Float, SIMD3<Float>)] = [(0, [1, 0, 0])]
            for config in ringConfigs {
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

            while !Task.isCancelled {
                guard sensor.parent != nil else { break }

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
