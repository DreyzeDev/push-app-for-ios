//
//  Theme.swift
//  PushApp
//
//  Чёрно-белая минималистичная тема: чистый чёрный фон, белый текст,
//  тонкие серые разделители. Один акцент — белый.
//

import SwiftUI

enum Theme {
    // MARK: - Цвета
    static let background = Color.black
    static let surface = Color(white: 0.08)          // карточки/панели
    static let surfaceElevated = Color(white: 0.12)  // активные/выделенные
    static let stroke = Color(white: 0.22)           // тонкие границы
    static let primaryText = Color.white
    static let secondaryText = Color(white: 0.62)
    static let accent = Color.white
    static let danger = Color(white: 0.85)
    static let success = Color.white

    // MARK: - Геометрия
    static let cornerRadius: CGFloat = 18
    static let cardCornerRadius: CGFloat = 24
    static let spacing: CGFloat = 16

    // MARK: - Шрифты
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    static func title(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    static func mono(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }
}

// MARK: - Общий фон экрана
struct ScreenBackground: View {
    var body: some View {
        Theme.background
            .ignoresSafeArea()
            .overlay(
                // едва заметный градиент сверху, чтобы фон не был совсем плоским
                LinearGradient(
                    colors: [Color(white: 0.10), .black],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
            )
    }
}
