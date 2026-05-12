//
//  ChatInputBar.swift
//  Smart Study Reminder
//

import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String

    let onSend: () -> Void
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            inputBox

            Button {
                onSend()
                isFocused.wrappedValue = false
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(canSend ? Color.blue.gradient : Color.gray.gradient)
                    )
            }
            .disabled(!canSend)
        }
    }

    private var inputBox: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text("Nhập câu hỏi...")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }

            TextEditor(text: $text)
                .focused(isFocused)
                .frame(minHeight: 20, maxHeight: 20)
                .padding(.horizontal, 10)
                .padding(.vertical, 15)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled(false)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
