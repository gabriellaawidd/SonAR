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
                guard let observations = classifyRequest.results, !observations.isEmpty else {
                    self.finish(.init(category: .unknown, topLabel: nil, confidence: 0), completion)
                    return
                }
                let mapped = self.pickBestMatch(from: observations)
                print("[topResult confidence ]: \(mapped.confidence)")
                self.finish(mapped, completion)
            } catch {
                self.finish(.init(category: .unknown, topLabel: nil, confidence: 0), completion)
            }
            print("[classify request] : \(classifyRequest.results)")
        }
    }

    private func boundingBoxIsDominant(_ box: CGRect) -> Bool {
        let area = box.width * box.height
        return Float(area) >= AppConfig.humanDominanceAreaThreshold
    }

    private func finish(_ result: MaterialClassificationResult, _ completion: @escaping (MaterialClassificationResult) -> Void) {
        DispatchQueue.main.async {
            print("[Result Material Classification] \(result)")
            completion(result)
        }
    }

    /// Vision's top-1 guess is sometimes a generic label (e.g. "structure") that's in neither
    /// lookup table, while a specific soft/hard label sits a few ranks below it. Scan a few
    /// more candidates before giving up.
    private static let topNCandidates = 5

    private func pickBestMatch(from observations: [VNClassificationObservation]) -> MaterialClassificationResult {
        for candidate in observations.prefix(Self.topNCandidates) {
            let result = mapToCategory(label: candidate.identifier, confidence: candidate.confidence)
            if result.category == .soft || result.category == .hard {
                return result
            }
        }
        let top = observations[0]
        return mapToCategory(label: top.identifier, confidence: top.confidence)
    }

    private func mapToCategory(label: String, confidence: VNConfidence) -> MaterialClassificationResult {
        let confidenceValue = Float(confidence)
        print("[confidenceValue ] : \(confidenceValue)")
        print("[labelValue] : \(label)")
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
