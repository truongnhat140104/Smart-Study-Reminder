//
//  EditTimetableView.swift
//  Smart Study Reminder
//

import SwiftUI
import SwiftData

struct EditTimetableView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let schedule: ClassSchedule
    
    @Query(sort: \Subject.name) private var subjects: [Subject]
    @Query(sort: \ClassSchedule.startTime, order: .forward) private var classSchedules: [ClassSchedule]
    
    @State private var subjectName: String
    @State private var selectedWeekday: Weekday
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var room: String
    @State private var note: String
    
    @State private var showInvalidTimeAlert = false
    @State private var invalidTimeMessage = ""
    @State private var showEmptySubjectAlert = false
    @State private var showDeleteConfirmation = false
    @State private var showTimeConflictAlert = false
    @State private var timeConflictMessage = ""
    
    init(schedule: ClassSchedule) {
        self.schedule = schedule
        
        _subjectName = State(initialValue: schedule.subject.name)
        _selectedWeekday = State(initialValue: Weekday(rawValue: schedule.weekday) ?? .monday)
        _startTime = State(initialValue: schedule.startTime)
        _endTime = State(initialValue: schedule.endTime)
        _room = State(initialValue: schedule.room ?? "")
        _note = State(initialValue: schedule.note ?? "")
    }
    
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
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Text("Xóa lịch học")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Chỉnh sửa lịch học")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            normalizeTimesIfNeeded()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Lưu") {
                    updateClassSchedule()
                }
                .fontWeight(.semibold)
                .disabled(!canSave)
            }
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
        .confirmationDialog(
            "Bạn có chắc muốn xóa lịch học này?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Xóa lịch học", role: .destructive) {
                deleteClassSchedule()
            }
            
            Button("Hủy", role: .cancel) {}
        }
    }
    
    private func updateClassSchedule() {
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
        
        schedule.weekday = selectedWeekday.rawValue
        schedule.startTime = startTime
        schedule.endTime = endTime
        schedule.room = room.nilIfEmpty
        schedule.note = note.nilIfEmpty
        schedule.subject = subject
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to update class schedule:", error.localizedDescription)
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
            guard existingSchedule !== schedule else {
                return false
            }
            
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
    
    private func deleteClassSchedule() {
        modelContext.delete(schedule)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to delete class schedule:", error.localizedDescription)
        }
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
