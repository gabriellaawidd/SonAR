//
//  StepRowView.swift
//  SonAR
//
//  Created by Gabriella Angelina Widjaja on 12/08/26.
//

import SwiftUI

struct StepRowView: View {
    var number: String
    var text: String
    var imageName: String?
    
    var body: some View {
        HStack(spacing: 16) {
            Text(number)
                .font(.subheadline)
                .bold()
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.black))
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
            
            if let img = imageName {
                Spacer()
                
                Image(img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
            }
        }
    }
}

#Preview {
    StepRowView(
        number: "1",
        text: "The sensor transmitter shoots an invisible sound wave.",
        imageName: "step1"
    )
    .padding()
}
