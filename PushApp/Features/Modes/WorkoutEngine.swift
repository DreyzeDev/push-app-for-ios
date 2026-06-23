//
//  WorkoutEngine.swift
//  PushApp
//
//  Управляет ходом тренировки: подходы, счёт отжиманий в подходе,
//  отдых 30 секунд между подходами и завершение.
//

import Foundation
import SwiftUI
import Combine

struct WorkoutConfig {
    let repsPerSet: Int
    let sets: Int
}

final class WorkoutEngine: ObservableObject {
    enum Phase: Equatable {
        case ready          // приготовиться, счёт ещё не идёт
        case active         // идёт подход, отжимания считаются
        case resting        // отдых между подходами
        case finished       // тренировка завершена
    }

    @Published private(set) var phase: Phase = .ready
    @Published private(set) var currentSet = 1
    @Published private(set) var repsInSet = 0
    @Published private(set) var totalReps = 0
    @Published private(set) var bestSet = 0
    @Published private(set) var restRemaining = AppConfig.restSeconds

    let config: WorkoutConfig
    private var timer: Timer?

    init(config: WorkoutConfig) {
        self.config = config
    }

    var isCounting: Bool { phase == .active }

    var progressInSet: Double {
        guard config.repsPerSet > 0 else { return 0 }
        return Double(repsInSet) / Double(config.repsPerSet)
    }

    // MARK: - Управление

    /// Начать текущий подход (из состояния готовности).
    func beginSet() {
        guard phase == .ready else { return }
        phase = .active
    }

    /// Засчитать одно отжимание (вызывает камера).
    func registerRep() {
        guard phase == .active else { return }
        repsInSet += 1
        totalReps += 1
        if repsInSet >= config.repsPerSet {
            completeSet()
        }
    }

    private func completeSet() {
        bestSet = max(bestSet, repsInSet)
        if currentSet >= config.sets {
            finish()
        } else {
            startRest()
        }
    }

    private func startRest() {
        phase = .resting
        restRemaining = AppConfig.restSeconds
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tickRest()
        }
    }

    private func tickRest() {
        restRemaining -= 1
        if restRemaining <= 0 {
            advanceToNextSet()
        }
    }

    /// Пропустить отдых и сразу перейти к следующему подходу.
    func skipRest() {
        guard phase == .resting else { return }
        advanceToNextSet()
    }

    private func advanceToNextSet() {
        timer?.invalidate()
        timer = nil
        currentSet += 1
        repsInSet = 0
        phase = .ready
    }

    private func finish() {
        timer?.invalidate()
        timer = nil
        phase = .finished
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
    }

    /// Итоговый результат для сохранения в профиль/лидерборд.
    func makeResult() -> WorkoutResult {
        WorkoutResult(
            repsPerSet: config.repsPerSet,
            sets: config.sets,
            completedReps: totalReps,
            bestSet: bestSet
        )
    }
}
