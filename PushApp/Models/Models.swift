//
//  Models.swift
//  PushApp
//
//  Доменные модели приложения: пользователь, результат тренировки,
//  запись в таблице лидеров и аватар.
//

import Foundation

// MARK: - Аватар

/// Аватар может быть процедурно сгенерированным («ИИ»-стиль) или отсутствовать.
/// Картинки не храним — храним только seed, по которому рисуем геометрический аватар.
struct Avatar: Codable, Equatable {
    var seed: Int
    var style: Style

    enum Style: String, Codable, CaseIterable, Identifiable {
        case rings = "Кольца"
        case grid = "Сетка"
        case bars = "Полосы"
        case mono = "Монограмма"

        var id: String { rawValue }
    }

    static func random() -> Avatar {
        Avatar(seed: Int.random(in: 0...1_000_000), style: Style.allCases.randomElement()!)
    }

    static let none = Avatar(seed: 0, style: .mono)
}

// MARK: - Пользователь

struct User: Codable, Identifiable, Equatable {
    var id: String
    var email: String
    var nickname: String
    var avatar: Avatar?
    var motto: String          // короткая подпись профиля (кастомизация)
    var totalPushups: Int
    var totalWorkouts: Int
    var bestSet: Int           // лучший результат за один подход
    var createdAt: Date

    static func newLocal(email: String, nickname: String, avatar: Avatar?) -> User {
        User(
            id: UUID().uuidString,
            email: email,
            nickname: nickname,
            avatar: avatar,
            motto: "Каждый день — сильнее",
            totalPushups: 0,
            totalWorkouts: 0,
            bestSet: 0,
            createdAt: Date()
        )
    }
}

// MARK: - Результат тренировки

struct WorkoutResult: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var date: Date = Date()
    var repsPerSet: Int
    var sets: Int
    var completedReps: Int      // сколько фактически засчитано
    var bestSet: Int            // максимум за один подход в этой тренировке
}

// MARK: - Таблица лидеров

struct LeaderboardEntry: Codable, Identifiable, Equatable {
    var id: String
    var nickname: String
    var avatar: Avatar?
    var totalPushups: Int
    var isActive: Bool          // «активен» — онлайн / тренируется прямо сейчас
}

// MARK: - Запросы к API

struct RegistrationRequest: Codable {
    var email: String
    var nickname: String
    var password: String
    var avatar: Avatar?
}

struct CodeRequestResult: Codable {
    /// В демо-режиме сюда кладётся сгенерированный код, чтобы показать его на экране.
    /// На реальном сервере поле будет nil — код придёт на почту.
    var devCode: String?
}
