//
//  RootView.swift
//  PushApp
//
//  Корневой контейнер с навигацией. Стартовый экран — главное меню
//  с тремя кнопками: Режимы, Лидеры, Профиль.
//

import SwiftUI

enum AppRoute: Hashable {
    case modes
    case leaderboard
    case profile
}

struct RootView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            MainMenuView(path: $path)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .modes:       ModesView()
                    case .leaderboard: LeaderboardView()
                    case .profile:     ProfileView()
                    }
                }
        }
    }
}
