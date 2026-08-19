//
//  SpeechBubble.swift
//  SonAR
//
//  Created by Tiffany Michelle on 12/08/26.
//

import SwiftUI

enum AppPalette {

    static let card = Color("bgMain")
    static let cyan = Color("buttonCyan")
    static let ink = Color.black
    static let mutedInk = Color.black.opacity(0.55)

    static let buttonTealTop = Color(hex: 0x7CE8D7)
    static let buttonTealBottom = Color(hex: 0x1E8F95)

    static let statusGreen = Color(hex: 0x34C759)
    static let statusOrange = Color(hex: 0xFF8D28)
    static let statusRed = Color(hex: 0xFF383C)

    static let buttonTeal = LinearGradient(
        colors: [buttonTealTop, buttonTealBottom],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

struct SpeechBubble: Shape {
    var cornerRadius: CGFloat = 24
    var tailWidth: CGFloat = 12
    var tailHeight: CGFloat = 26

    var tailCenterFromTop: CGFloat = 42

    func path(in rect: CGRect) -> Path {
        let body = CGRect(
            x: rect.minX + tailWidth,
            y: rect.minY,
            width: max(rect.width - tailWidth, 0),
            height: rect.height
        )
        let radius = min(cornerRadius, min(body.width, body.height) / 2)

        let center = min(
            max(tailCenterFromTop, body.minY + radius + tailHeight / 2),
            body.maxY - radius - tailHeight / 2
        )
        let top = center - tailHeight / 2
        let bottom = center + tailHeight / 2

        var path = Path()
        path.move(to: CGPoint(x: body.minX + radius, y: body.minY))
        path.addLine(to: CGPoint(x: body.maxX - radius, y: body.minY))
        path.addArc(
            center: CGPoint(x: body.maxX - radius, y: body.minY + radius),
            radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false
        )
        path.addLine(to: CGPoint(x: body.maxX, y: body.maxY - radius))
        path.addArc(
            center: CGPoint(x: body.maxX - radius, y: body.maxY - radius),
            radius: radius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false
        )
        path.addLine(to: CGPoint(x: body.minX + radius, y: body.maxY))
        path.addArc(
            center: CGPoint(x: body.minX + radius, y: body.maxY - radius),
            radius: radius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false
        )

        path.addLine(to: CGPoint(x: body.minX, y: bottom))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: center - tailHeight * 0.12),
            control: CGPoint(x: body.minX - tailWidth * 0.35, y: bottom - tailHeight * 0.18)
        )
        path.addQuadCurve(
            to: CGPoint(x: body.minX, y: top),
            control: CGPoint(x: body.minX + tailWidth * 0.1, y: top + tailHeight * 0.1)
        )

        path.addLine(to: CGPoint(x: body.minX, y: body.minY + radius))
        path.addArc(
            center: CGPoint(x: body.minX + radius, y: body.minY + radius),
            radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

struct SpeechBubbleView: View {
    let text: String
    var maxWidth: CGFloat = 210

    private let tailWidth: CGFloat = 12

    var body: some View {
        Text(text)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(AppPalette.ink)
            .lineSpacing(3)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: maxWidth, alignment: .leading)
            .padding(.vertical, 16)
            .padding(.trailing, 18)
            .padding(.leading, 18 + tailWidth)
            .background(
                SpeechBubble(tailWidth: tailWidth)
                    .fill(AppPalette.card)
                    .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 6)
            )
            .accessibilityElement(children: .combine)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.4).ignoresSafeArea()
        VStack(spacing: 20) {
            SpeechBubbleView(text: "Point at a flat surface and tap to place")
            SpeechBubbleView(text: "Ooh, too steep! The sound bounced away. Try a smaller tilt!")
        }
    }
}
