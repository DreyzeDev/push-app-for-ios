//
//  WorkoutView.swift
//  PushApp
//
//  Экран тренировки: камера на весь экран, скелет поверх, шкала глубины
//  с порогом 80%, счётчик отжиманий, отдых между подходами и итог.
//

import SwiftUI
import UIKit

struct WorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var leaderboard: LeaderboardStore

    @StateObject private var engine: WorkoutEngine
    @StateObject private var camera = CameraManager()
    @State private var didSave = false

    init(config: WorkoutConfig) {
        _engine = StateObject(wrappedValue: WorkoutEngine(config: config))
    }

    var body: some View {
        ZStack {
            // Камера + скелет
            CameraPreviewView(session: camera.session)
                .ignoresSafeArea()
            PoseOverlayView(pose: camera.pose)
                .ignoresSafeArea()

            // Затемнение для читаемости интерфейса
            LinearGradient(colors: [.black.opacity(0.55), .clear, .black.opacity(0.55)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            content
        }
        .statusBarHidden(true)
        .onAppear { setup() }
        .onDisappear { teardown() }
        .onChange(of: engine.phase) { _, phase in syncCamera(for: phase) }
        .onChange(of: camera.repCount) { _, _ in engine.registerRep() }
    }

    // MARK: - Слои интерфейса

    @ViewBuilder
    private var content: some View {
        switch engine.phase {
        case .ready:
            activeHUD
            readyOverlay
        case .active:
            activeHUD
            if !camera.poseDetected { noBodyHint }
        case .resting:
            activeHUD.opacity(0.25)
            restOverlay
        case .finished:
            finishedOverlay
        }
    }

    // MARK: - HUD во время подхода

    private var activeHUD: some View {
        VStack {
            topBar
            Spacer()
            HStack(alignment: .bottom) {
                repCounter
                Spacer()
                DepthGauge(depth: camera.depthPercent, threshold: AppConfig.depthThreshold)
                    .frame(width: 64)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 30)
        }
    }

    private var topBar: some View {
        HStack {
            Button { teardown(); dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.4), in: Circle())
            }
            Spacer()
            VStack(spacing: 2) {
                Text("ПОДХОД \(engine.currentSet) / \(engine.config.sets)")
                    .font(Theme.body(13)).tracking(2)
                    .foregroundStyle(.white)
                Text("Всего: \(engine.totalReps)")
                    .font(Theme.body(12))
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            Button { camera.flipCamera() } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.4), in: Circle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private var repCounter: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(engine.repsInSet)")
                .font(Theme.display(96))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.snappy, value: engine.repsInSet)
            Text("из \(engine.config.repsPerSet)")
                .font(Theme.title(22))
                .foregroundStyle(.white.opacity(0.7))
        }
        .shadow(color: .black.opacity(0.6), radius: 6)
    }

    private var noBodyHint: some View {
        VStack {
            Spacer()
            Text("Встань так, чтобы тело было в кадре")
                .font(Theme.body(15))
                .foregroundStyle(.white)
                .padding(.horizontal, 18).padding(.vertical, 12)
                .background(.black.opacity(0.6), in: Capsule())
            Spacer().frame(height: 220)
        }
    }

    // MARK: - Готовность

    private var readyOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 22) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.white)
                Text("Прими упор лёжа")
                    .font(Theme.title(26)).foregroundStyle(.white)
                Text("Камера должна видеть руки, торс и ноги.\nОтжимание засчитывается при глубине ≥ 80%.")
                    .font(Theme.body(15))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 30)

                Label(camera.poseDetected ? "Тело в кадре" : "Ищу тело…",
                      systemImage: camera.poseDetected ? "checkmark.circle.fill" : "viewfinder")
                    .font(Theme.body(14))
                    .foregroundStyle(camera.poseDetected ? .white : .white.opacity(0.6))

                PrimaryButton(title: "Начать подход \(engine.currentSet)", systemImage: "play.fill") {
                    engine.beginSet()
                }
                .padding(.horizontal, 40)
            }
        }
    }

    // MARK: - Отдых

    private var restOverlay: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            VStack(spacing: 18) {
                Text("ОТДЫХ")
                    .font(Theme.body(15)).tracking(4)
                    .foregroundStyle(.white.opacity(0.7))
                Text("\(engine.restRemaining)")
                    .font(Theme.display(120))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: engine.restRemaining)
                Text("Дальше: подход \(engine.currentSet + 1) из \(engine.config.sets)")
                    .font(Theme.body(15))
                    .foregroundStyle(.white.opacity(0.8))
                OutlineButton(title: "Пропустить отдых", systemImage: "forward.fill") {
                    engine.skipRest()
                }
                .padding(.horizontal, 50)
                .tint(.white)
            }
        }
    }

    // MARK: - Итог

    private var finishedOverlay: some View {
        ZStack {
            ScreenBackground()
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 70, weight: .bold))
                    .foregroundStyle(.white)
                Text("Готово!")
                    .font(Theme.display(40)).foregroundStyle(.white)

                HStack(spacing: 14) {
                    statTile(value: "\(engine.totalReps)", label: "отжиманий")
                    statTile(value: "\(engine.config.sets)", label: "подходов")
                    statTile(value: "\(engine.bestSet)", label: "лучший сет")
                }
                Spacer()
                PrimaryButton(title: "Сохранить и выйти", systemImage: "checkmark") {
                    teardown(); dismiss()
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 30)
        }
        .task { await saveResultIfNeeded() }
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value).font(Theme.display(34)).foregroundStyle(.white)
            Text(label.uppercased()).font(Theme.body(11)).tracking(1.5).foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.stroke, lineWidth: 1))
    }

    // MARK: - Логика

    @MainActor private func setup() {
        UIApplication.shared.isIdleTimerDisabled = true
        camera.countingEnabled = false
        camera.start()
    }

    @MainActor private func teardown() {
        UIApplication.shared.isIdleTimerDisabled = false
        engine.cancel()
        camera.stop()
    }

    @MainActor private func syncCamera(for phase: WorkoutEngine.Phase) {
        switch phase {
        case .active:
            camera.countingEnabled = true
        case .ready, .resting:
            camera.countingEnabled = false
            camera.resetCounter()
        case .finished:
            camera.countingEnabled = false
            camera.stop()
        }
    }

    @MainActor private func saveResultIfNeeded() async {
        guard !didSave else { return }
        didSave = true
        await auth.applyWorkout(engine.makeResult())
        await leaderboard.refresh()
    }
}

