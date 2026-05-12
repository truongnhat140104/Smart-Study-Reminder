//
//  SettingsAccountCard.swift
//  Smart Study Reminder
//

import SwiftUI

struct SettingsAccountCard: View {
    @Bindable var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.12))
                        .frame(width: 72, height: 72)
                    
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 58))
                        .foregroundStyle(.blue.gradient)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tài khoản")
                        .font(.headline)
                    
                    Text(settings.displayName?.isEmpty == false ? settings.displayName! : "Chưa đặt tên")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Tên hiển thị")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextField(
                    "Nhập tên của bạn",
                    text: Binding(
                        get: {
                            settings.displayName ?? ""
                        },
                        set: { newValue in
                            settings.displayName = newValue
                            settings.updatedAt = .now
                        }
                    )
                )
                .textFieldStyle(.roundedBorder)
            }
        }
        .modifier(CardBackgroundModifier())
    }
}
