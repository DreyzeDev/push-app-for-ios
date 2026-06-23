//
//  ModesView.swift
//  PushApp
//
//  Список режимов. Пока один режим — «Отжимания».
//

import SwiftUI

struct ModesView: View {
    @State private var showSetup = false

    var body: some View {
        ZStack {
            ScreenBackground()

            ScrollView {
                VStack(spacing: 20) {
                    SectionHeader(title: "Доступные режимы")

                    modeCard

                    lockedCard

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
        }
        .navigationTitle("Режимы")
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(isPresented: $showSetup) {
            PushupSetupView()
        }
    }

    private var modeCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Theme.primaryText)
                        .frame(width: 64, height: 64)
                        .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 16))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Отжимания")
                            .font(Theme.title(24))
                            .foregroundStyle(Theme.primaryText)
                        Text("Трекинг тела камерой · зачёт ≥ 80% глубины")
                            .font(Theme.body(13))
                            .foregroundStyle(Theme.secondaryText)
                    }
                    Spacer()
                }

                Text("Камера отслеживает руки, торс, ноги и лицо. Отжимание засчитывается, когда глубина опускания достигает 80% и больше. Между подходами — отдых 30 секунд.")
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.secondaryText)

                PrimaryButton(title: "Начать", systemImage: "play.fill") {
                    showSetup = true
                }
            }
        }
    }

    private var lockedCard: some View {
        Card {
            HStack(spacing: 14) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.secondaryText)
                    .frame(width: 52, height: 52)
                    .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Скоро")
                        .font(Theme.title(18))
                        .foregroundStyle(Theme.secondaryText)
                    Text("Приседания, планка, подтягивания")
                        .font(Theme.body(13))
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
            }
        }
        .opacity(0.7)
    }
}
