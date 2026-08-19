//
//  AnnotationMarker.swift
//  SonAR
//
//  Created by Tiffany Michelle on 13/08/26.
//

import RealityKit
import UIKit
import simd

enum AnnotationMarkerLayout {
    static let width: Float = 0.04
    static let heightAboveSensor: Float = 0.045
    static let bobHeight: Float = 0.006
    static let bobDuration: TimeInterval = 0.9
    static let tapZoneRadius: Float = 0.05
}

enum AnnotationMarker {

    static let entityName = "annotationMarker"
    static let tapZoneName = "annotationTapZone"

    static func makeEntity() -> ModelEntity? {
        guard let image = render(), let cgImage = image.cgImage else { return nil }

        do {
            let texture = try TextureResource(
                image: cgImage,
                withName: nil,
                options: .init(semantic: .color)
            )

            var material = UnlitMaterial()
            material.color = .init(tint: .white, texture: .init(texture))
            material.blending = .transparent(opacity: 1.0)
            material.faceCulling = .none

            let aspect = Float(image.size.height / image.size.width)
            let mesh = MeshResource.generatePlane(
                width: AnnotationMarkerLayout.width,
                height: AnnotationMarkerLayout.width * aspect
            )
            let marker = ModelEntity(mesh: mesh, materials: [material])
            marker.name = entityName
            marker.generateCollisionShapes(recursive: false)
            return marker
        } catch {
            print("[AnnotationMarker] Gagal membuat tekstur: \(error.localizedDescription)")
            return nil
        }
    }

    static func makeTapZone() -> ModelEntity {
        let zone = ModelEntity(
            mesh: .generateSphere(radius: AnnotationMarkerLayout.tapZoneRadius),
            materials: [UnlitMaterial(color: .clear)]
        )
        zone.name = tapZoneName
        zone.generateCollisionShapes(recursive: false)
        zone.components.remove(ModelComponent.self)
        return zone
    }

    static func isTappable(_ entity: Entity) -> Bool {
        var current: Entity? = entity
        while let node = current {
            if node.name == entityName
                || node.name == tapZoneName
                || node.name == SensorAsset.rootName {
                return true
            }
            current = node.parent
        }
        return false
    }

    private static let canvasWidth: CGFloat = 402
    private static let bodyHeight: CGFloat = 100
    private static let tailHeight: CGFloat = 37
    private static let tailHalfWidth: CGFloat = 26
    private static let cornerRadius: CGFloat = 26

    private static func render() -> UIImage? {
        let size = CGSize(width: canvasWidth, height: bodyHeight + tailHeight)

        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let w = canvasWidth
            let h = bodyHeight
            let r = min(cornerRadius, min(w, h) / 2)

            let tipX = w / 2
            let tipY = h + tailHeight
            let baseLeft = tipX - tailHalfWidth
            let baseRight = tipX + tailHalfWidth

            let bubble = UIBezierPath()
            bubble.move(to: CGPoint(x: r, y: 0))
            bubble.addLine(to: CGPoint(x: w - r, y: 0))
            bubble.addArc(
                withCenter: CGPoint(x: w - r, y: r), radius: r,
                startAngle: -.pi / 2, endAngle: 0, clockwise: true
            )
            bubble.addLine(to: CGPoint(x: w, y: h - r))
            bubble.addArc(
                withCenter: CGPoint(x: w - r, y: h - r), radius: r,
                startAngle: 0, endAngle: .pi / 2, clockwise: true
            )
            bubble.addLine(to: CGPoint(x: baseRight, y: h))
            bubble.addLine(to: CGPoint(x: tipX, y: tipY))
            bubble.addLine(to: CGPoint(x: baseLeft, y: h))
            bubble.addLine(to: CGPoint(x: r, y: h))
            bubble.addArc(
                withCenter: CGPoint(x: r, y: h - r), radius: r,
                startAngle: .pi / 2, endAngle: .pi, clockwise: true
            )
            bubble.addLine(to: CGPoint(x: 0, y: r))
            bubble.addArc(
                withCenter: CGPoint(x: r, y: r), radius: r,
                startAngle: .pi, endAngle: 3 * .pi / 2, clockwise: true
            )
            bubble.close()

            context.cgContext.setShadow(
                offset: CGSize(width: 0, height: 4),
                blur: 14,
                color: UIColor.black.withAlphaComponent(0.25).cgColor
            )
            UIColor(red: 0xF7 / 255, green: 0xF4 / 255, blue: 0xEE / 255, alpha: 1).setFill()
            bubble.fill()
            context.cgContext.setShadow(offset: .zero, blur: 0, color: nil)

            let text = "?" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 58, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            let textSize = text.size(withAttributes: attributes)
            text.draw(
                at: CGPoint(
                    x: w / 2 - textSize.width / 2,
                    y: h / 2 - textSize.height / 2
                ),
                withAttributes: attributes
            )
        }
    }
}
