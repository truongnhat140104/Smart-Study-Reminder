//
//  SettingsSyncCard.swift
//  Smart Study Reminder
//

import SwiftUI

struct SettingsSyncCard: View {
    @Bindable var settings: AppSettings
    
    var body: some View {
        VStack(spacing: 0) {
            SettingsToggleRow(
                icon: "calendar.badge.clock",
                iconColor: .green,
                title: "Đồng bộ lịch",
                isOn: Binding(
                    get: {
                        settings.enableCalendarSync
                    },
                    set: { newValue in
                        settings.enableCalendarSync = newValue
                        settings.updatedAt = .now
                    }
                )
            )
            
            Divider()
                .padding(.leading, 58)
            
            SettingsInfoRow(
                icon: "clock.arrow.circlepath",
                iconColor: .gray,
                title: "Cập nhật lần cuối",
                trailingText: settings.updatedAt.formatted(
                    .dateTime
                        .day()
                        .month()
                        .year()
                        .hour()
                        .minute()
                )
            )
        }
        .modifier(CardBackgroundModifier())
    }
}
