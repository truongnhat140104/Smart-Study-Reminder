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

    @Query(sort: \TaskItem.startAt) private var existingTasks: [TaskItem]
    @Query(sort: \Tag.name) private var existingTags: [Tag]

    @State private var title: String
    @State private var detail: String

    // Tách ngày, giờ bắt đầu và giờ kết thúc giống AddTaskView.
    @State private var selectedDate: Date
    @State private var startTime: Date
    @State private var endTime: Date

    @State private var priority: TaskPriority
    @State private var repeatRule: TaskRepeatRule

    // Chỉ lưu số phút nhắc trước giờ bắt đầu.
    @State private var hasReminder: Bool
    @State private var reminderOffset: ReminderOffsetOption

    @State private var selectedDefaultTags: Set<DefaultTaskTag>

    @State private var showEmptyTitleAlert = false
    @State private var showInvalidTimeAlert = false
    @State private var showTimeConflictAlert = false
    @State private var timeConflictMessage = ""

    private var startAt: Date {
        combine(date: selectedDate, time: startTime)
    }

    private var endAt: Date {
        combine(date: selectedDate, time: endTime)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        endAt > startAt
    }

    init(task: TaskItem) {
        self.task = task

        _title = State(initialValue: task.title)
        _detail = State(initialValue: task.detail ?? "")

        _selectedDate = State(initialValue: task.startAt)
        _startTime = State(initialValue: task.startAt)
        _endTime = State(initialValue: task.endAt)

        _priority = State(initialValue: task.priority)
        _repeatRule = State(initialValue: task.repeatRule)

        let savedOffset = task.reminderOffsetMinutes
        _hasReminder = State(initialValue: savedOffset != nil)
        _reminderOffset = State(
            initialValue: ReminderOffsetOption(rawValue: savedOffset ?? ReminderOffsetOption.tenMinutes.rawValue) ?? .tenMinutes
        )

        _selectedDefaultTags = State(initialValue: Self.initialSelectedTags(for: task))
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
                        "Ngày",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .tint(.red)

                    DatePicker(
                        "Bắt đầu",
                        selection: $startTime,
                        displayedComponents: .hourAndMinute
                    )
                    .tint(.red)

                    DatePicker(
                        "Kết thúc",
                        selection: $endTime,
                        displayedComponents: .hourAndMinute
                    )
                    .tint(.red)
                } header: {
                    Text("Thời gian làm")
                } footer: {
                    Text("Thời gian kết thúc phải sau thời gian bắt đầu và không được trùng với công việc khác.")
                }

                Section {
                    Picker("Lặp lại", selection: $repeatRule) {
                        ForEach(TaskRepeatRule.allCases) { rule in
                            Text(rule.title)
                                .tag(rule)
                        }
                    }
                } header: {
                    Text("Lặp lại")
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
                        Picker("Nhắc trước", selection: $reminderOffset) {
                            ForEach(ReminderOffsetOption.allCases) { option in
                                Text(option.title)
                                    .tag(option)
                            }
                        }
                    }
                } header: {
                    Text("Nhắc nhở")
                } footer: {
                    if hasReminder {
                        Text("App sẽ nhắc dựa trên giờ bắt đầu của công việc.")
                    }
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
        .alert("Trùng thời gian", isPresented: $showTimeConflictAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(timeConflictMessage)
        }
    }

    private func updateTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            showEmptyTitleAlert = true
            return
        }

        let newStartAt = startAt
        let newEndAt = endAt

        guard newEndAt > newStartAt else {
            showInvalidTimeAlert = true
            return
        }

        if let conflictTask = findTimeConflict(
            startAt: newStartAt,
            endAt: newEndAt,
            repeatRule: repeatRule
        ) {
            timeConflictMessage = "Không thể lưu vì bị trùng thời gian với \"\(conflictTask.title)\"."
            showTimeConflictAlert = true
            return
        }

        let tagObjects = makeTags(from: selectedDefaultTags)

        NotificationManager.shared.cancelTaskReminder(for: task)

        task.title = trimmedTitle
        task.detail = detail.nilIfEmpty
        task.startAt = newStartAt
        task.endAt = newEndAt
        task.priority = priority
        task.repeatRule = repeatRule
        task.reminderOffsetMinutes = hasReminder ? reminderOffset.rawValue : nil
        task.tags = tagObjects
        task.updatedAt = .now

        if hasReminder,
           let reminderAt = task.reminderAt,
           reminderAt > Date() {
            NotificationManager.shared.scheduleTaskReminder(for: task)
        }

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
                findOrCreateTag(named: defaultTag.title)
            }
    }

    private func findOrCreateTag(named name: String) -> Tag {
        if let existingTag = existingTags.first(where: {
            $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame
        }) {
            return existingTag
        }

        let newTag = Tag(name: name)
        modelContext.insert(newTag)
        return newTag
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

    private func combine(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        var components = DateComponents()
        components.year = dateComponents.year
        components.month = dateComponents.month
        components.day = dateComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        return calendar.date(from: components) ?? date
    }

    private func findTimeConflict(
        startAt newStartAt: Date,
        endAt newEndAt: Date,
        repeatRule newRepeatRule: TaskRepeatRule
    ) -> TaskItem? {
        let calendar = Calendar.current
        let rangeStart = calendar.startOfDay(for: newStartAt)
        let rangeEnd = calendar.date(byAdding: .year, value: 2, to: rangeStart) ?? newEndAt

        let newOccurrences = makeOccurrences(
            startAt: newStartAt,
            endAt: newEndAt,
            repeatRule: newRepeatRule,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd
        )

        for existingTask in existingTasks where existingTask.id != task.id && existingTask.status != .done {
            let existingOccurrences = makeOccurrences(
                startAt: existingTask.startAt,
                endAt: existingTask.endAt,
                repeatRule: existingTask.repeatRule,
                rangeStart: rangeStart,
                rangeEnd: rangeEnd
            )

            for newOccurrence in newOccurrences {
                if existingOccurrences.contains(where: { existingOccurrence in
                    intervalsOverlap(
                        newStart: newOccurrence.start,
                        newEnd: newOccurrence.end,
                        existingStart: existingOccurrence.start,
                        existingEnd: existingOccurrence.end
                    )
                }) {
                    return existingTask
                }
            }
        }

        return nil
    }

    private func makeOccurrences(
        startAt: Date,
        endAt: Date,
        repeatRule: TaskRepeatRule,
        rangeStart: Date,
        rangeEnd: Date
    ) -> [(start: Date, end: Date)] {
        guard endAt > startAt else { return [] }

        let duration = endAt.timeIntervalSince(startAt)

        if repeatRule == .none {
            return intervalsOverlap(
                newStart: startAt,
                newEnd: endAt,
                existingStart: rangeStart,
                existingEnd: rangeEnd
            ) ? [(startAt, endAt)] : []
        }

        var occurrences: [(start: Date, end: Date)] = []
        var currentStart = startAt
        var safetyCount = 0

        while currentStart.addingTimeInterval(duration) <= rangeStart {
            guard let nextStart = nextOccurrence(after: currentStart, repeatRule: repeatRule) else {
                return occurrences
            }

            currentStart = nextStart
            safetyCount += 1

            if safetyCount > 3000 {
                return occurrences
            }
        }

        while currentStart <= rangeEnd {
            let currentEnd = currentStart.addingTimeInterval(duration)
            occurrences.append((currentStart, currentEnd))

            guard let nextStart = nextOccurrence(after: currentStart, repeatRule: repeatRule) else {
                break
            }

            currentStart = nextStart
            safetyCount += 1

            if safetyCount > 3000 {
                break
            }
        }

        return occurrences
    }

    private func nextOccurrence(after date: Date, repeatRule: TaskRepeatRule) -> Date? {
        let calendar = Calendar.current

        switch repeatRule {
        case .none:
            return nil
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date)
        }
    }

    private func intervalsOverlap(
        newStart: Date,
        newEnd: Date,
        existingStart: Date,
        existingEnd: Date
    ) -> Bool {
        newStart < existingEnd && existingStart < newEnd
    }
}
