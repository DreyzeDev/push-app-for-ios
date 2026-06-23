//
//  UIComponents.swift
//  PushApp
//
//  Переиспользуемые элементы интерфейса в чёрно-белом стиле:
//  крупные кнопки, карточки, поля ввода, степпер.
//

import SwiftUI

// MARK: - Основная кнопка (белая на чёрном)

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var isLoading = false
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView().tint(.black)
                } else {
                    if let systemImage { Image(systemName: systemImage) }
                    Text(title)
                }
            }
            .font(Theme.title(18))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(enabled ? Theme.accent : Theme.stroke, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
        .disabled(!enabled || isLoading)
    }
}

// MARK: - Второстепенная кнопка (обводка)

struct OutlineButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(Theme.title(17))
            .foregroundStyle(Theme.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Theme.stroke, lineWidth: 1.5)
            )
        }
    }
}

// MARK: - Карточка

struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(Theme.spacing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
    }
}

// MARK: - Поле ввода в стиле приложения

struct ThemedField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    var keyboard: UIKeyboardType = .default
    var autocap: TextInputAutocapitalization = .never

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .textInputAutocapitalization(autocap)
        .autocorrectionDisabled()
        .keyboardType(keyboard)
        .font(Theme.body(17))
        .foregroundStyle(Theme.primaryText)
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.stroke, lineWidth: 1)
        )
    }
}

// MARK: - Степпер (− значение +)

struct CounterStepper: View {
    let title: String
    @Binding var value: Int
    var range: ClosedRange<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(Theme.body(13))
                .tracking(2)
                .foregroundStyle(Theme.secondaryText)

            HStack {
                stepButton("minus") { value = max(range.lowerBound, value - 1) }
                Spacer()
                Text("\(value)")
                    .font(Theme.display(40))
                    .foregroundStyle(Theme.primaryText)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: value)
                Spacer()
                stepButton("plus") { value = min(range.upperBound, value + 1) }
            }
        }
        .padding(Theme.spacing)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .stroke(Theme.stroke, lineWidth: 1)
        )
    }

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 54, height: 54)
                .background(Theme.accent, in: Circle())
        }
    }
}

// MARK: - Заголовок секции

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(Theme.body(13))
            .tracking(2)
            .foregroundStyle(Theme.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
