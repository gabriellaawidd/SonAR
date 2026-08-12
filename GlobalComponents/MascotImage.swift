//
//  MascotImage.swift
//  SonAR
//
//  Created by Tiffany Michelle on 12/08/26.
//

import SwiftUI
import UIKit

enum MascotAsset {
    static let neutral = "mascot2"
    static let happy = "mascotGreat"
    static let sad = "mascotTryAgain"

    static func resolved(_ name: String) -> String {
        UIImage(named: name) != nil ? name : neutral
    }
}

struct MascotImage: View {
    let name: String
    var height: CGFloat

    var body: some View {
        Image(MascotAsset.resolved(name))
            .resizable()
            .scaledToFit()
            .frame(height: height)
    }
}
