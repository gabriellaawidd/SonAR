//
//  CameraPreviewBackdrop.swift
//  SonAR
//
//  Created by Gabriella Angelina Widjaja on 17/08/26.
//

import SwiftUI
import AVFoundation

struct CameraPreviewBackdrop: UIViewRepresentable {
    func makeUIView(context: Context) -> CameraView {
        CameraView()
    }

    func updateUIView(_ uiView: CameraView, context: Context) {}

    final class CameraView: UIView {
        private let session = AVCaptureSession()
        private var previewLayer: AVCaptureVideoPreviewLayer?

        override init(frame: CGRect) {
            super.init(frame: frame)
            setupCamera()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupCamera() {
            session.sessionPreset = .high
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else { return }

            session.addInput(input)

            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            self.layer.addSublayer(layer)
            self.previewLayer = layer

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer?.frame = bounds
        }

        deinit {
            session.stopRunning()
        }
    }
}

#Preview("Camera Backdrop") {
    CameraPreviewBackdrop()
        .ignoresSafeArea()
}
