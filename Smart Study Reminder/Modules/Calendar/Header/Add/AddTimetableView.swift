import SwiftUI
import SwiftData

struct AddTimetableView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Subject.name) private var subjects: [Subject]
    @Query(sort: \ClassSchedule.startTime, order: .forward) private var classSchedules: [ClassSchedule]
    
    @State private var subjectName: String = ""
    @State private var selectedWeekday: Weekday = .monday
    @State private var startTime: Date = TimetableTimeValidator.defaultStartTime()
    @State private var endTime: Date = TimetableTimeValidator.defaultEndTime()
    @State private var room: String = ""
    @State private var note: String = ""
    
    @State private var showInvalidTimeAlert = false
    @State private var invalidTimeMessage = ""
    @State private var showEmptySubjectAlert = false
    @State private var showTimeConflictAlert = false
    @State private var timeConflictMessage = ""
    
    private var canSave: Bool {
        !subjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        TimetableTimeValidator.isStartTimeAllowed(startTime) &&
        TimetableTimeValidator.isStartBeforeEnd(startTime, endTime)
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            Form {
                Section {
                    TextField("Ví dụ: Toán cao cấp", text: $subjectName)
                        .textInputAutocapitalization(.words)
                    
                } header: {
                    Text("Môn học")
                }
                
                Section {
                    Picker("Thứ", selection: $selectedWeekday) {
                        ForEach(Weekday.allCases) { day in
                            Text(day.title)
                                .tag(day)
                        }
                    }
                    
                    DatePicker(
                        "Giờ bắt đầu",
                        selection: $startTime,
                        in: TimetableTimeValidator.allowedStartTimeRange(for: startTime),
                        displayedComponents: .hourAndMinute
                    )
                    .onChange(of: startTime) { _, newValue in
                        updateStartTime(newValue)
                    }
                    
                    DatePicker(
                        "Giờ kết thúc",
                        selection: $endTime,
                        displayedComponents: .hourAndMinute
                    )
                    .onChange(of: endTime) { _, newValue in
                        updateEndTime(newValue)
                    }
                    
                    Text("Giờ bắt đầu chỉ được chọn từ 07:00 đến 22:00.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Thời gian học")
                }
                
                Section {
                    TextField("Ví dụ: A203, Lab 5", text: $room)
                } header: {
                    Text("Phòng học")
                }
                
                Section {
                    TextField("Ghi chú thêm", text: $note, axis: .vertical)
                        .lineLimit(3...5)
                } header: {
                    Text("Ghi chú")
                }
                
                Section {
                    Button {
                        saveClassSchedule()
                    } label: {
                        Text("Lưu thời khóa biểu")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!canSave)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Thêm lịch học")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            normalizeTimesIfNeeded()
        }
        .alert("Thiếu tên môn học", isPresented: $showEmptySubjectAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Vui lòng nhập tên môn học.")
        }
        .alert("Thời gian không hợp lệ", isPresented: $showInvalidTimeAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(invalidTimeMessage)
        }
        .alert("Lịch học bị trùng", isPresented: $showTimeConflictAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(timeConflictMessage)
        }
    }
    
    private func saveClassSchedule() {
        let trimmedSubjectName = subjectName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedSubjectName.isEmpty else {
            showEmptySubjectAlert = true
            return
        }
        
        guard validateTime() else {
            return
        }
        
        if let conflictSchedule = findTimeConflict(
            weekday: selectedWeekday,
            startTime: startTime,
            endTime: endTime
        ) {
            timeConflictMessage = conflictMessage(for: conflictSchedule)
            showTimeConflictAlert = true
            return
        }
        
        let subject = findOrCreateSubject(named: trimmedSubjectName)
        
        let schedule = ClassSchedule(
            weekday: selectedWeekday.rawValue,
            startTime: startTime,
            endTime: endTime,
            room: room.nilIfEmpty,
            note: note.nilIfEmpty,
            source: .manual,
            subject: subject
        )
        
        modelContext.insert(schedule)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save class schedule:", error.localizedDescription)
        }
    }
    
    private func validateTime() -> Bool {
        guard TimetableTimeValidator.isStartTimeAllowed(startTime) else {
            invalidTimeMessage = "Giờ bắt đầu chỉ được chọn từ 07:00 đến 22:00."
            showInvalidTimeAlert = true
            return false
        }
        
        guard TimetableTimeValidator.isStartBeforeEnd(startTime, endTime) else {
            invalidTimeMessage = "Giờ bắt đầu phải trước giờ kết thúc."
            showInvalidTimeAlert = true
            return false
        }
        
        return true
    }
    
    private func findTimeConflict(
        weekday: Weekday,
        startTime: Date,
        endTime: Date
    ) -> ClassSchedule? {
        classSchedules.first { existingSchedule in
            guard existingSchedule.weekday == weekday.rawValue else {
                return false
            }
            
            return TimetableTimeValidator.isOverlapping(
                startTime,
                endTime,
                existingSchedule.startTime,
                existingSchedule.endTime
            )
        }
    }
    
    private func conflictMessage(for schedule: ClassSchedule) -> String {
        "Lịch này bị trùng với \(schedule.subject.name) vào \(selectedWeekday.title), từ \(formatTime(schedule.startTime)) đến \(formatTime(schedule.endTime))."
    }
    
    private func normalizeTimesIfNeeded() {
        startTime = TimetableTimeValidator.clampedStartTime(startTime)
        
        if !TimetableTimeValidator.isStartBeforeEnd(startTime, endTime) {
            endTime = TimetableTimeValidator.suggestedEndTime(after: startTime)
        }
    }
    
    private func updateStartTime(_ newValue: Date) {
        let clampedStartTime = TimetableTimeValidator.clampedStartTime(newValue)
        
        if startTime != clampedStartTime {
            startTime = clampedStartTime
        }
        
        if !TimetableTimeValidator.isStartBeforeEnd(startTime, endTime) {
            endTime = TimetableTimeValidator.suggestedEndTime(after: startTime)
        }
    }
    
    private func updateEndTime(_ newValue: Date) {
        guard TimetableTimeValidator.isStartBeforeEnd(startTime, newValue) else {
            endTime = TimetableTimeValidator.suggestedEndTime(after: startTime)
            return
        }
        
        endTime = newValue
    }
    
    private func findOrCreateSubject(named name: String) -> Subject {
        if let existingSubject = subjects.first(where: {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare(name) == .orderedSame
        }) {
            return existingSubject
        }
        
        let newSubject = Subject(name: name)
        modelContext.insert(newSubject)
        return newSubject
    }
    
    private func formatTime(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .locale(Locale(identifier: "vi_VN"))
                .hour()
                .minute()
        )
    }
}

