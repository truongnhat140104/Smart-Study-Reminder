//
//  ManageTimetableView.swift
//  Smart Study Reminder
//

import SwiftUI
import SwiftData

struct ManageTimetableView: View {
    @Query private var schedules: [ClassSchedule]
    
    private let weekdays: [Weekday] = [
        .monday,
        .tuesday,
        .wednesday,
        .thursday,
        .friday,
        .saturday,
        .sunday
    ]
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            List {
                Section {
                    ForEach(weekdays) { day in
                        NavigationLink {
                            DayScheduleListView(day: day)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(day.title)
                                        .font(.headline)
                                    
                                    Text("\(scheduleCount(for: day)) môn học")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                    }
                } header: {
                    Text("Chọn thứ để chỉnh sửa")
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Quản lý lịch học")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func scheduleCount(for day: Weekday) -> Int {
        schedules.filter { $0.weekday == day.rawValue }.count
    }
}

#Preview {
    NavigationStack {
        ManageTimetableView()
    }
}
