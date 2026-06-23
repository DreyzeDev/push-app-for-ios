//
//  PushupCounter.swift
//  PushApp
//
//  Логика подсчёта отжиманий по глубине опускания.
//  Глубина считается из угла в локте: руки выпрямлены ~160°+ (0%),
//  внизу ~85° (100%). Отжимание засчитывается, только если глубина
//  достигла порога (80%) и затем тело вернулось вверх.
//

import Foundation

final class PushupCounter {
    enum Phase { case up, down }

    private(set) var phase: Phase = .up
    private(set) var reps = 0
    private(set) var depthPercent: Double = 0   // сглаженное значение 0...100
    private(set) var reachedThreshold = false   // достиг ли порога в текущем спуске

    private let topAngle: Double = 160      // угол выпрямленной руки
    private let bottomAngle: Double = 85    // угол в нижней точке
    private let upThreshold: Double = 20    // ниже этого считаем, что вернулся вверх
    private let threshold = AppConfig.depthThreshold
    private var smoothed: Double = 0

    /// Обновляет состояние новым углом локтя. Возвращает true, если только что засчитано отжимание.
    @discardableResult
    func update(elbowAngle: Double) -> Bool {
        let raw = (topAngle - elbowAngle) / (topAngle - bottomAngle)
        let pct = min(max(raw, 0), 1) * 100
        // Экспоненциальное сглаживание, чтобы дрожание не сбивало счёт.
        smoothed = smoothed * 0.6 + pct * 0.4
        depthPercent = smoothed

        switch phase {
        case .up:
            if smoothed >= threshold {
                phase = .down
                reachedThreshold = true
            }
        case .down:
            if smoothed <= upThreshold {
                phase = .up
                if reachedThreshold {
                    reps += 1
                    reachedThreshold = false
                    return true
                }
            }
        }
        return false
    }

    func reset() {
        phase = .up
        reps = 0
        depthPercent = 0
        smoothed = 0
        reachedThreshold = false
    }
}
