//
//  DayScheduleListView.swift
//  Smart Study Reminder
//

import SwiftUI
import SwiftData

struct DayScheduleListView: View {
    let day: Weekday
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \ClassSchedule.startTime) private var schedules: [ClassSchedule]
    
    @State private var scheduleToEdit: ClassSchedule?
    @State private var isShowingEditView = false
    
    @State private var scheduleToDelete: ClassSchedule?
    @State private var showDeleteConfirmation = false
    
    private var daySchedules: [ClassSchedule] {
        schedules
            .filter { $0.weekday == day.rawValue }
            .sorted { $0.startTime < $1.startTime }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if daySchedules.isEmpty {
                ContentUnavailableView(
                    "Chưa có môn học",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Bạn chưa thêm lịch học nào cho \(day.title).")
                )
            } else {
                List {
                    Section {
                        ForEach(daySchedules, id: \.id) { schedule in
                            ScheduleManageRowView(schedule: schedule)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        scheduleToDelete = schedule
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Xóa", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        scheduleToEdit = schedule
                                        isShowingEditView = true
                                    } label: {
                                        Label("Sửa", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
                    } header: {
                        Text("Danh sách môn học")
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(day.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $isShowingEditView) {
            if let scheduleToEdit {
                EditTimetableView(schedule: scheduleToEdit)
            }
        }
        .confirmationDialog(
            "Bạn có chắc muốn xóa lịch học này?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Xóa lịch học", role: .destructive) {
                deleteSelectedSchedule()
            }
            
            Button("Hủy", role: .cancel) {}
        } message: {
            Text(scheduleToDelete?.subject.name ?? "Lịch học này sẽ bị xóa khỏi thời khóa biểu.")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    AddTimetableView()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
            }
        }
    }
    
    private func deleteSelectedSchedule() {
        guard let scheduleToDelete else { return }
        
        modelContext.delete(scheduleToDelete)
        
        do {
            try modelContext.save()
            self.scheduleToDelete = nil
        } catch {
            print("Failed to delete schedule:", error.localizedDescription)
        }
    }
}
struct ScheduleManageRowView: View {
    let schedule: ClassSchedule
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(schedule.subject.name)
                .font(.headline)
            
            Text(timeText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let room = schedule.room, !room.isEmpty {
                Label(room, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if let note = schedule.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 6)
    }
    
    private var timeText: String {
        let start = schedule.startTime.formatted(date: .omitted, time: .shortened)
        let end = schedule.endTime.formatted(date: .omitted, time: .shortened)
        return "\(start) - \(end)"
    }
}
