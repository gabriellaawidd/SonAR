import Foundation
import RealityKit
import UIKit

enum WaveRenderer {
    private static let pulseRadius: Float = 0.003

    static func spawnPulse( // munculin bola soundwave
        color: UIColor, from start: SIMD3<Float>, to end: SIMD3<Float>, anchor: AnchorEntity, duration: TimeInterval,
        opacity: Float = 1.0, scale: Float = 1.0
    ) {
        let finalColor = color.withAlphaComponent(CGFloat(opacity))
        var material = UnlitMaterial(color: finalColor)
        if opacity < 1.0 {
            material.blending = .transparent(opacity: .init(floatLiteral: opacity))
        }

        let pulse = ModelEntity(
            mesh: .generateSphere(radius: pulseRadius * scale),
            materials: [material]
        )
        pulse.setPosition(start, relativeTo: nil)

        anchor.addChild(pulse)

        pulse.move(to: Transform(translation: end), relativeTo: nil, duration: duration, timingFunction: .linear)

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            pulse.removeFromParent()
        }
    }
}
