//
//  APIService.swift
//  PushApp
//
//  Абстракция над бэкендом. Сейчас используется MockAPIService (всё локально).
//  Когда подключим твой сервер — просто вернём RemoteAPIService в `current`.
//

import Foundation

enum APIError: LocalizedError {
    case invalidCode
    case userExists
    case userNotFound
    case wrongPassword
    case network(String)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidCode:   return "Неверный или просроченный код"
        case .userExists:    return "Пользователь с такой почтой уже есть"
        case .userNotFound:  return "Пользователь не найден"
        case .wrongPassword: return "Неверный пароль"
        case .network(let m): return "Ошибка сети: \(m)"
        case .server(let m):  return m
        }
    }
}

protocol APIService {
    /// Запросить код подтверждения на почту.
    func requestEmailCode(email: String) async throws -> CodeRequestResult
    /// Проверить введённый код.
    func verifyEmailCode(email: String, code: String) async throws
    /// Завершить регистрацию.
    func register(_ request: RegistrationRequest) async throws -> User
    /// Войти по почте и паролю.
    func login(email: String, password: String) async throws -> User
    /// Получить таблицу лидеров.
    func fetchLeaderboard() async throws -> [LeaderboardEntry]
    /// Отправить результат тренировки на сервер.
    func submitWorkout(_ result: WorkoutResult, for user: User) async throws -> User
}

/// Единая точка доступа к API во всём приложении.
enum API {
    static let current: APIService = AppConfig.useMockBackend
        ? (MockAPIService.shared as APIService)
        : (RemoteAPIService(baseURL: AppConfig.apiBaseURL) as APIService)
}
