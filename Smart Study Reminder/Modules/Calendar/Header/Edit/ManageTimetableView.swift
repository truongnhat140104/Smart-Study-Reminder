//
//  ManageTimetableView.swift
//  Smart Study Reminder
//

import SwiftUI
import SwiftData

struct ManageTimetableView: View {
    @Environment(\.modelContext) private var modelContext

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

                Section {
                    Button(role: .destructive) {
                        deleteAllSchedules()
                    } label: {
                        Label("Xóa hết thời khóa biểu", systemImage: "trash")
                    }
                    .disabled(schedules.isEmpty)
                } footer: {
                    Text("Nút này sẽ xóa toàn bộ lịch học đã lưu trong thời khóa biểu.")
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

    private func deleteAllSchedules() {
        withAnimation {
            for schedule in schedules {
                modelContext.delete(schedule)
            }
        }

        do {
            try modelContext.save()
        } catch {
            print("Delete all schedules failed: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        ManageTimetableView()
    }
}
