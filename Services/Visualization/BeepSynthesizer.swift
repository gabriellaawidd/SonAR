import Foundation
import AVFoundation
import UIKit

class BeepSynthesizer {
    static let shared = BeepSynthesizer()
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    
    private var cachedBuffer: AVAudioPCMBuffer?
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium)

    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        try? engine.start()
        
        prepareBuffer()
    }
    
    private func prepareBuffer() {
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
            let envelope: Float
            if i < 100 {
                envelope = Float(i) / 100.0
            } else if i > Int(frameCount) - 100 {
                envelope = Float(Int(frameCount) - i) / 100.0
            } else {
                envelope = 1.0
            }
            
            for channel in 0..<channels {
                buffer.floatChannelData?[channel][i] = val * 0.5 * envelope
            }
        }
        self.cachedBuffer = buffer
    }

    func playLowBeep() {
        guard let buffer = cachedBuffer else { return }
        
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        player.play()
        
        DispatchQueue.main.async {
            self.hapticGenerator.prepare()
            self.hapticGenerator.impactOccurred()
        }
    }
}
