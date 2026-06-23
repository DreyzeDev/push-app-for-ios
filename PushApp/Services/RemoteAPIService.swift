//
//  RemoteAPIService.swift
//  PushApp
//
//  Реальный клиент к серверу. Готов к работе — когда поднимешь API на своём
//  домене, поставь AppConfig.useMockBackend = false и пропиши apiBaseURL.
//
//  Ожидаемые эндпоинты (REST, JSON):
//    POST /auth/request-code   { email }                       -> 200
//    POST /auth/verify-code    { email, code }                 -> 200
//    POST /auth/register       { email, nickname, password, avatar } -> { user }
//    POST /auth/login          { email, password }             -> { user }
//    GET  /leaderboard                                         -> { entries: [...] }
//    POST /workouts            { result, userId }              -> { user }
//

import Foundation

struct RemoteAPIService: APIService {
    let baseURL: URL
    var session: URLSession = .shared

    private func makeRequest(_ path: String, method: String, body: Encodable? = nil) throws -> URLRequest {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            req.httpBody = try JSONEncoder.api.encode(AnyEncodable(body))
        }
        return req
    }

    private func send<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.network("нет ответа")
            }
            guard (200..<300).contains(http.statusCode) else {
                let message = String(data: data, encoding: .utf8) ?? "код \(http.statusCode)"
                throw APIError.server(message)
            }
            return try JSONDecoder.api.decode(T.self, from: data)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.network(error.localizedDescription)
        }
    }

    private func sendNoContent(_ request: URLRequest) async throws {
        _ = try await send(request, as: EmptyResponse.self)
    }

    // MARK: - APIService

    func requestEmailCode(email: String) async throws -> CodeRequestResult {
        let req = try makeRequest("auth/request-code", method: "POST", body: ["email": email])
        return try await send(req, as: CodeRequestResult.self)
    }

    func verifyEmailCode(email: String, code: String) async throws {
        let req = try makeRequest("auth/verify-code", method: "POST", body: ["email": email, "code": code])
        try await sendNoContent(req)
    }

    func register(_ request: RegistrationRequest) async throws -> User {
        let req = try makeRequest("auth/register", method: "POST", body: request)
        return try await send(req, as: UserResponse.self).user
    }

    func login(email: String, password: String) async throws -> User {
        let req = try makeRequest("auth/login", method: "POST", body: ["email": email, "password": password])
        return try await send(req, as: UserResponse.self).user
    }

    func fetchLeaderboard() async throws -> [LeaderboardEntry] {
        let req = try makeRequest("leaderboard", method: "GET")
        return try await send(req, as: LeaderboardResponse.self).entries
    }

    func submitWorkout(_ result: WorkoutResult, for user: User) async throws -> User {
        let req = try makeRequest("workouts", method: "POST", body: WorkoutSubmission(result: result, userId: user.id))
        return try await send(req, as: UserResponse.self).user
    }
}

// MARK: - Вспомогательные типы ответов/запросов

private struct UserResponse: Decodable { let user: User }
private struct LeaderboardResponse: Decodable { let entries: [LeaderboardEntry] }
private struct EmptyResponse: Decodable {}
private struct WorkoutSubmission: Encodable { let result: WorkoutResult; let userId: String }

/// Обёртка, чтобы кодировать `Encodable` без указания конкретного типа.
private struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    init(_ wrapped: Encodable) { encodeFunc = wrapped.encode }
    func encode(to encoder: Encoder) throws { try encodeFunc(encoder) }
}

extension JSONEncoder {
    static var api: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }
}

extension JSONDecoder {
    static var api: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}
