//
//  ManageTaskView.swift
//  Smart Study Reminder
//

import SwiftUI
import SwiftData

struct ManageTaskView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \TaskItem.startAt) private var tasks: [TaskItem]
    
    @State private var filterMode: TaskFilterMode = .all
    @State private var selectedPriority: TaskPriority = .medium
    @State private var selectedTag: DefaultTaskTag = .study
    
    @State private var taskToEdit: TaskItem?
    @State private var isShowingEditView = false
    
    private var filteredTasks: [TaskItem] {
        switch filterMode {
        case .all:
            return tasks
            
        case .priority:
            return tasks.filter { task in
                task.priority == selectedPriority
            }
            
        case .tag:
            return tasks.filter { task in
                task.tags.contains { tag in
                    tag.name
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .localizedCaseInsensitiveCompare(selectedTag.title) == .orderedSame
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            List {
                filterSection
                
                if filteredTasks.isEmpty {
                    emptySection
                } else {
                    taskListSection
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Quản lý công việc")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $isShowingEditView) {
            if let taskToEdit {
                EditTaskView(task: taskToEdit)
            }
        }
    }
    
    private var filterSection: some View {
        Section {
            Picker("Lọc", selection: $filterMode) {
                ForEach(TaskFilterMode.allCases) { mode in
                    Text(mode.rawValue)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            
            if filterMode == .priority {
                Picker("Độ ưu tiên", selection: $selectedPriority) {
                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                        Text(priority.title)
                            .tag(priority)
                    }
                }
            }
            
            if filterMode == .tag {
                Picker("Nhãn", selection: $selectedTag) {
                    ForEach(DefaultTaskTag.allCases) { tag in
                        Label(tag.title, systemImage: tag.systemImage)
                            .tag(tag)
                    }
                }
            }
        } header: {
            Text("Bộ lọc")
        }
    }
    
    private var emptySection: some View {
        Section {
            ContentUnavailableView(
                "Không có công việc",
                systemImage: "tray",
                description: Text("Không tìm thấy công việc phù hợp với bộ lọc hiện tại.")
            )
        }
    }
    
    private var taskListSection: some View {
        Section {
            ForEach(filteredTasks, id: \.id) { task in
                TaskManageRowView(task: task)
                    .opacity(task.status == .done ? 0.55 : 1)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteTask(task)
                        } label: {
                            Label("Xóa", systemImage: "trash")
                        }
                        
                        Button {
                            taskToEdit = task
                            isShowingEditView = true
                        } label: {
                            Label("Sửa", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        if task.status == .done {
                            Button {
                                cancelTaskDone(task)
                            } label: {
                                Label("Hủy", systemImage: "x.circle.fill")
                            }
                            .tint(.orange)
                        } else {
                            Button {
                                markTaskAsDone(task)
                            } label: {
                                Label("Xong", systemImage: "checkmark")
                            }
                            .tint(.green)
                        }
                    }
            }
        } header: {
            Text("Danh sách công việc")
        }
    }
    
    private func deleteTask(_ task: TaskItem) {
        NotificationManager.shared.cancelTaskReminder(for: task)
        modelContext.delete(task)
        saveContext()
    }
    
    private func markTaskAsDone(_ task: TaskItem) {
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
}

#Preview {
    NavigationStack {
        ManageTaskView()
            .modelContainer(for: AppModelContainer.models)
    }
}