// MARK: - Шкала глубины

struct DepthGauge: View {
    let depth: Double        // 0...100
    let threshold: Double    // 80

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let clamped = CGFloat(min(max(depth, 0), 100) / 100)
            let markerY = h * (1 - CGFloat(threshold / 100))
            let reached = depth >= threshold

            ZStack(alignment: .bottom) {
                // Фон шкалы
                RoundedRectangle(cornerRadius: 16)
                    .fill(.black.opacity(0.4))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.3), lineWidth: 1))

                // Заполнение снизу вверх
                RoundedRectangle(cornerRadius: 16)
                    .fill(reached ? Color.white : Color.white.opacity(0.65))
                    .frame(height: h * clamped)
                    .animation(.easeOut(duration: 0.12), value: clamped)

                // Текущий процент внизу шкалы
                Text("\(Int(depth))%")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(reached ? .black : .white)
                    .padding(.vertical, 3).padding(.horizontal, 6)
                    .background(reached ? Color.white : Color.black.opacity(0.4), in: Capsule())
                    .padding(.bottom, 8)
            }
            // Линия порога 80% и подпись поверх шкалы
            .overlay(alignment: .topLeading) {
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.white)
                        .frame(width: w, height: 2)
                    Text("80%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .background(.black.opacity(0.5), in: Capsule())
                        .offset(y: -12)
                }
                .offset(y: markerY)
            }
        }
        .frame(maxHeight: 260)
    }
}
