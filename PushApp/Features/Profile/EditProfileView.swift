//
//  EditProfileView.swift
//  PushApp
//
//  Кастомизация профиля: ник, подпись, аватар (стиль + перегенерация «ИИ»).
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthStore

    @State private var nickname = ""
    @State private var motto = ""
    @State private var avatar: Avatar?
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        AvatarEditor(avatar: $avatar, initial: String(nickname.prefix(1)))

                        VStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionHeader(title: "Ник")
                                ThemedField(placeholder: "Ник", text: $nickname, autocap: .never)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                SectionHeader(title: "Подпись")
                                ThemedField(placeholder: "Короткий девиз", text: $motto, autocap: .sentences)
                            }
                        }

                        PrimaryButton(title: "Сохранить", systemImage: "checkmark") {
                            auth.updateProfile(
                                nickname: nickname.trimmingCharacters(in: .whitespaces),
                                motto: motto,
                                avatar: .some(avatar)
                            )
                            dismiss()
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }.tint(.white)
                }
            }
            .onAppear {
                guard !loaded, let user = auth.currentUser else { return }
                nickname = user.nickname
                motto = user.motto
                avatar = user.avatar
                loaded = true
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Редактор аватара (общий для регистрации и профиля)

struct AvatarEditor: View {
    @Binding var avatar: Avatar?
    var initial: String

    var body: some View {
        VStack(spacing: 16) {
            GeneratedAvatarView(avatar: avatar, fallbackInitial: initial.isEmpty ? "?" : initial, size: 130)

            HStack(spacing: 10) {
                Button {
                    let style = avatar?.style ?? .rings
                    avatar = Avatar(seed: Int.random(in: 0...1_000_000), style: style)
                } label: {
                    Label("Сгенерировать", systemImage: "wand.and.stars")
                        .font(Theme.body(14))
                        .foregroundStyle(.black)
                        .padding(.vertical, 12).frame(maxWidth: .infinity)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                }
                Button {
                    avatar = nil
                } label: {
                    Label("Без аватара", systemImage: "nosign")
                        .font(Theme.body(14))
                        .foregroundStyle(Theme.primaryText)
                        .padding(.vertical, 12).frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 14).stroke(Theme.stroke, lineWidth: 1.5))
                }
            }

            // Выбор стиля
            HStack(spacing: 8) {
                ForEach(Avatar.Style.allCases) { style in
                    Button {
                        let seed = avatar?.seed ?? Int.random(in: 0...1_000_000)
                        avatar = Avatar(seed: seed, style: style)
                    } label: {
                        Text(style.rawValue)
                            .font(Theme.body(12))
                            .foregroundStyle(avatar?.style == style ? .black : Theme.secondaryText)
                            .padding(.vertical, 8).frame(maxWidth: .infinity)
                            .background(
                                avatar?.style == style ? Theme.accent : Color.clear,
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Theme.stroke, lineWidth: avatar?.style == style ? 0 : 1)
                            )
                    }
                }
            }
        }
    }
}
