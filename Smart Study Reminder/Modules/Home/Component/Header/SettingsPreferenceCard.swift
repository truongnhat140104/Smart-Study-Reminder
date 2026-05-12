//
//  SettingsPreferenceCard.swift
//  Smart Study Reminder
//

import SwiftUI

struct SettingsPreferenceCard: View {
    @Bindable var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            
            VStack(spacing: 0) {
                SettingsToggleRow(
                    icon: "bell.fill",
                    iconColor: .red,
                    title: "Thông báo",
                    isOn: Binding(
                        get: {
                            settings.enableNotifications
                        },
                        set: { newValue in
                            settings.enableNotifications = newValue
                            settings.updatedAt = .now
                        }
                    )
                )
                
                rowDivider
                
                SettingsStepperRow(
                    icon: "alarm.fill",
                    iconColor: .orange,
                    title: "Nhắc trước",
                    valueText: "\(settings.defaultReminderMinutes) phút",
                    onMinus: {
                        settings.defaultReminderMinutes = max(5, settings.defaultReminderMinutes - 5)
                        settings.updatedAt = .now
                    },
                    onPlus: {
                        settings.defaultReminderMinutes += 5
                        settings.updatedAt = .now
                    }
                )
                
                rowDivider
                
                SettingsStepperRow(
                    icon: "timer",
                    iconColor: .blue,
                    title: "Thời lượng học",
                    valueText: "\(settings.preferredStudyDurationMinutes) phút",
                    onMinus: {
                        settings.preferredStudyDurationMinutes = max(15, settings.preferredStudyDurationMinutes - 15)
                        settings.updatedAt = .now
                    },
                    onPlus: {
                        settings.preferredStudyDurationMinutes += 15
                        settings.updatedAt = .now
                    }
                )
            }
            .padding(.vertical, 4)
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 5)
    }
    
    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.red.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.red)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Tùy chỉnh học tập")
                    .font(.headline)
                
                Text("Thiết lập nhắc nhở và thời lượng học mặc định")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var rowDivider: some View {
        Divider()
            .padding(.leading, 58)
    }
}
