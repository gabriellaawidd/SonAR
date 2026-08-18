import RealityKit
import Combine
import UIKit
import simd

enum SensorAsset {

    static let fileName = "Sensor_Ultrasonik_3D"
    static let rootName = "ultrasonicSensor"
    static let realBoardWidth: Float = 0.045
    private static let widthIfUnitsApplied: Float = 0.354519
    private static let widthIfUnitsIgnored: Float = 35.4519
    static let facingCorrection = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))

    private(set) static var lastLoadError: String?

    private static var template: Entity?
    private static var isLoading = false
    private static var pending: [(Entity?) -> Void] = []
    private static var cancellable: AnyCancellable?

    static func load(completion: @escaping (Entity?) -> Void) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { load(completion: completion) }
            return
        }

        if let template {
            completion(template.clone(recursive: true))
            return
        }

        pending.append(completion)
        guard !isLoading else { return }
        isLoading = true

        guard let url = Bundle.main.url(forResource: fileName, withExtension: "usdz") else {
            failLoad("\(fileName).usdz tidak ada di bundle. "
                     + "Tambahkan lewat Build Phases > Copy Bundle Resources.")
            return
        }

        cancellable = Entity.loadAsync(contentsOf: url)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                if case .failure(let error) = result {
                    failLoad("Gagal mengurai \(fileName).usdz: \(error.localizedDescription)")
                }
            }, receiveValue: { entity in
                lastLoadError = nil
                finish(with: normalise(entity))
            })
    }

    private static func failLoad(_ message: String) {
        print("[SensorAsset] \(message)")
        lastLoadError = message
        finish(with: nil)
    }

    private static func finish(with entity: Entity?) {
        template = entity
        isLoading = false
        cancellable = nil

        let callbacks = pending
        pending.removeAll()
        callbacks.forEach { $0(entity?.clone(recursive: true)) }
    }

    private static func normalise(_ entity: Entity) -> Entity {
        let wrapper = Entity()
        wrapper.name = rootName

        let sizer = Entity()
        sizer.name = "sizer"
        sizer.addChild(entity)

        let rawWidth = probeWidth(sizer)

        let assumedRaw: Float
        let mode: String
        if rawWidth > 5 {
            assumedRaw = widthIfUnitsIgnored
            mode = "unit mentah"
        } else if rawWidth > 1e-4 {
            assumedRaw = max(rawWidth, 1e-4)
            mode = "terukur"
        } else {
            assumedRaw = widthIfUnitsApplied
            mode = "acuan file"
        }

        let scale = realBoardWidth / assumedRaw
        sizer.scale = SIMD3<Float>(repeating: scale)
        sizer.orientation = facingCorrection

        let scaledCentre = probeCentre(sizer)
        if scaledCentre.x.isFinite {
            entity.position -= scaledCentre / max(scale, 1e-6)
        }

        let finalWidth = probeWidth(sizer)
        print(String(format: "[SensorAsset] mentah %.4f (%@) -> skala %.5f -> akhir %.4f m",
                     rawWidth, mode, scale, finalWidth))

        if !finalWidth.isFinite || finalWidth > 0.09 || finalWidth < 0.005 {
            let corrective = realBoardWidth / max(finalWidth, 1e-5)
            sizer.scale *= SIMD3<Float>(repeating: corrective)
            print(String(format: "[SensorAsset] koreksi lanjutan x%.5f", corrective))
        }

        wrapper.addChild(sizer)
        return wrapper
    }


    private static func probeWidth(_ entity: Entity) -> Float {
        guard let box = meshBounds(of: entity) else {
            let visual = entity.visualBounds(relativeTo: nil).extents.x
            return visual.isFinite ? visual : 0
        }
        return box.extents.x
    }

    private static func probeCentre(_ entity: Entity) -> SIMD3<Float> {
        meshBounds(of: entity)?.center ?? entity.visualBounds(relativeTo: nil).center
    }

    private static func meshBounds(of entity: Entity) -> BoundingBox? {
        var minV = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
        var maxV = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)
        var found = false

        func walk(_ node: Entity, _ parent: simd_float4x4) {
            let world = parent * node.transform.matrix
            if let model = node.components[ModelComponent.self] as ModelComponent? {
                let box = model.mesh.bounds
                for xi in [box.min.x, box.max.x] {
                    for yi in [box.min.y, box.max.y] {
                        for zi in [box.min.z, box.max.z] {
                            let p = world * SIMD4<Float>(xi, yi, zi, 1)
                            minV = simd_min(minV, SIMD3<Float>(p.x, p.y, p.z))
                            maxV = simd_max(maxV, SIMD3<Float>(p.x, p.y, p.z))
                            found = true
                        }
                    }
                }
            }
            node.children.forEach { walk($0, world) }
        }

        walk(entity, matrix_identity_float4x4)
        return found ? BoundingBox(min: minV, max: maxV) : nil
    }

    // Below ~400 lumens the room is too dark to see the sensor by reflected light alone.
    private static let lowLightThreshold: Double = 400

    static func applyLowLightGlow(_ entity: Entity, ambientIntensity: Double) {
        let darkness = Float(max(0, min(1, (lowLightThreshold - ambientIntensity) / lowLightThreshold)))

        func walk(_ node: Entity) {
            if let model = node as? ModelEntity, model.model != nil {
                model.model?.materials = model.model!.materials.map { material in
                    guard var pbr = material as? PhysicallyBasedMaterial else { return material }
                    pbr.emissiveColor = .init(color: .white)
                    pbr.emissiveIntensity = darkness
                    return pbr
                }
            }
            node.children.forEach(walk)
        }
        walk(entity)
    }

    static func applyPreviewTint(_ entity: Entity, color: UIColor, alpha: CGFloat = 0.45) {
        var material = SimpleMaterial(color: color, isMetallic: false)
        material.color = .init(tint: color.withAlphaComponent(alpha))

        func walk(_ node: Entity) {
            if let model = node as? ModelEntity, model.model != nil {
                let count = max(model.model?.materials.count ?? 1, 1)
                model.model?.materials = Array(repeating: material, count: count)
            }
            node.children.forEach(walk)
        }
        walk(entity)
    }
}
