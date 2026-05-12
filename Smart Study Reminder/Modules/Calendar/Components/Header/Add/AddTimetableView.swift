import SwiftUI
import SwiftData

struct AddTimetableView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Subject.name) private var subjects: [Subject]
    
    @State private var subjectName: String = ""
    @State private var selectedWeekday: Weekday = .monday
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var room: String = ""
    @State private var note: String = ""
    
    @State private var showInvalidTimeAlert = false
    @State private var showEmptySubjectAlert = false
    
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
    }
    
    private func saveClassSchedule() {
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


#Preview {
    NavigationStack {
        AddTimetableView()
    }
}
