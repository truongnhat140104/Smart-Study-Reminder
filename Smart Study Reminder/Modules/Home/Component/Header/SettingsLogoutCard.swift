//
//  SettingsLogoutCard.swift
//  Smart Study Reminder
//

import SwiftUI

struct SettingsLogoutCard: View {
    var body: some View {
        Button {
            print("Đăng xuất")
        } label: {
            HStack(spacing: 14) {
                SettingsIconBox(
                    icon: "rectangle.portrait.and.arrow.forward",
                    color: .orange
                )
                
                Text("Đăng xuất")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .modifier(CardBackgroundModifier())
    }
}
