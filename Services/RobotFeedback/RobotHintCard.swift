//
//  RobotHintCard.swift
//  SonAR
//
//  Created by Tiffany Michelle on 12/08/26.
//

import RealityKit
import UIKit

enum RobotHintCard {

    private static let background = UIColor(red: 0xF7 / 255, green: 0xF4 / 255, blue: 0xEE / 255, alpha: 1)
    private static let badgeText = UIColor.white
    private static let bodyText = UIColor.black

    private static let canvasWidth: CGFloat = 900
    private static let horizontalPadding: CGFloat = 56
    private static let verticalPadding: CGFloat = 52
    private static let cornerRadius: CGFloat = 56

    private static let badgeFontSize: CGFloat = 44
    private static let badgeHeight: CGFloat = 86
    private static let badgeHorizontalPadding: CGFloat = 44
    private static let badgeSpacing: CGFloat = 34

    private static let messageFontSize: CGFloat = 46
    private static let distanceFontSize: CGFloat = 38
    private static let distanceSpacing: CGFloat = 26
    private static let distanceColor = UIColor(white: 0.28, alpha: 1)

    static func makeEntity(for presentation: FeedbackPresentation, width: Float) -> ModelEntity? {
        guard let image = render(presentation), let cgImage = image.cgImage else { return nil }

        let aspect = Float(image.size.height / image.size.width)
        let height = width * aspect

        do {
            let texture = try TextureResource.generate(
                from: cgImage,
                withName: nil,
                options: .init(semantic: .color)
            )

            var material = UnlitMaterial()
            material.color = .init(tint: .white, texture: .init(texture))
            material.blending = .transparent(opacity: 1.0)
            material.faceCulling = .none

            let mesh = MeshResource.generatePlane(width: width, height: height)
            let card = ModelEntity(mesh: mesh, materials: [material])
            card.name = "robotHintCard"
            return card
        } catch {
            print("[RobotHintCard] Gagal membuat tekstur: \(error.localizedDescription)")
            return nil
        }
    }

    private static func render(_ presentation: FeedbackPresentation) -> UIImage? {
        let badgeFont = UIFont.systemFont(ofSize: badgeFontSize, weight: .bold)
        let messageFont = UIFont.systemFont(ofSize: messageFontSize, weight: .bold)
        let distanceFont = UIFont.systemFont(ofSize: distanceFontSize, weight: .regular)
        let textWidth = canvasWidth - horizontalPadding * 2

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineHeightMultiple = 1.1

        let messageAttributes: [NSAttributedString.Key: Any] = [
            .font: messageFont,
            .foregroundColor: bodyText,
            .paragraphStyle: paragraph
        ]
        let distanceAttributes: [NSAttributedString.Key: Any] = [
            .font: distanceFont,
            .foregroundColor: distanceColor,
            .paragraphStyle: paragraph
        ]

        let messageHeight = measure(presentation.message, attributes: messageAttributes, width: textWidth)
        let distanceHeight = measure(presentation.distanceText, attributes: distanceAttributes, width: textWidth)

        let canvasHeight = ceil(
            verticalPadding * 2
            + badgeHeight + badgeSpacing
            + messageHeight + distanceSpacing
            + distanceHeight
        )
        let size = CGSize(width: canvasWidth, height: canvasHeight)

        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            let cardRect = CGRect(origin: .zero, size: size)
            background.setFill()
            UIBezierPath(roundedRect: cardRect, cornerRadius: cornerRadius).fill()

            var cursorY = verticalPadding

            let badgeAttributes: [NSAttributedString.Key: Any] = [
                .font: badgeFont,
                .foregroundColor: badgeText
            ]
            let badgeSize = (presentation.badge as NSString).size(withAttributes: badgeAttributes)
            let badgeWidth = badgeSize.width + badgeHorizontalPadding * 2
            let badgeRect = CGRect(
                x: (canvasWidth - badgeWidth) / 2,
                y: cursorY,
                width: badgeWidth,
                height: badgeHeight
            )
            presentation.badgeColor.setFill()
            UIBezierPath(roundedRect: badgeRect, cornerRadius: badgeHeight / 2).fill()
            (presentation.badge as NSString).draw(
                at: CGPoint(
                    x: badgeRect.midX - badgeSize.width / 2,
                    y: badgeRect.midY - badgeSize.height / 2
                ),
                withAttributes: badgeAttributes
            )
            cursorY += badgeHeight + badgeSpacing

            (presentation.message as NSString).draw(
                with: CGRect(x: horizontalPadding, y: cursorY, width: textWidth, height: messageHeight),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: messageAttributes,
                context: nil
            )
            cursorY += messageHeight + distanceSpacing

            (presentation.distanceText as NSString).draw(
                with: CGRect(x: horizontalPadding, y: cursorY, width: textWidth, height: distanceHeight),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: distanceAttributes,
                context: nil
            )
        }
    }

    private static func measure(
        _ text: String,
        attributes: [NSAttributedString.Key: Any],
        width: CGFloat
    ) -> CGFloat {
        let bounds = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        return ceil(bounds.height)
    }
}
