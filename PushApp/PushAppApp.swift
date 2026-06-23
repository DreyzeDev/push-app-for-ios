//
//  PushAppApp.swift
//  PushApp
//
//  Точка входа приложения. Здесь создаются глобальные хранилища
//  (авторизация, лидерборд) и задаётся тёмная чёрно-белая тема.
//

import SwiftUI

@main
struct PushAppApp: App {
    @StateObject private var auth = AuthStore()
    @StateObject private var leaderboard = LeaderboardStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(leaderboard)
                .preferredColorScheme(.dark) // приложение всегда в тёмном чёрно-белом стиле
                .tint(Theme.accent)
        }
    }
}
