import Foundation
import RealityKit
import UIKit

enum WaveRenderer {
    private static let pulseRadius: Float = 0.003
    
    private static var cachedTipMesh: MeshResource?
    private static var cachedShaftMesh: MeshResource?
    private static var cachedDecalMesh: MeshResource?
    private static var cachedMaterials: [String: PhysicallyBasedMaterial] = [:]
    private static var cachedArrowTemplates: [String: Entity] = [:]
    private static var cachedDecalTemplate: ModelEntity?
    
    private static func getMaterial(color: UIColor, opacity: Float) -> PhysicallyBasedMaterial {
        let key = "\(color.description)-\(opacity)"
        if let cached = cachedMaterials[key] { return cached }
        
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let darkerColor = UIColor(hue: h, saturation: s, brightness: b * 0.7, alpha: a)
        
        let finalColor = darkerColor.withAlphaComponent(CGFloat(opacity))
        
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: finalColor)
        material.emissiveColor = .init(color: darkerColor)
        material.emissiveIntensity = 0.5
        material.roughness = 0.6
        material.metallic = 0.0
        
        if opacity < 1.0 {
            material.blending = .transparent(opacity: .init(floatLiteral: opacity))
        }
        
        cachedMaterials[key] = material
        return material
    }
    
    private static func getDecalMaterial() -> PhysicallyBasedMaterial {
        let key = "decal"
        if let cached = cachedMaterials[key] { return cached }
        
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor.gray.withAlphaComponent(0.6))
        material.roughness = 0.9
        material.metallic = 0.0
        material.blending = .transparent(opacity: .init(floatLiteral: 0.6))
        
        cachedMaterials[key] = material
        return material
    }

    private static func getArrowTemplate(color: UIColor, opacity: Float) -> Entity {
        let key = "\(color.description)-\(opacity)"
        if let cached = cachedArrowTemplates[key] { return cached.clone(recursive: true) }
        
        let material = getMaterial(color: color, opacity: opacity)
        let arrowContainer = Entity()
        let yToMinusZ = simd_quatf(angle: -.pi/2, axis: [1, 0, 0])
        
        if cachedShaftMesh == nil {
            cachedShaftMesh = MeshResource.generateCylinder(height: pulseRadius * 7.5, radius: pulseRadius * 0.65)
        }
        let shaft = ModelEntity(mesh: cachedShaftMesh!, materials: [material])
        shaft.transform.rotation = yToMinusZ
        
        if cachedTipMesh == nil {
            cachedTipMesh = MeshResource.generateCone(height: pulseRadius * 6.0, radius: pulseRadius * 1.0)
        }
        let tip = ModelEntity(mesh: cachedTipMesh!, materials: [material])
        tip.transform.rotation = yToMinusZ
        tip.position = [0, 0, -pulseRadius * 6.0 / 2 - pulseRadius * 5.5 / 2]
        
        arrowContainer.addChild(shaft)
        arrowContainer.addChild(tip)
        
        cachedArrowTemplates[key] = arrowContainer
        return arrowContainer.clone(recursive: true)
    }

    private static func getDecalTemplate() -> ModelEntity {
        if let cached = cachedDecalTemplate { return cached.clone(recursive: true) }
        
        if cachedDecalMesh == nil {
            cachedDecalMesh = MeshResource.generateCylinder(height: 0.001, radius: pulseRadius * 1.75 * 0.5)
        }
        
        let material = getDecalMaterial()
        let decal = ModelEntity(mesh: cachedDecalMesh!, materials: [material])
        cachedDecalTemplate = decal
        return decal.clone(recursive: true)
    }

    static func spawnPulse(
        color: UIColor, from start: SIMD3<Float>, to end: SIMD3<Float>, anchor: AnchorEntity, duration: TimeInterval,
        opacity: Float = 1.0, scale: Float = 1.0
    ) {
        if simd_distance(start, end) < 0.001 { return }
        
        let arrowContainer = getArrowTemplate(color: color, opacity: opacity)

        arrowContainer.setPosition(start, relativeTo: nil)
        arrowContainer.look(at: end, from: start, relativeTo: nil)
        arrowContainer.scale = [scale, scale, scale]
        
        anchor.addChild(arrowContainer)

        var targetTransform = arrowContainer.transform
        targetTransform.translation = anchor.convert(position: end, from: nil)
        
        arrowContainer.move(to: targetTransform, relativeTo: anchor, duration: duration, timingFunction: .linear)

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            arrowContainer.removeFromParent()
        }
    }

    static func spawnHitDecal(at position: SIMD3<Float>, normal: SIMD3<Float>, anchor: AnchorEntity, scale: Float = 1.0) {
        let decal = getDecalTemplate()
        
        decal.position = anchor.convert(position: position + normal * 0.002, from: nil)
        
        decal.orientation = simd_quatf(from: [0, 1, 0], to: normal)
     
        decal.scale = [scale, scale, scale]
        
        anchor.addChild(decal)
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            var targetTransform = decal.transform
            targetTransform.scale = [0.01, 0.01, 0.01]
            decal.move(to: targetTransform, relativeTo: decal.parent, duration: 0.2, timingFunction: .easeOut)
     
            try? await Task.sleep(for: .seconds(0.2))
            decal.removeFromParent()
        }
    }
}
