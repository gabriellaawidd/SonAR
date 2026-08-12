//
//  CircleIconButton.swift
//  SonAR
//
//  Created by Tiffany Michelle on 12/08/26.
//

import SwiftUI

enum CircleIconStyle {
    case light
    case accent

    var background: Color {
        switch self {
        case .light: return Color.white.opacity(0.92)
        case .accent: return AppPalette.cyan
        }
    }

    var foreground: Color {
        switch self {
        case .light: return AppPalette.ink
        case .accent: return .white
        }
    }

    var shadow: Color {
        switch self {
        case .light: return .black.opacity(0.18)
        case .accent: return AppPalette.cyan.opacity(0.45)
        }
    }
}

struct CircleIconButton: View {
    let systemName: String
    var diameter: CGFloat = 44
    var style: CircleIconStyle = .light
    var accessibilityTitle: String = "Button"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: diameter * 0.42, weight: .semibold))
                .foregroundStyle(style.foreground)
                .frame(width: diameter, height: diameter)
                .background(Circle().fill(style.background))
                .shadow(color: style.shadow, radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityTitle)
    }
}
