//
//  MenuCardView.swift
//  SonAR
//
//  Created by Gabriella Angelina Widjaja on 10/08/26.
//

import SwiftUI

struct MenuCardView: View {
    let title: String
    let subtitle: String
    let iconName: String
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3)
                        .bold()
                        .foregroundColor(accentColor)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(Color.black)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(Color("buttonCyan"))
                    .font(.title2)
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.black, lineWidth: 1)
            )
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        
        VStack(spacing: 20) {
            MenuCardView(
                title: "Free Roam Mode",
                subtitle: "Explore the room and see how the robot detects obstacles.",
                iconName: "quickTour",
                accentColor: .blue,
                action: {
                    print("Menu Card Tapped!")
                }
            )
            .padding()
        }
    }
}
