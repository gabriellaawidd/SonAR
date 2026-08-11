import Foundation
import AVFoundation
import UIKit

class BeepSynthesizer {
    static let shared = BeepSynthesizer()
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        try? engine.start()
    }

    func playLowBeep() {
        let sampleRate = engine.mainMixerNode.outputFormat(forBus: 0).sampleRate
        let duration = 0.1
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        let format = player.outputFormat(forBus: 0)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        
        buffer.frameLength = frameCount
        let channels = Int(format.channelCount)
        let frequency: Float = 300.0 // Low pitch
        
        for i in 0..<Int(frameCount) {
            let val = sinf(2.0 * Float.pi * frequency * Float(i) / Float(sampleRate))
            // Apply a simple envelope to prevent clicking noises at the start/end
            let envelope: Float
            if i < 100 {
                envelope = Float(i) / 100.0
            } else if i > Int(frameCount) - 100 {
                envelope = Float(Int(frameCount) - i) / 100.0
            } else {
                envelope = 1.0
            }
            
            for channel in 0..<channels {
                buffer.floatChannelData?[channel][i] = val * 0.5 * envelope // 50% volume with envelope
            }
        }
        
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        player.play()
        
        DispatchQueue.main.async {
            let haptic = UIImpactFeedbackGenerator(style: .medium)
            haptic.impactOccurred()
        }
    }
}
