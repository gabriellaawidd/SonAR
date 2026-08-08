//
//  MaterialDetectionManager.swift
//  SonAR
//
//  Created by Gabriella Angelina Widjaja on 08/08/26.
//

import Foundation
import CoreVideo
import simd

final class MaterialDetectionManager {

    private let geometryClassifier: SurfaceGeometryClassifier
    private let visionClassifier: MaterialVisionClassifier

    var onReadingReady: ((PlacementLock, SurfaceReading) -> Void)?

    init(
        raycastProvider: SurfaceRaycastProviding,
        geometryClassifier: SurfaceGeometryClassifier = SurfaceGeometryClassifier(),
        visionClassifier: MaterialVisionClassifier = MaterialVisionClassifier()
    ) {
        self.geometryClassifier = geometryClassifier
        self.visionClassifier = visionClassifier

        raycastProvider.onLockCreated = { [weak self] lock, pixelBuffer in
            self?.handleLock(lock, pixelBuffer: pixelBuffer)
        }
    }

    private func handleLock(_ lock: PlacementLock, pixelBuffer: CVPixelBuffer?) {
        guard let hit = lock.hit else { return }
        

        let geometryResult = geometryClassifier.classify(angleDegrees: lock.incidenceAngleDegrees)

        guard let pixelBuffer else {
            report(SurfaceReading(
                normal: hit.normal,
                angleDegrees: geometryResult.angleDegrees,
                angleCategory: geometryResult.category,
                materialCategory: .unknown,
                materialConfidence: 0
            ), for: lock)
            return
        }

        visionClassifier.classify(pixelBuffer: pixelBuffer) { [weak self] materialResult in
            guard let self else { return }
            self.report(SurfaceReading(
                normal: hit.normal,
                angleDegrees: geometryResult.angleDegrees,
                angleCategory: geometryResult.category,
                materialCategory: materialResult.category,
                materialConfidence: materialResult.confidence
            ), for: lock)
        }
    }

    private func report(_ reading: SurfaceReading, for lock: PlacementLock) {
        onReadingReady?(lock, reading)
    }
}
