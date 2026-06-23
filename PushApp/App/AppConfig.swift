//
//  AppConfig.swift
//  PushApp
//
//  Единая точка конфигурации. Когда будет готов твой сервер/домен —
//  ставим `useMockBackend = false` и прописываем `apiBaseURL`.
//  Больше нигде ничего менять не нужно: вся сеть идёт через APIService.
//

import Foundation

enum AppConfig {
    /// true  — всё работает локально (коды подтверждения и лидерборд эмулируются на устройстве).
    /// false — приложение ходит на реальный сервер через RemoteAPIService.
    static let useMockBackend = true

    /// Базовый адрес твоего будущего API. Пример: "https://api.pushapp.ru"
    static let apiBaseURL = URL(string: "https://api.example.com")!

    /// Сколько раз по умолчанию предлагаем сделать в подходе.
    static let defaultReps = 10

    /// Сколько подходов по умолчанию.
    static let defaultSets = 3

    /// Длительность отдыха между подходами, секунд.
    static let restSeconds = 30

    /// Порог глубины (в процентах), при котором отжимание засчитывается.
    static let depthThreshold: Double = 80
}
