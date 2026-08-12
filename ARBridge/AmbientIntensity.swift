//
//  AmbientIntensity.swift
//  SonAR
//
//  Created by Maula Izza Azizi on 10/08/26.
//

import ARKit
import RealityKit

extension ARView {
    // ARKit reports ambientIntensity in lumens, ~0-2000, where 1000 ≈ a neutrally lit room.
    private static let lowLightThreshold: Double = 400
    private static let lowLightExponent: Float = 0.5

    func adjustLightingForAmbient(frame: ARFrame) {
        guard let ambientIntensity = frame.lightEstimate?.ambientIntensity else { return }

        environment.lighting.intensityExponent =
            ambientIntensity < Self.lowLightThreshold ? Self.lowLightExponent : 1.0
    }
}
