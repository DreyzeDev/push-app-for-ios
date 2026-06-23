//
//  GeneratedAvatarView.swift
//  PushApp
//
//  Процедурный чёрно-белый аватар («ИИ»-стиль): рисуется детерминированно
//  по seed, поэтому один и тот же seed всегда даёт один и тот же узор.
//  Реальный нейросетевой генератор можно подключить позже — интерфейс тот же.
//

import SwiftUI

struct GeneratedAvatarView: View {
    let avatar: Avatar?
    var fallbackInitial: String = "?"
    var size: CGFloat = 96

    var body: some View {
        ZStack {
            Circle().fill(Theme.surfaceElevated)
            Circle().stroke(Theme.stroke, lineWidth: 1)

            if let avatar {
                pattern(for: avatar)
                    .clipShape(Circle())
                    .padding(size * 0.14)
            } else {
                Text(fallbackInitial.uppercased())
                    .font(.system(size: size * 0.42, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.primaryText)
            }
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private func pattern(for avatar: Avatar) -> some View {
        var rng = SeededGenerator(seed: UInt64(bitPattern: Int64(avatar.seed)))
        switch avatar.style {
        case .rings:  RingsPattern(rng: &rng)
        case .grid:   GridPattern(rng: &rng)
        case .bars:   BarsPattern(rng: &rng)
        case .mono:   MonoPattern(seed: avatar.seed)
        }
    }
}

// MARK: - Узоры

private struct RingsPattern: View {
    let count: Int
    let widths: [CGFloat]
    init(rng: inout SeededGenerator) {
        count = Int.random(in: 3...5, using: &rng)
        widths = (0..<count).map { _ in CGFloat.random(in: 0.04...0.12, using: &rng) }
    }
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    Circle()
                        .stroke(shade(i), lineWidth: s * widths[i])
                        .padding(s * CGFloat(i) / CGFloat(count) * 0.42)
                }
            }
            .frame(width: s, height: s)
        }
    }
    private func shade(_ i: Int) -> Color { Color(white: i.isMultiple(of: 2) ? 1.0 : 0.45) }
}

private struct GridPattern: View {
    let cells: [Bool]
    let dim = 5
    init(rng: inout SeededGenerator) {
        // Симметричный по вертикали узор (как identicon).
        var grid = Array(repeating: false, count: 25)
        for r in 0..<5 {
            for c in 0..<3 {
                let on = Bool.random(using: &rng)
                grid[r * 5 + c] = on
                grid[r * 5 + (4 - c)] = on
            }
        }
        cells = grid
    }
    var body: some View {
        GeometryReader { geo in
            let cell = min(geo.size.width, geo.size.height) / CGFloat(dim)
            ForEach(0..<25, id: \.self) { i in
                if cells[i] {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: cell, height: cell)
                        .position(x: cell * (CGFloat(i % dim) + 0.5),
                                  y: cell * (CGFloat(i / dim) + 0.5))
                }
            }
        }
    }
}

private struct BarsPattern: View {
    let heights: [CGFloat]
    init(rng: inout SeededGenerator) {
        heights = (0..<6).map { _ in CGFloat.random(in: 0.2...1.0, using: &rng) }
    }
    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: geo.size.width * 0.03) {
                ForEach(0..<heights.count, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(white: i.isMultiple(of: 2) ? 1.0 : 0.55))
                        .frame(height: geo.size.height * heights[i])
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}

private struct MonoPattern: View {
    let seed: Int
    var body: some View {
        let symbols = ["bolt.fill", "flame.fill", "figure.strengthtraining.traditional",
                       "hexagon.fill", "triangle.fill", "diamond.fill"]
        Image(systemName: symbols[abs(seed) % symbols.count])
            .resizable()
            .scaledToFit()
            .foregroundStyle(Theme.primaryText)
    }
}

// MARK: - Детерминированный генератор случайных чисел

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        // SplitMix64
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
