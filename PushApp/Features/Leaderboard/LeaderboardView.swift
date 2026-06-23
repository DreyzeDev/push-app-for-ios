//
//  LeaderboardView.swift
//  PushApp
//
//  Таблица лидеров: вкладки «Активные» и «Все», сортировка по сумме отжиманий.
//

import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject private var leaderboard: LeaderboardStore
    @EnvironmentObject private var auth: AuthStore
    @State private var showActiveOnly = false

    private var entries: [LeaderboardEntry] {
        showActiveOnly ? leaderboard.activeEntries : leaderboard.entries
    }

    var body: some View {
        ZStack {
            ScreenBackground()

            VStack(spacing: 16) {
                picker

                if leaderboard.isLoading && entries.isEmpty {
                    Spacer(); ProgressView().tint(.white); Spacer()
                } else if entries.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .navigationTitle("Лидеры")
        .navigationBarTitleDisplayMode(.large)
        .task { await leaderboard.refresh() }
        .refreshable { await leaderboard.refresh() }
    }

    private var picker: some View {
        Picker("", selection: $showActiveOnly) {
            Text("Все").tag(false)
            Text("Активные").tag(true)
        }
        .pickerStyle(.segmented)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    LeaderboardRow(
                        rank: index + 1,
                        entry: entry,
                        isCurrentUser: entry.id == auth.currentUser?.id
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "trophy")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Theme.secondaryText)
            Text(showActiveOnly ? "Сейчас никто не тренируется" : "Пока никого нет")
                .font(Theme.body(15))
                .foregroundStyle(Theme.secondaryText)
            Spacer()
        }
    }
}

// MARK: - Строка таблицы

private struct LeaderboardRow: View {
    let rank: Int
    let entry: LeaderboardEntry
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text("\(rank)")
                .font(Theme.display(rank <= 3 ? 26 : 20))
                .foregroundStyle(rank <= 3 ? Theme.primaryText : Theme.secondaryText)
                .frame(width: 36, alignment: .center)

            GeneratedAvatarView(avatar: entry.avatar, fallbackInitial: String(entry.nickname.prefix(1)), size: 46)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.nickname)
                        .font(Theme.title(17))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                    if isCurrentUser {
                        Text("ВЫ")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Theme.accent, in: Capsule())
                    }
                }
                if entry.isActive {
                    Label("активен", systemImage: "circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.secondaryText)
                        .labelStyle(ActiveDotLabelStyle())
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.totalPushups)")
                    .font(Theme.display(22))
                    .foregroundStyle(Theme.primaryText)
                Text("отжиманий")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(14)
        .background(isCurrentUser ? Theme.surfaceElevated : Theme.surface,
                    in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isCurrentUser ? Theme.accent.opacity(0.6) : Theme.stroke, lineWidth: 1)
        )
    }
}

private struct ActiveDotLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 5) {
            configuration.icon.font(.system(size: 7))
            configuration.title
        }
    }
}
