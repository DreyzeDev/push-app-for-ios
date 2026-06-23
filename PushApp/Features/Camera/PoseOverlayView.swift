//
//  PoseOverlayView.swift
//  PushApp
//
//  Рисует распознанный скелет (точки суставов и кости) поверх камеры.
//  Координаты приблизительные при режиме aspectFill — это визуальный слой,
//  на точность подсчёта он не влияет (счёт идёт по углам).
//

import SwiftUI

struct PoseOverlayView: View {
    let pose: PoseResult?

    var body: some View {
        GeometryReader { geo in
            if let pose {
                let size = geo.size
                ZStack {
                    // Кости
                    ForEach(Array(skeletonBones.enumerated()), id: \.offset) { _, bone in
                        if let a = pose.points[bone.0], let b = pose.points[bone.1] {
                            Path { path in
                                path.move(to: scaled(a, size))
                                path.addLine(to: scaled(b, size))
                            }
                            .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        }
                    }
                    // Суставы
                    ForEach(BodyJoint.allCases, id: \.self) { joint in
                        if let p = pose.points[joint] {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 9, height: 9)
                                .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                                .position(scaled(p, size))
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func scaled(_ p: CGPoint, _ size: CGSize) -> CGPoint {
        CGPoint(x: p.x * size.width, y: p.y * size.height)
    }
}
