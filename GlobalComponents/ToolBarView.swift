//
//  NavBarView.swift
//  SonAR
//
//  Created by Tiffany Michelle on 13/08/26.
//

import SwiftUI

struct ToolBarView: View {
    var onHome: () -> Void
    var onHowItWorks: () -> Void

    var body: some View {
        HStack {
            CircleIconButton(
                systemName: "house.fill",
                accessibilityTitle: "Back to menu",
                action: onHome
            )

            Spacer()

            CircleIconButton(
                systemName: "questionmark",
                accessibilityTitle: "How it works",
                action: onHowItWorks
            )
        }
        .padding(.top, 8)
    }
}
