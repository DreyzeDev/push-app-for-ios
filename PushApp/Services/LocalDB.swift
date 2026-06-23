//
//  LocalDB.swift
//  PushApp
//
//  Простое локальное хранилище на UserDefaults (JSON).
//  Используется мок-бэкендом и для запоминания текущей сессии.
//
//  ВНИМАНИЕ: пароли хранятся в открытом виде — это только для локального демо.
//  На реальном сервере пароль никогда не хранится в приложении.
//

import Foundation

struct UserRecord: Codable {
    var user: User
    var password: String
}

final class LocalDB {
    static let shared = LocalDB()
    private let defaults = UserDefaults.standard

    private enum Key {
        static let users = "db.users"
        static let workouts = "db.workouts"
        static let session = "db.session.userId"
    }

    private var records: [UserRecord] {
        get { decode([UserRecord].self, Key.users) ?? [] }
        set { encode(newValue, Key.users) }
    }

    // MARK: - Пользователи

    func user(email: String) -> User? {
        records.first { $0.user.email == email.lowercased() }?.user
    }

    func userRecord(email: String) -> UserRecord? {
        records.first { $0.user.email == email.lowercased() }
    }

    func userById(_ id: String) -> User? {
        records.first { $0.user.id == id }?.user
    }

    func allUsers() -> [User] {
        records.map { $0.user }
    }

    func saveUser(_ user: User, password: String) {
        var all = records
        all.removeAll { $0.user.id == user.id || $0.user.email == user.email }
        all.append(UserRecord(user: user, password: password))
        records = all
    }

    func updateUserStats(_ user: User) {
        var all = records
        guard let idx = all.firstIndex(where: { $0.user.id == user.id }) else { return }
        all[idx].user = user
        records = all
    }

    // MARK: - Тренировки

    func saveWorkout(_ result: WorkoutResult, userId: String) {
        var all = decode([String: [WorkoutResult]].self, Key.workouts) ?? [:]
        all[userId, default: []].insert(result, at: 0)
        encode(all, Key.workouts)
    }

    func workouts(userId: String) -> [WorkoutResult] {
        (decode([String: [WorkoutResult]].self, Key.workouts) ?? [:])[userId] ?? []
    }

    // MARK: - Сессия

    func saveSession(userId: String?) {
        defaults.set(userId, forKey: Key.session)
    }

    func sessionUser() -> User? {
        guard let id = defaults.string(forKey: Key.session) else { return nil }
        return userById(id)
    }

    // MARK: - JSON helpers

    private func decode<T: Decodable>(_ type: T.Type, _ key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func encode<T: Encodable>(_ value: T, _ key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }
}