enum Weekday: Int, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .monday:
            return "Thứ 2"
        case .tuesday:
            return "Thứ 3"
        case .wednesday:
            return "Thứ 4"
        case .thursday:
            return "Thứ 5"
        case .friday:
            return "Thứ 6"
        case .saturday:
            return "Thứ 7"
        case .sunday:
            return "Chủ nhật"
        }
    }
}

enum TimetableTimeValidator {
    private static let calendar = Calendar.current
    private static let earliestStartMinute = 7 * 60
    private static let latestStartMinute = 22 * 60
    
    static func defaultStartTime() -> Date {
        date(onSameDayAs: Date(), minuteOfDay: earliestStartMinute)
    }
    
    static func defaultEndTime() -> Date {
        date(onSameDayAs: Date(), minuteOfDay: earliestStartMinute + 60)
    }
    
    static func allowedStartTimeRange(for date: Date) -> ClosedRange<Date> {
        let lowerBound = Self.date(onSameDayAs: date, minuteOfDay: earliestStartMinute)
        let upperBound = Self.date(onSameDayAs: date, minuteOfDay: latestStartMinute)
        return lowerBound...upperBound
    }
    
    static func isStartTimeAllowed(_ date: Date) -> Bool {
        (earliestStartMinute...latestStartMinute).contains(minuteOfDay(date))
    }
    
    static func isStartBeforeEnd(_ startTime: Date, _ endTime: Date) -> Bool {
        minuteOfDay(startTime) < minuteOfDay(endTime)
    }
    
    static func isOverlapping(
        _ firstStartTime: Date,
        _ firstEndTime: Date,
        _ secondStartTime: Date,
        _ secondEndTime: Date
    ) -> Bool {
        let firstStart = minuteOfDay(firstStartTime)
        let firstEnd = minuteOfDay(firstEndTime)
        let secondStart = minuteOfDay(secondStartTime)
        let secondEnd = minuteOfDay(secondEndTime)
        
        return firstStart < secondEnd && secondStart < firstEnd
    }
    
    static func clampedStartTime(_ date: Date) -> Date {
        let currentMinute = minuteOfDay(date)
        
        if currentMinute < earliestStartMinute {
            return Self.date(onSameDayAs: date, minuteOfDay: earliestStartMinute)
        }
        
        if currentMinute > latestStartMinute {
            return Self.date(onSameDayAs: date, minuteOfDay: latestStartMinute)
        }
        
        return date
    }
    
    static func suggestedEndTime(after startTime: Date) -> Date {
        let startMinute = minuteOfDay(startTime)
        let suggestedEndMinute = min(startMinute + 60, 23 * 60 + 59)
        return Self.date(onSameDayAs: startTime, minuteOfDay: suggestedEndMinute)
    }
    
    static func minuteOfDay(_ date: Date) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
    
    static func date(onSameDayAs date: Date, minuteOfDay: Int) -> Date {
        let safeMinuteOfDay = max(0, min(minuteOfDay, 23 * 60 + 59))
        let hour = safeMinuteOfDay / 60
        let minute = safeMinuteOfDay % 60
        
        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: date
        ) ?? date
    }
}

#Preview {
    NavigationStack {
        AddTimetableView()
    }
    .modelContainer(for: AppModelContainer.models, inMemory: true)
}
