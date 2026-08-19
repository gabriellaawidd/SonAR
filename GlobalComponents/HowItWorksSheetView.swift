//
//  HowItWorksSheetView.swift
//  SonAR
//
//  Created by Gabriella Angelina Widjaja on 12/08/26.
//

import SwiftUI

struct HowItWorksSheetView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Text("How it works?")
                    .font(.headline)
                    .bold()
                
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.body.bold())
                            .foregroundColor(.gray)
                            .padding(10)
                            .background(Circle().fill(Color.gray.opacity(0.2)))
                    }
                    Spacer()
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 20)
                        
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    StepRowView(
                        number: "1",
                        text: "The sensor transmitter shoots an invisible sound wave.",
                        imageName: "step1"
                    )
                    
                    StepRowView(
                        number: "2",
                        text: "The wave travels until it hits an object.",
                        imageName: "step2"
                    )
                    
                    StepRowView(
                        number: "3",
                        text: "The object bounces the sound back to the sensor receiver.",
                        imageName: "step3"
                    )
                    
                    StepRowView(
                        number: "4",
                        text: "The robot times the echo to calculate the exact distance.",
                        imageName: "step4"
                    )
                    
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    HowItWorksSheetView()
}
