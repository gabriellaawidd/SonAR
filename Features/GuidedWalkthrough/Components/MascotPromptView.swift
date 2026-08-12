//
//  MascotPromptView.swift
//  SonAR
//
//  Created by Tiffany Michelle on 12/08/26.
//

import SwiftUI

struct MascotPromptView: View {
    let mascot: String
    let text: String
    var mascotHeight: CGFloat = 120

    var body: some View {
        HStack(alignment: .top, spacing: -8) {
            MascotImage(name: mascot, height: mascotHeight)

            SpeechBubbleView(text: text)
                .padding(.top, mascotHeight * 0.16)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.4).ignoresSafeArea()
        VStack(spacing: 28) {
            MascotPromptView(
                mascot: "mascot2",
                text: "Point at a flat surface and tap to place",
                mascotHeight: 120
            )
            MascotPromptView(
                mascot: "mascotTryAgain",
                text: "Ooh, too steep! The sound bounced away. Try a smaller tilt!",
                mascotHeight: 96
            )
        }
    }
}
