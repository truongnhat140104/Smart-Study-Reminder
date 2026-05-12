//
//  TasksScheduleSection.swift
//  Smart Study Reminder
//

import SwiftUI
import SwiftData

struct TasksScheduleSection: View {
    @Binding var selectedTab: MainTab
    
    var selectedDate: Date = Date()

    @Query(sort: \TaskItem.startAt) private var tasks: [TaskItem]

    @Environment(\.modelContext) private var modelContext
    
    @State private var taskToEdit: TaskItem?
    @State private var isShowingEditView = false
    
    private let calendar = Calendar.current
    
    private var normalizedSelectedDate: Date {
        calendar.startOfDay(for: selectedDate)
    }
    
    private var selectedDateTasks: [TaskItem] {
        tasksForDate(normalizedSelectedDate)
    }
    
    var body: some View {
        ScheduleCard(
            selectedTab: $selectedTab,
            dateTitle: dayTitle(from: normalizedSelectedDate),
            isToday: calendar.isDateInToday(normalizedSelectedDate),
            schedules: selectedDateTasks,
            onEdit: { task in
                editTask(task)
            },
            onDelete: { task in
                deleteTask(task)
            },
            onDone: { task in
                markTaskDone(task)
            },
            onCancel: { task in
                cancelTaskDone(task)
            }
        )
        .id(normalizedSelectedDate)
        .navigationDestination(isPresented: $isShowingEditView) {
            if let taskToEdit {
                EditTaskView(task: taskToEdit)
            }
        }
    }
    
    private func tasksForDate(_ date: Date) -> [TaskItem] {
        tasks
            .filter { task in
                calendar.isDate(task.startAt, inSameDayAs: date)
            }
            .sorted { $0.startAt < $1.startAt }
    }
    
    private func editTask(_ task: TaskItem) {
        taskToEdit = task
        isShowingEditView = true
    }
    
    private func deleteTask(_ task: TaskItem) {
        NotificationManager.shared.cancelTaskReminder(for: task)
        modelContext.delete(task)
        saveContext()
    }
    
    private func markTaskDone(_ task: TaskItem) {
        withAnimation {
            task.status = .done
            task.updatedAt = .now
        }
        NotificationManager.shared.cancelTaskReminder(for: task)
        
        saveContext()
    }
    
    private func cancelTaskDone(_ task: TaskItem) {
        withAnimation {
            task.status = .notDone
            task.updatedAt = .now
        }
        if let reminderAt = task.reminderAt, reminderAt > Date() {
            NotificationManager.shared.scheduleTaskReminder(for: task)
        }
        saveContext()
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save task:", error.localizedDescription)
        }
    }
    
    private func dayTitle(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}
