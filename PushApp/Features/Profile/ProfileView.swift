//
//  ProfileView.swift
//  PushApp
//
//  Профиль пользователя. Без входа — приглашение зарегистрироваться/войти.
//  После входа — аватар, статистика, кастомизация и история тренировок.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var showAuth = false
    @State private var showEdit = false

    var body: some View {
        ZStack {
            ScreenBackground()
            if let user = auth.currentUser {
                authenticated(user)
            } else {
                guest
            }
        }
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAuth) { AuthFlowView() }
        .sheet(isPresented: $showEdit) { EditProfileView() }
    }

    // MARK: - Гость

    private var guest: some View {
        VStack(spacing: 22) {
            Spacer()
            GeneratedAvatarView(avatar: nil, fallbackInitial: "?", size: 110)
            Text("Войди в профиль")
                .font(Theme.title(24)).foregroundStyle(Theme.primaryText)
            Text("Регистрация по почте — на неё придёт код подтверждения. После входа результаты попадают в таблицу лидеров.")
                .font(Theme.body(15))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.secondaryText)
                .padding(.horizontal, 30)
            Spacer()
            PrimaryButton(title: "Регистрация / Вход", systemImage: "person.fill") {
                showAuth = true
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 20)
    }

    // MARK: - Авторизован

    private func authenticated(_ user: User) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                header(user)
                statsCard(user)
                customizationCard
                historySection
                Button(role: .destructive) {
                    auth.logout()
                } label: {
                    Text("Выйти из аккаунта")
                        .font(Theme.body(15))
                        .foregroundStyle(Theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .padding(.top, 4)
            }
            .padding(20)
        }
    }

    private func header(_ user: User) -> some View {
        VStack(spacing: 12) {
            GeneratedAvatarView(avatar: user.avatar, fallbackInitial: String(user.nickname.prefix(1)), size: 120)
            Text(user.nickname)
                .font(Theme.display(30)).foregroundStyle(Theme.primaryText)
            Text(user.motto)
                .font(Theme.body(14)).foregroundStyle(Theme.secondaryText)
            Text(user.email)
                .font(Theme.body(12)).foregroundStyle(Theme.secondaryText.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private func statsCard(_ user: User) -> some View {
        Card {
            VStack(spacing: 16) {
                SectionHeader(title: "Статистика")
                HStack {
                    stat(value: "\(user.totalPushups)", label: "всего")
                    Divider().frame(height: 40).overlay(Theme.stroke)
                    stat(value: "\(user.totalWorkouts)", label: "тренировок")
                    Divider().frame(height: 40).overlay(Theme.stroke)
                    stat(value: "\(user.bestSet)", label: "лучший сет")
                }
            }
        }
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(Theme.display(28)).foregroundStyle(Theme.primaryText)
            Text(label.uppercased()).font(Theme.body(11)).tracking(1.5).foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var customizationCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Кастомизация")
                Text("Меняй ник, подпись и аватар в любой момент.")
                    .font(Theme.body(14)).foregroundStyle(Theme.secondaryText)
                OutlineButton(title: "Редактировать профиль", systemImage: "slider.horizontal.3") {
                    showEdit = true
                }
            }
        }
    }

    @ViewBuilder
    private var historySection: some View {
        let history = auth.workoutHistory()
        if !history.isEmpty {
            Card {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "История")
                    ForEach(history.prefix(8)) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(item.completedReps) отжиманий")
                                    .font(Theme.title(16)).foregroundStyle(Theme.primaryText)
                                Text("\(item.sets)×\(item.repsPerSet) · лучший \(item.bestSet)")
                                    .font(Theme.body(12)).foregroundStyle(Theme.secondaryText)
                            }
                            Spacer()
                            Text(item.date, format: .dateTime.day().month().hour().minute())
                                .font(Theme.body(12)).foregroundStyle(Theme.secondaryText)
                        }
                        if item.id != history.prefix(8).last?.id {
                            Divider().overlay(Theme.stroke)
                        }
                    }
                }
            }
        }
    }
}
