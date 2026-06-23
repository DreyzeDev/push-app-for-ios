//
//  MainMenuView.swift
//  PushApp
//
//  Главное меню: логотип и три крупные кнопки.
//

import SwiftUI

struct MainMenuView: View {
    @Binding var path: NavigationPath
    @EnvironmentObject private var auth: AuthStore

    var body: some View {
        ZStack {
            ScreenBackground()

            VStack(spacing: 28) {
                Spacer(minLength: 20)
                header
                Spacer(minLength: 10)

                VStack(spacing: 16) {
                    MenuButton(
                        title: "Режимы",
                        subtitle: "Тренировка отжиманий",
                        systemImage: "figure.strengthtraining.traditional"
                    ) { path.append(AppRoute.modes) }

                    MenuButton(
                        title: "Лидеры",
                        subtitle: "Кто отжался больше всех",
                        systemImage: "trophy.fill"
                    ) { path.append(AppRoute.leaderboard) }

                    MenuButton(
                        title: "Профиль",
                        subtitle: auth.isAuthenticated ? (auth.currentUser?.nickname ?? "") : "Вход и регистрация",
                        systemImage: "person.fill"
                    ) { path.append(AppRoute.profile) }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Theme.stroke, lineWidth: 2)
                    .frame(width: 96, height: 96)
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(Theme.primaryText)
            }
            Text("PUSH")
                .font(Theme.display(54))
                .tracking(6)
                .foregroundStyle(Theme.primaryText)
            Text("Считай отжимания по-настоящему")
                .font(Theme.body(15))
                .foregroundStyle(Theme.secondaryText)
        }
    }
}

// MARK: - Кнопка меню

private struct MenuButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Theme.primaryText)
                    .frame(width: 56, height: 56)
                    .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Theme.title(22))
                        .foregroundStyle(Theme.primaryText)
                    Text(subtitle)
                        .font(Theme.body(14))
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(18)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
        }
    }
}
