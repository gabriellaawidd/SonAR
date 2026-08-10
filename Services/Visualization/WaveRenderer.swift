import Foundation
import RealityKit
import UIKit

enum WaveRenderer {
    private static let pulseRadius: Float = 0.003

    static func spawnPulse(
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
