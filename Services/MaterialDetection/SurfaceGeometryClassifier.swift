//
//  SurfaceGeometryClassifier.swift
//  SonAR
//
//  Created by Gabriella Angelina Widjaja on 08/08/26.
//

import simd

final class SurfaceGeometryClassifier {
    private var recentAngles: [Float] = []

    func classify(angleDegrees: Float?) -> (angleDegrees: Float?, category: AngleCategory) {
        guard let angleDegrees else {
            recentAngles.removeAll()
            return (nil, .unknown)
        }
        let smoothed = applySmoothing(to: angleDegrees)
        let category: AngleCategory = smoothed <= AppConfig.flatAngleThreshold ? .flat : .angled
        return (smoothed, category)
    }

    private func applySmoothing(to newValue: Float) -> Float {
        recentAngles.append(newValue)
        if recentAngles.count > AppConfig.angleSmoothingWindowSize {
            recentAngles.removeFirst()
        }
        return recentAngles.reduce(0, +) / Float(recentAngles.count)
    }
}
