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
    var imageName: String
    
    var body: some View {
        HStack(spacing: 16) {
            Text(number)
                .font(.subheadline)
                .bold()
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.black))
            
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 60)
            
            Text(text)
                .font(.subheadline.bold())
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
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
