import SwiftUI

struct SensorPlacementARView: View {
    @StateObject private var model = ARSessionModel()
    @Binding var appState: AppState

    var body: some View {
        ZStack {
            ARViewContainer(model: model)
                .ignoresSafeArea()

            VStack {
                if model.isLowLight {
                    HintPill(text: "Ruangan terlalu gelap · cari ruangan yang lebih terang")
                        .padding(.top, 16)
                        .transition(.opacity)
                }

                Spacer()

                if model.phase == .carrying, model.isAssetReady {
                    HintPill(text: "Ketuk untuk meletakkan sensor")
                        .padding(.bottom, 32)
                        .transition(.opacity)
                }

                if model.phase == .placed, let reading = model.surfaceReading {
                    HintPill(text: "\(reading.materialCategory.rawValue) · \(reading.angleCategory.rawValue)")
                        .padding(.bottom, 12)
                }

                if model.phase == .placed {
                    Button("Letakkan ulang") {
                        model.placeAgain()
                    }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(.white, in: Capsule())
                    .padding(.bottom, 32)
                    .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: model.phase)
        .animation(.easeInOut(duration: 0.2), value: model.isAssetReady)
        .animation(.easeInOut(duration: 0.2), value: model.isLowLight)
    }
}

private struct HintPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote.weight(.medium))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
    }
}
