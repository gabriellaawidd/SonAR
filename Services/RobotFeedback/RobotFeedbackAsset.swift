//
//  RobotFeedbackAsset.swift
//  SonAR
//
//  Created by Tiffany Michelle on 12/08/26.
//

import Foundation
import RealityKit
import FeedbackRobot

enum RobotFeedbackAsset {

    static let sceneName = "Scene"
    static let robotName = "Robot"
    static let hintAnchorName = "HintAnchor"

    static let appearanceTimeline = "Appearance"
    static let disappearanceTimeline = "Disappearance"
    static let hoverTimeline = "HoverLoop"

    static let appearanceDuration: TimeInterval = 0.6
    static let disappearanceDuration: TimeInterval = 0.4

    private(set) static var lastLoadError: String?

    private static var template: Entity?

    @MainActor
    static func load() async -> Entity? {
        if let template {
            return template.clone(recursive: true)
        }

        do {
            let entity = try await Entity(named: sceneName, in: feedbackRobotBundle)
            template = entity
            lastLoadError = nil
            return entity.clone(recursive: true)
        } catch {
            let message = "Gagal memuat \(sceneName) dari package FeedbackRobot: "
                + error.localizedDescription
            print("[RobotFeedbackAsset] \(message)")
            lastLoadError = message
            return nil
        }
    }

    static func listAnimations(in entity: Entity, depth: Int = 0) {
        let pad = String(repeating: "  ", count: depth)
        let hasLibrary = entity.components.has(AnimationLibraryComponent.self)
        let available = entity.availableAnimations.compactMap { $0.name }
        if hasLibrary || !available.isEmpty {
            print("[RobotFeedbackAsset] \(pad)\(entity.name) punyaLibrary=\(hasLibrary) available=\(available)")
        }
        for child in entity.children {
            listAnimations(in: child, depth: depth + 1)
        }
    }

    static func animation(named name: String, in entity: Entity) -> AnimationResource? {
        if let library = entity.components[AnimationLibraryComponent.self],
           let animation = library.animations[name] {
            return animation
        }
        if let animation = entity.availableAnimations.first(where: { $0.name == name }) {
            return animation
        }
        for child in entity.children {
            if let animation = animation(named: name, in: child) {
                return animation
            }
        }
        return nil
    }
}
