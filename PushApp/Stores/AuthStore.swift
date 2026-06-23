//
//  AuthStore.swift
//  PushApp
//
//  Состояние авторизации и профиля. Держит текущего пользователя,
//  ведёт регистрацию/вход и применяет результаты тренировок.
//

import Foundation
import SwiftUI
import Combine

final class AuthStore: ObservableObject {
    @Published private(set) var currentUser: User?
    @Published var isWorking = false

    private let api = API.current
    private let db = LocalDB.shared

    var isAuthenticated: Bool { currentUser != nil }

    init() {
        // Восстанавливаем сессию, если пользователь уже входил.
        currentUser = db.sessionUser()
    }

    // MARK: - Регистрация

    /// Шаг 1 — запросить код на почту. Возвращает демо-код (в реальном API будет nil).
    @MainActor func requestCode(email: String) async throws -> String? {
        try validateEmail(email)
        isWorking = true; defer { isWorking = false }
        let result = try await api.requestEmailCode(email: email)
        return result.devCode
    }

    /// Шаг 2 — проверить код.
    @MainActor func verifyCode(email: String, code: String) async throws {
        isWorking = true; defer { isWorking = false }
        try await api.verifyEmailCode(email: email, code: code)
    }

    /// Шаг 3 — завершить регистрацию.
    @MainActor func register(email: String, nickname: String, password: String, avatar: Avatar?) async throws {
        guard nickname.trimmingCharacters(in: .whitespaces).count >= 2 else {
            throw APIError.server("Ник должен быть не короче 2 символов")
        }
        guard password.count >= 4 else {
            throw APIError.server("Пароль должен быть не короче 4 символов")
        }
        isWorking = true; defer { isWorking = false }
        let request = RegistrationRequest(email: email, nickname: nickname, password: password, avatar: avatar)
        let user = try await api.register(request)
        setSession(user)
    }

    // MARK: - Вход

    @MainActor func login(email: String, password: String) async throws {
        try validateEmail(email)
        isWorking = true; defer { isWorking = false }
        let user = try await api.login(email: email, password: password)
        setSession(user)
    }

    func logout() {
        setSession(nil)
    }

    // MARK: - Профиль / кастомизация

    func updateProfile(nickname: String? = nil, motto: String? = nil, avatar: Avatar?? = nil) {
        guard var user = currentUser else { return }
        if let nickname { user.nickname = nickname }
        if let motto { user.motto = motto }
        if let avatar { user.avatar = avatar }
        currentUser = user
        // Сохраняем локально (пароль не меняем).
        if let record = db.userRecord(email: user.email) {
            db.saveUser(user, password: record.password)
        }
    }

    // MARK: - Результаты тренировок

    @MainActor func applyWorkout(_ result: WorkoutResult) async {
        guard let user = currentUser else { return }
        if let updated = try? await api.submitWorkout(result, for: user) {
            currentUser = updated
        }
    }

    func workoutHistory() -> [WorkoutResult] {
        guard let user = currentUser else { return [] }
        return db.workouts(userId: user.id)
    }

    // MARK: - Внутреннее

    private func setSession(_ user: User?) {
        currentUser = user
        db.saveSession(userId: user?.id)
    }

    private func validateEmail(_ email: String) throws {
        let pattern = #"^\S+@\S+\.\S+$"#
        guard email.range(of: pattern, options: .regularExpression) != nil else {
            throw APIError.server("Неверный формат почты")
        }
    }
}
