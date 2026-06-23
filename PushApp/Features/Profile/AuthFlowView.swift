//
//  AuthFlowView.swift
//  PushApp
//
//  Регистрация по почте с кодом подтверждения и вход.
//  Шаги регистрации: почта → код → ник и пароль → аватар и подпись.
//

import SwiftUI

struct AuthFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthStore

    enum Mode: String, CaseIterable { case register = "Регистрация", login = "Вход" }
    enum Step: Int, CaseIterable { case email, code, credentials, avatar }

    @State private var mode: Mode = .register
    @State private var step: Step = .email

    @State private var email = ""
    @State private var code = ""
    @State private var nickname = ""
    @State private var password = ""
    @State private var motto = "Каждый день — сильнее"
    @State private var avatar: Avatar? = Avatar.random()

    @State private var devCode: String?
    @State private var error: String?
    @State private var working = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        Picker("", selection: $mode) {
                            ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: mode) { _, _ in resetFlow() }

                        if mode == .register {
                            registerFlow
                        } else {
                            loginFlow
                        }

                        if let error {
                            Text(error)
                                .font(Theme.body(14))
                                .foregroundStyle(Theme.primaryText)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(mode.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Закрыть") { dismiss() }.tint(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Вход

    private var loginFlow: some View {
        VStack(spacing: 14) {
            ThemedField(placeholder: "Почта", text: $email, keyboard: .emailAddress)
            ThemedField(placeholder: "Пароль", text: $password, isSecure: true)
            PrimaryButton(title: "Войти", systemImage: "arrow.right", isLoading: working) {
                run {
                    try await auth.login(email: email, password: password)
                    dismiss()
                }
            }
        }
    }

    // MARK: - Регистрация

    @ViewBuilder
    private var registerFlow: some View {
        stepDots

        switch step {
        case .email:
            VStack(spacing: 14) {
                Text("Введи почту — пришлём код подтверждения.")
                    .font(Theme.body(14)).foregroundStyle(Theme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ThemedField(placeholder: "Почта", text: $email, keyboard: .emailAddress)
                PrimaryButton(title: "Получить код", systemImage: "envelope.fill", isLoading: working) {
                    run {
                        devCode = try await auth.requestCode(email: email)
                        step = .code
                    }
                }
            }

        case .code:
            VStack(spacing: 14) {
                Text("Код отправлен на \(email).")
                    .font(Theme.body(14)).foregroundStyle(Theme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let devCode {
                    // Демо-режим: показываем код прямо в приложении (сервера нет).
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                        Text("Демо-код: \(devCode)")
                    }
                    .font(Theme.mono(15))
                    .foregroundStyle(Theme.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 12))
                }
                ThemedField(placeholder: "Код из 6 цифр", text: $code, keyboard: .numberPad)
                PrimaryButton(title: "Подтвердить", systemImage: "checkmark", isLoading: working) {
                    run {
                        try await auth.verifyCode(email: email, code: code)
                        step = .credentials
                    }
                }
                Button("Изменить почту") { step = .email; error = nil }
                    .font(Theme.body(13)).tint(Theme.secondaryText)
            }

        case .credentials:
            VStack(spacing: 14) {
                Text("Придумай ник и пароль.")
                    .font(Theme.body(14)).foregroundStyle(Theme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ThemedField(placeholder: "Ник", text: $nickname)
                ThemedField(placeholder: "Пароль (от 4 символов)", text: $password, isSecure: true)
                PrimaryButton(title: "Дальше", systemImage: "arrow.right") {
                    error = nil
                    if nickname.trimmingCharacters(in: .whitespaces).count < 2 {
                        error = "Ник должен быть не короче 2 символов"
                    } else if password.count < 4 {
                        error = "Пароль должен быть не короче 4 символов"
                    } else {
                        step = .avatar
                    }
                }
            }

        case .avatar:
            VStack(spacing: 18) {
                Text("Выбери аватар (можно пропустить) и подпись.")
                    .font(Theme.body(14)).foregroundStyle(Theme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                AvatarEditor(avatar: $avatar, initial: String(nickname.prefix(1)))
                ThemedField(placeholder: "Подпись профиля", text: $motto, autocap: .sentences)
                PrimaryButton(title: "Завершить регистрацию", systemImage: "checkmark.seal.fill", isLoading: working) {
                    run {
                        try await auth.register(email: email, nickname: nickname, password: password, avatar: avatar)
                        if motto.trimmingCharacters(in: .whitespaces).isEmpty == false {
                            auth.updateProfile(motto: motto)
                        }
                        dismiss()
                    }
                }
            }
        }
    }

    private var stepDots: some View {
        HStack(spacing: 8) {
            ForEach(Step.allCases, id: \.self) { s in
                Capsule()
                    .fill(s.rawValue <= step.rawValue ? Theme.accent : Theme.stroke)
                    .frame(width: s == step ? 26 : 10, height: 6)
                    .animation(.snappy, value: step)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Утилиты

    private func resetFlow() {
        step = .email
        error = nil
        devCode = nil
        code = ""
    }

    /// Запускает асинхронную операцию, ловит ошибки в `error` и крутит индикатор.
    private func run(_ operation: @escaping () async throws -> Void) {
        error = nil
        working = true
        Task { @MainActor in
            do {
                try await operation()
            } catch {
                self.error = error.localizedDescription
            }
            working = false
        }
    }
}
