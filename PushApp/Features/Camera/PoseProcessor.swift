//
//  PoseProcessor.swift
//  PushApp
//
//  Обёртка над Vision: распознаёт позу тела на кадре, извлекает суставы
//  (руки, торс, ноги, голова) и считает угол в локте для подсчёта глубины.
//

import Foundation
import Vision
import CoreGraphics
import ImageIO

/// Сустав в нашей системе координат (не зависит от внутренних имён Vision).
enum BodyJoint: String, CaseIterable {
    case nose
    case neck
    case leftShoulder, rightShoulder
    case leftElbow, rightElbow
    case leftWrist, rightWrist
    case leftHip, rightHip
    case leftKnee, rightKnee
    case leftAnkle, rightAnkle

    var vnName: VNHumanBodyPoseObservation.JointName {
        switch self {
        case .nose: return .nose
        case .neck: return .neck
        case .leftShoulder: return .leftShoulder
        case .rightShoulder: return .rightShoulder
        case .leftElbow: return .leftElbow
        case .rightElbow: return .rightElbow
        case .leftWrist: return .leftWrist
        case .rightWrist: return .rightWrist
        case .leftHip: return .leftHip
        case .rightHip: return .rightHip
        case .leftKnee: return .leftKnee
        case .rightKnee: return .rightKnee
        case .leftAnkle: return .leftAnkle
        case .rightAnkle: return .rightAnkle
        }
    }
}

/// Кости скелета — пары суставов, которые соединяем линиями в оверлее.
let skeletonBones: [(BodyJoint, BodyJoint)] = [
    (.nose, .neck),
    (.neck, .leftShoulder), (.neck, .rightShoulder),
    (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
    (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
    (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
    (.leftHip, .rightHip),
    (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
    (.rightHip, .rightKnee), (.rightKnee, .rightAnkle)
]

/// Результат распознавания одного кадра.
struct PoseResult {
    /// Точки в UI-координатах: (0,0) — левый верх, (1,1) — правый низ.
    var points: [BodyJoint: CGPoint]
    /// Угол в локте (среднее по доступным рукам), если удалось вычислить.
    var elbowAngle: Double?
}

final class PoseProcessor {
    private let request = VNDetectHumanBodyPoseRequest()
    private let minConfidence: Float = 0.2

    func process(pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation, mirror: Bool) -> PoseResult? {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }
        guard let observation = request.results?.first else { return nil }

        var points: [BodyJoint: CGPoint] = [:]
        for joint in BodyJoint.allCases {
            guard let p = try? observation.recognizedPoint(joint.vnName), p.confidence > minConfidence else { continue }
            // Vision: origin внизу-слева. Переводим в UI: origin вверху-слева.
            var x = p.location.x
            let y = 1 - p.location.y
            if mirror { x = 1 - x }
            points[joint] = CGPoint(x: x, y: y)
        }

        let angle = averageElbowAngle(points)
        return PoseResult(points: points, elbowAngle: angle)
    }

    /// Среднее значение угла в локте по обеим рукам (по тем, что распознаны).
    private func averageElbowAngle(_ p: [BodyJoint: CGPoint]) -> Double? {
        var angles: [Double] = []
        if let s = p[.leftShoulder], let e = p[.leftElbow], let w = p[.leftWrist] {
            angles.append(Self.angle(s, e, w))
        }
        if let s = p[.rightShoulder], let e = p[.rightElbow], let w = p[.rightWrist] {
            angles.append(Self.angle(s, e, w))
        }
        guard !angles.isEmpty else { return nil }
        return angles.reduce(0, +) / Double(angles.count)
    }

    /// Угол в точке b между лучами b→a и b→c, в градусах.
    static func angle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Double {
        let v1 = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let v2 = CGVector(dx: c.x - b.x, dy: c.y - b.y)
        let dot = v1.dx * v2.dx + v1.dy * v2.dy
        let m1 = hypot(v1.dx, v1.dy)
        let m2 = hypot(v2.dx, v2.dy)
        guard m1 > 0, m2 > 0 else { return 180 }
        let cosine = max(-1, min(1, dot / (m1 * m2)))
        return acos(cosine) * 180 / .pi
    }
}
