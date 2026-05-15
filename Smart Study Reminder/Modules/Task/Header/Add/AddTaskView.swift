//
//  AddTaskView.swift
//  Smart Study Reminder
//

import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \TaskItem.startAt) private var existingTasks: [TaskItem]

    @State private var title: String = ""
    @State private var detail: String = ""

    // Chọn ngày riêng, sau đó chọn giờ bắt đầu và giờ kết thúc riêng.
    @State private var selectedDate: Date = Date()
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Calendar.current.date(
        byAdding: .hour,
        value: 1,
        to: Date()
    ) ?? Date()

    @State private var priority: TaskPriority = .medium
    @State private var repeatRule: TaskRepeatRule = .none

    // Chỉ lưu số phút nhắc trước giờ bắt đầu, không lưu DatePicker riêng.
    @State private var hasReminder: Bool = false
    @State private var reminderOffset: ReminderOffsetOption = .tenMinutes

    @State private var selectedDefaultTags: Set<DefaultTaskTag> = []

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
                        saveTask()
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
        .navigationTitle("Thêm công việc")
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

    private func saveTask() {
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
            timeConflictMessage = "Không thể thêm vì bị trùng thời gian với \"\(conflictTask.title)\"."
            showTimeConflictAlert = true
            return
        }

        let tagObjects = makeTags(from: selectedDefaultTags)

        let task = TaskItem(
            title: trimmedTitle,
            detail: detail.nilIfEmpty,
            startAt: newStartAt,
            endAt: newEndAt,
            status: .notDone,
            priority: priority,
            reminderOffsetMinutes: hasReminder ? reminderOffset.rawValue : nil,
            notificationIdentifier: nil,
            repeatRule: repeatRule,
            tags: tagObjects
        )

        modelContext.insert(task)

        if hasReminder {
            NotificationManager.shared.scheduleTaskReminder(for: task)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save task:", error.localizedDescription)
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

        for task in existingTasks where task.status != .done {
            let existingOccurrences = makeOccurrences(
                startAt: task.startAt,
                endAt: task.endAt,
                repeatRule: task.repeatRule,
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
                    return task
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

enum ReminderOffsetOption: Int, CaseIterable, Identifiable {
    case atTime = 0
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    case oneHour = 60
    case oneDay = 1440

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .atTime:
            return "Đúng giờ"
        case .fiveMinutes:
            return "Trước 5 phút"
        case .tenMinutes:
            return "Trước 10 phút"
        case .fifteenMinutes:
            return "Trước 15 phút"
        case .thirtyMinutes:
            return "Trước 30 phút"
        case .oneHour:
            return "Trước 1 giờ"
        case .oneDay:
            return "Trước 1 ngày"
        }
    }
}

#Preview {
    NavigationStack {
        AddTaskView()
            .modelContainer(for: AppModelContainer.models, inMemory: true)
    }
}
