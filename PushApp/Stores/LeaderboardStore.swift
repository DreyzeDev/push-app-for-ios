//
//  LeaderboardStore.swift
//  PushApp
//
//  Загружает и хранит таблицу лидеров.
//

import Foundation
import Combine

final class LeaderboardStore: ObservableObject {
    @Published private(set) var entries: [LeaderboardEntry] = []
    @Published var isLoading = false
    @Published var errorText: String?

    private let api = API.current

    /// Только активные сейчас участники.
    var activeEntries: [LeaderboardEntry] {
        entries.filter { $0.isActive }
    }

    @MainActor func refresh() async {
        isLoading = true
        errorText = nil
        defer { isLoading = false }
        do {
            entries = try await api.fetchLeaderboard()
        } catch {
            errorText = error.localizedDescription
        }
    }
}
