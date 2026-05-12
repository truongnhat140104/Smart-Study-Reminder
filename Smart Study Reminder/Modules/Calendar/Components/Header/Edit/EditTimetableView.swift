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
    
    @State private var subjectName: String
    @State private var selectedWeekday: Weekday
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var room: String
    @State private var note: String
    
    @State private var showInvalidTimeAlert = false
    @State private var showEmptySubjectAlert = false
    @State private var showDeleteConfirmation = false
    
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
        endTime > startTime
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
                        displayedComponents: .hourAndMinute
                    )
                    
                    DatePicker(
                        "Giờ kết thúc",
                        selection: $endTime,
                        displayedComponents: .hourAndMinute
                    )
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
            Text("Giờ kết thúc phải sau giờ bắt đầu.")
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
        
        guard endTime > startTime else {
            showInvalidTimeAlert = true
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
}
