//
//  MaterialVisionClassifier.swift
//  SonAR
//
//  Created by Gabriella Angelina Widjaja on 08/08/26.
//

import Vision
import CoreVideo

struct MaterialClassificationResult {
    let category: MaterialCategory
    let topLabel: String?
    let confidence: Float
}

final class MaterialVisionClassifier {
    private let softLabels: Set<String>
    private let hardLabels: Set<String>
    private let visionQueue = DispatchQueue(label: "material-vision-classifier", qos: .userInitiated)

    init(lookupTable: MaterialLookupTable = MaterialLookupLoader.load()) {
        self.softLabels = Set(lookupTable.soft)
        self.hardLabels = Set(lookupTable.hard)
    }

    func classify(pixelBuffer: CVPixelBuffer, completion: @escaping (MaterialClassificationResult) -> Void) {
        visionQueue.async { [weak self] in
            guard let self = self else { return }
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

            let humanRequest = VNDetectHumanRectanglesRequest()
            do {
                try handler.perform([humanRequest])
                if let humanResults = humanRequest.results,
                   let topHuman = humanResults.first,
                   self.boundingBoxIsDominant(topHuman.boundingBox) {
                    self.finish(.init(category: .hard, topLabel: "person", confidence: Float(topHuman.confidence)), completion)
                    return
                }
            } catch {}

            let classifyRequest = VNClassifyImageRequest()
            do {
                try handler.perform([classifyRequest])
                guard let observations = classifyRequest.results,
                      let topResult = observations.first else {
                    self.finish(.init(category: .unknown, topLabel: nil, confidence: 0), completion)
                    return
                }
                let mapped = self.mapToCategory(label: topResult.identifier, confidence: topResult.confidence)
                self.finish(mapped, completion)
            } catch {
                self.finish(.init(category: .unknown, topLabel: nil, confidence: 0), completion)
            }
        }
    }

    private func boundingBoxIsDominant(_ box: CGRect) -> Bool {
        let area = box.width * box.height
        return Float(area) >= AppConfig.humanDominanceAreaThreshold
    }

    private func finish(_ result: MaterialClassificationResult, _ completion: @escaping (MaterialClassificationResult) -> Void) {
        DispatchQueue.main.async { completion(result) }
    }

    private func mapToCategory(label: String, confidence: VNConfidence) -> MaterialClassificationResult {
        let confidenceValue = Float(confidence)
        guard confidenceValue >= AppConfig.visionConfidenceThreshold else {
            return .init(category: .lowConfidence, topLabel: label, confidence: confidenceValue)
        }
        if softLabels.contains(label) {
            return .init(category: .soft, topLabel: label, confidence: confidenceValue)
        } else if hardLabels.contains(label) {
            return .init(category: .hard, topLabel: label, confidence: confidenceValue)
        } else {
            return .init(category: .unknown, topLabel: label, confidence: confidenceValue)
        }
    }
}
