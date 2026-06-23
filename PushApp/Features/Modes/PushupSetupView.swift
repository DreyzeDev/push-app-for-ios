//
//  PushupSetupView.swift
//  PushApp
//
//  Экран настройки тренировки: сколько отжиманий в подходе и сколько подходов.
//  Отсюда запрашивается камера и запускается тренировка.
//

import SwiftUI
import AVFoundation
import UIKit

struct PushupSetupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var reps = AppConfig.defaultReps
    @State private var sets = AppConfig.defaultSets
    @State private var startWorkout = false
    @State private var showCameraDeniedAlert = false

    var body: some View {
        ZStack {
            ScreenBackground()

            VStack(spacing: 20) {
                topBar

                ScrollView {
                    VStack(spacing: 18) {
                        CounterStepper(title: "Отжиманий в подходе", value: $reps, range: 1...100)
                        CounterStepper(title: "Подходов", value: $sets, range: 1...20)

                        summaryCard
                    }
                    .padding(.bottom, 20)
                }

                PrimaryButton(title: "Запросить камеру и начать", systemImage: "camera.fill") {
                    requestCameraAndStart()
                }
            }
            .padding(20)
        }
        .fullScreenCover(isPresented: $startWorkout) {
            WorkoutView(config: WorkoutConfig(repsPerSet: reps, sets: sets))
        }
        .alert("Нет доступа к камере", isPresented: $showCameraDeniedAlert) {
            Button("Открыть настройки") { openSettings() }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Чтобы считать отжимания, разреши доступ к камере в настройках.")
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.primaryText)
                    .frame(width: 44, height: 44)
                    .background(Theme.surface, in: Circle())
            }
            Spacer()
            Text("Настройка")
                .font(Theme.title(20))
                .foregroundStyle(Theme.primaryText)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
    }

    private var summaryCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Итого")
                HStack {
                    summaryItem(value: "\(reps * sets)", label: "всего")
                    Divider().frame(height: 40).overlay(Theme.stroke)
                    summaryItem(value: "\(sets)", label: "подходов")
                    Divider().frame(height: 40).overlay(Theme.stroke)
                    summaryItem(value: "30с", label: "отдых")
                }
            }
        }
    }

    private func summaryItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(Theme.display(28)).foregroundStyle(Theme.primaryText)
            Text(label.uppercased()).font(Theme.body(11)).tracking(1.5).foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Камера

    private func requestCameraAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startWorkout = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted { startWorkout = true } else { showCameraDeniedAlert = true }
                }
            }
        default:
            showCameraDeniedAlert = true
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
