//
//  EditTaskView.swift
//  Smart Study Reminder
//

import SwiftUI
import SwiftData

struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let task: TaskItem
    
    @Query(sort: \Tag.name) private var existingTags: [Tag]
    
    @State private var title: String
    @State private var detail: String
    
    @State private var startAt: Date
    @State private var endAt: Date
    
    @State private var priority: TaskPriority
    
    @State private var hasReminder: Bool
    @State private var reminderAt: Date
    
    @State private var selectedDefaultTags: Set<DefaultTaskTag>
    
    @State private var showEmptyTitleAlert = false
    @State private var showInvalidTimeAlert = false
    
    init(task: TaskItem) {
        self.task = task
        
        _title = State(initialValue: task.title)
        _detail = State(initialValue: task.detail ?? "")
        _startAt = State(initialValue: task.startAt)
        _endAt = State(initialValue: task.endAt)
        _priority = State(initialValue: task.priority)
        _hasReminder = State(initialValue: task.reminderAt != nil)
        _reminderAt = State(initialValue: task.reminderAt ?? Date())
        _selectedDefaultTags = State(initialValue: Self.initialSelectedTags(for: task))
    }
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        endAt > startAt
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            Form {
                Section {
                    TextField("Ví dụ: Làm bài tập Toán", text: $title)
                        .textInputAutocapitalization(.sentences)
                    
                    TextField("Mô tả chi tiết", text: $detail, axis: .vertical)
                        .lineLimit(3...5)
                } header: {
                    Text("Thông tin công việc")
                }
                
                Section {
                    DatePicker(
                        "Bắt đầu",
                        selection: $startAt,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .tint(.red)
                    
                    DatePicker(
                        "Kết thúc",
                        selection: $endAt,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .tint(.red)

                } header: {
                    Text("Thời gian làm")
                }
                
                Section {
                    Picker("Độ ưu tiên", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.title)
                                .tag(priority)
                        }
                    }
                } header: {
                    Text("Ưu tiên")
                }
                
                Section {
                    Toggle("Bật nhắc nhở", isOn: $hasReminder)
                    
                    if hasReminder {
                        DatePicker(
                            "Thời gian nhắc",
                            selection: $reminderAt,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .tint(.red)

                    }
                } header: {
                    Text("Nhắc nhở")
                }
                
                Section {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 12
                    ) {
                        ForEach(DefaultTaskTag.allCases) { tag in
                            Button {
                                toggleDefaultTag(tag)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: tag.systemImage)
                                    
                                    Text(tag.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    if selectedDefaultTags.contains(tag) {
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(
                                    selectedDefaultTags.contains(tag)
                                    ? Color.red.opacity(0.15)
                                    : Color(.secondarySystemGroupedBackground)
                                )
                                .foregroundStyle(
                                    selectedDefaultTags.contains(tag)
                                    ? Color.red
                                    : Color.primary
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Nhãn")
                } footer: {
                    Text("Bạn có thể chọn nhiều nhãn cho một công việc.")
                }
                
                Section {
                    Button {
                        updateTask()
                    } label: {
                        Text("Lưu công việc")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.red)
                    }
                    .disabled(!canSave)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Chỉnh sửa công việc")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Thiếu tiêu đề", isPresented: $showEmptyTitleAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Vui lòng nhập tên công việc.")
        }
        .alert("Thời gian không hợp lệ", isPresented: $showInvalidTimeAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Thời gian kết thúc phải sau thời gian bắt đầu.")
        }
    }
    
    private func updateTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty else {
            showEmptyTitleAlert = true
            return
        }
        
        guard endAt > startAt else {
            showInvalidTimeAlert = true
            return
        }
        
        let tagObjects = makeTags(from: selectedDefaultTags)
        NotificationManager.shared.cancelTaskReminder(for: task)

        task.title = trimmedTitle
        task.detail = detail.nilIfEmpty
        task.startAt = startAt
        task.endAt = endAt
        task.priority = priority
        task.reminderAt = hasReminder ? reminderAt : nil
        task.tags = tagObjects
        task.updatedAt = .now
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to update task:", error.localizedDescription)
        }
    }
    
    private func toggleDefaultTag(_ tag: DefaultTaskTag) {
        if selectedDefaultTags.contains(tag) {
            selectedDefaultTags.remove(tag)
        } else {
            selectedDefaultTags.insert(tag)
        }
    }
    
    private func makeTags(from selectedTags: Set<DefaultTaskTag>) -> [Tag] {
        DefaultTaskTag.allCases
            .filter { selectedTags.contains($0) }
            .map { defaultTag in
                let tag = Tag(name: defaultTag.title)
                modelContext.insert(tag)
                return tag
            }
    }
    
    private static func initialSelectedTags(for task: TaskItem) -> Set<DefaultTaskTag> {
        let taskTagNames = task.tags.map {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        let matchedDefaultTags = DefaultTaskTag.allCases.filter { defaultTag in
            taskTagNames.contains { tagName in
                tagName.localizedCaseInsensitiveCompare(defaultTag.title) == .orderedSame
            }
        }
        
        return Set(matchedDefaultTags)
    }
}

#Preview {
    NavigationStack {
        EditTaskView(
            task: TaskItem(
                title: "Làm bài tập Toán",
                detail: "Hoàn thành chương 2",
                startAt: Date(),
                endAt: Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date(),
                priority: .medium
            )
        )
    }
}
