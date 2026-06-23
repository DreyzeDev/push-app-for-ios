//
//  MockAPIService.swift
//  PushApp
//
//  Локальная эмуляция бэкенда: коды подтверждения генерируются на устройстве,
//  пользователи и лидерборд хранятся в UserDefaults. Никакого сервера не требуется.
//  Идеально, чтобы собрать IPA и потестить весь флоу прямо сейчас.
//

import Foundation

actor MockAPIService: APIService {
    static let shared = MockAPIService()

    private var pendingCodes: [String: String] = [:]   // email -> код
    private var verified: Set<String> = []             // подтверждённые email
    private let store = LocalDB.shared

    // MARK: - Регистрация по почте

    func requestEmailCode(email: String) async throws -> CodeRequestResult {
        try await fakeLatency()
        let normalized = email.lowercased()
        if store.user(email: normalized) != nil {
            throw APIError.userExists
        }
        let code = String(format: "%06d", Int.random(in: 0...999_999))
        pendingCodes[normalized] = code
        // На реальном сервере devCode будет nil — здесь возвращаем код, чтобы показать в UI.
        return CodeRequestResult(devCode: code)
    }

    func verifyEmailCode(email: String, code: String) async throws {
        try await fakeLatency()
        let normalized = email.lowercased()
        guard pendingCodes[normalized] == code else {
            throw APIError.invalidCode
        }
        verified.insert(normalized)
    }

    func register(_ request: RegistrationRequest) async throws -> User {
        try await fakeLatency()
        let normalized = request.email.lowercased()
        guard verified.contains(normalized) else { throw APIError.invalidCode }
        guard store.user(email: normalized) == nil else { throw APIError.userExists }

        let user = User.newLocal(email: normalized, nickname: request.nickname, avatar: request.avatar)
        store.saveUser(user, password: request.password)
        pendingCodes[normalized] = nil
        verified.remove(normalized)
        return user
    }

    func login(email: String, password: String) async throws -> User {
        try await fakeLatency()
        let normalized = email.lowercased()
        guard let record = store.userRecord(email: normalized) else { throw APIError.userNotFound }
        guard record.password == password else { throw APIError.wrongPassword }
        return record.user
    }

    // MARK: - Лидерборд

    func fetchLeaderboard() async throws -> [LeaderboardEntry] {
        try await fakeLatency()
        var entries = store.allUsers().map {
            LeaderboardEntry(
                id: $0.id,
                nickname: $0.nickname,
                avatar: $0.avatar,
                totalPushups: $0.totalPushups,
                isActive: false
            )
        }
        entries.append(contentsOf: Self.demoEntries)
        return entries.sorted { $0.totalPushups > $1.totalPushups }
    }

    func submitWorkout(_ result: WorkoutResult, for user: User) async throws -> User {
        try await fakeLatency()
        var updated = user
        updated.totalPushups += result.completedReps
        updated.totalWorkouts += 1
        updated.bestSet = max(updated.bestSet, result.bestSet)
        store.updateUserStats(updated)
        store.saveWorkout(result, userId: user.id)
        return updated
    }

    // MARK: - Утилиты

    private func fakeLatency() async throws {
        try? await Task.sleep(nanoseconds: 350_000_000) // 0.35с — имитация сети
    }

    /// Несколько «ботов» для демонстрации таблицы лидеров.
    static let demoEntries: [LeaderboardEntry] = [
        .init(id: "bot-1", nickname: "ironwill",  avatar: Avatar(seed: 11, style: .rings), totalPushups: 4820, isActive: true),
        .init(id: "bot-2", nickname: "max_power", avatar: Avatar(seed: 27, style: .bars),  totalPushups: 3960, isActive: true),
        .init(id: "bot-3", nickname: "nina_fit",  avatar: Avatar(seed: 5,  style: .grid),  totalPushups: 3110, isActive: false),
        .init(id: "bot-4", nickname: "steel",     avatar: Avatar(seed: 81, style: .mono),  totalPushups: 2540, isActive: true),
        .init(id: "bot-5", nickname: "alex_d",    avatar: Avatar(seed: 42, style: .rings), totalPushups: 1870, isActive: false),
        .init(id: "bot-6", nickname: "kate",      avatar: Avatar(seed: 63, style: .grid),  totalPushups: 1290, isActive: true),
        .init(id: "bot-7", nickname: "newbie99",  avatar: nil,                              totalPushups: 540,  isActive: false)
    ]
}
