//
//  HomeHeaderView.swift
//  Smart Study Reminder
//

import SwiftUI
import SwiftData

struct HomeHeader: View {
    @Query(sort: \ClassSchedule.startTime, order: .forward)
    private var schedules: [ClassSchedule]
    
    private var todaySchedules: [ClassSchedule] {
        schedules.filter { $0.weekday == todayWeekday }
    }
    
    private var todayWeekday: Int {
        Calendar.current.component(.weekday, from: Date())
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Xin chào 👋")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(titleText)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            NavigationLink {
                SettingsView()
            } label: {
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.12))
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(.blue.gradient)
                }
                .background(
                    Circle()
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cài đặt")
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var titleText: String {
        let count = todaySchedules.count
        
        if count == 0 {
            return "Hôm nay bạn không có lịch học"
        } else {
            return "Bạn có \(count) lịch học hôm nay!"
        }
    }
}
