//
//  ScanTimetableCard.swift
//  Smart Study Reminder
//

import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct ScanTimetableCard: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Subject.name)
    private var subjects: [Subject]
    
    @Query(sort: \ClassSchedule.startTime, order: .forward)
    private var classSchedules: [ClassSchedule]
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    @State private var recognizedText: String = ""
    @State private var scheduleDrafts: [ScannedScheduleDraft] = []
    
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    @State private var isShowingCamera = false
    
    private let weekdayOptions: [(title: String, value: Int)] = [
        ("Chủ nhật", 1),
        ("Thứ 2", 2),
        ("Thứ 3", 3),
        ("Thứ 4", 4),
        ("Thứ 5", 5),
        ("Thứ 6", 6),
        ("Thứ 7", 7)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            
            actionButtons
            
            if let selectedImage {
                previewImage(selectedImage)
            }
            
            if isProcessing {
                processingView
            }
            
            if let successMessage {
                successView(successMessage)
            }
            
            if let errorMessage {
                errorView(errorMessage)
            }
            
            if !scheduleDrafts.isEmpty {
                scheduleDraftEditor
            }
            
            if !recognizedText.isEmpty {
                resultView
            }
        }
        .modifier(CardBackgroundModifier())
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            
            Task {
                await loadImageFromPhotoPicker(newItem)
            }
        }
        .sheet(isPresented: $isShowingCamera) {
            CameraImagePicker { image in
                selectedImage = image
                
                Task {
                    await scanImage(image)
                }
            }
            .ignoresSafeArea()
        }
    }
    
    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 46, height: 46)
                
                Image(systemName: "viewfinder.rectangular")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Quét thời khóa biểu")
                    .font(.headline)
                
                Text("OCR ảnh TKB, AI local lọc lịch, bạn kiểm tra rồi lưu")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var actionButtons: some View {
        PhotosPicker(
            selection: $selectedPhotoItem,
            matching: .images
        ) {
            Label("Chọn ảnh", systemImage: "photo.fill")
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue.gradient)
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
    }
    
    private func previewImage(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(maxHeight: 220)
            .padding(8)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            }
    }
    
    private var processingView: some View {
        HStack(spacing: 10) {
            ProgressView()
            
            Text("Đang đọc và phân tích thời khóa biểu...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func successView(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private func errorView(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private var scheduleDraftEditor: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Lịch học AI nhận diện", systemImage: "calendar.badge.clock")
                    .font(.headline)
                    .foregroundStyle(.blue)
                
                Spacer()
                
                Text("\(scheduleDrafts.count) lịch")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach($scheduleDrafts) { $draft in
                        draftCard($draft)
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: 420)
            
            Button {
                saveScheduleDrafts()
            } label: {
                Label("Lưu lịch học", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    
    private func draftCard(_ draft: Binding<ScannedScheduleDraft>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Tên môn học", text: draft.subjectName)
                    .font(.headline)
                
                Button(role: .destructive) {
                    scheduleDrafts.removeAll { $0.id == draft.wrappedValue.id }
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
            }
            
            Picker("Thứ", selection: draft.weekday) {
                ForEach(weekdayOptions, id: \.value) { option in
                    Text(option.title)
                        .tag(option.value)
                }
            }
            
            DatePicker(
                "Bắt đầu",
                selection: draft.startTime,
                in: ScanTimetableTimeValidator.allowedStartTimeRange(for: draft.wrappedValue.startTime),
                displayedComponents: .hourAndMinute
            )
            .onChange(of: draft.wrappedValue.startTime) { _, newValue in
                updateDraftStartTime(draft, newValue)
            }
            
            DatePicker(
                "Kết thúc",
                selection: draft.endTime,
                displayedComponents: .hourAndMinute
            )
            .onChange(of: draft.wrappedValue.endTime) { _, newValue in
                updateDraftEndTime(draft, newValue)
            }
            
            Text("Giờ bắt đầu chỉ được chọn từ 07:00 đến 22:00.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if let warningMessage = draftWarningMessage(for: draft.wrappedValue) {
                Label(warningMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            
            TextField("Phòng học", text: draft.room)
            
            TextField("Ghi chú", text: draft.note, axis: .vertical)
                .lineLimit(2...3)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private var resultView: some View {
        DisclosureGroup {
            ScrollView {
                Text(recognizedText)
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(12)
            }
            .frame(minHeight: 120, maxHeight: 220)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        } label: {
            Label("Xem text OCR gốc", systemImage: "text.viewfinder")
                .font(.subheadline.bold())
                .foregroundStyle(.blue)
        }
    }
    
    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            errorMessage = "Thiết bị này không hỗ trợ camera."
            return
        }
        
        isShowingCamera = true
    }
    
    @MainActor
    private func loadImageFromPhotoPicker(_ item: PhotosPickerItem) async {
        isProcessing = true
        errorMessage = nil
        successMessage = nil
        recognizedText = ""
        scheduleDrafts = []
        
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                throw ScanTimetableError.invalidImage
            }
            
            selectedImage = image
            await scanImage(image)
        } catch {
            errorMessage = error.localizedDescription
            isProcessing = false
        }
        
        selectedPhotoItem = nil
    }
    
    @MainActor
    private func scanImage(_ image: UIImage) async {
        isProcessing = true
        errorMessage = nil
        successMessage = nil
        recognizedText = ""
        scheduleDrafts = []

        do {
            let text = try await OCRService.extractText(from: image)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !text.isEmpty else {
                errorMessage = "Không đọc được chữ trong ảnh. Bạn thử chụp rõ hơn, đủ sáng hơn nhé."
                isProcessing = false
                return
            }

            recognizedText = text

            let response = try await TimetableAIService.shared.parseTimetable(from: text)
            

            print("===== AI RAW OUTPUT =====")
            print(response.rawOutput ?? "nil")

            print("===== AI ERROR =====")
            print(response.error ?? "nil")

            print("===== AI ITEMS =====")
            print(response.items)

            let drafts = response.items.compactMap { draft(from: $0) }

            print("===== VALID DRAFTS =====")
            print(drafts)
            
            if drafts.isEmpty {
                errorMessage = """
                Đã đọc được chữ nhưng AI chưa tìm thấy lịch học hợp lệ.

                Bạn mở “Xem text OCR gốc” để kiểm tra text OCR có đủ tên môn, thứ, giờ học không.
                """
            } else {
                scheduleDrafts = drafts.map { normalizedDraft($0) }
                successMessage = "Đã nhận diện \(drafts.count) lịch học. Bạn kiểm tra lại rồi bấm lưu."
            }
        } catch {
            errorMessage = friendlyErrorMessage(from: error)
        }

        isProcessing = false
    }
    
    private func draft(from item: TimetableAIItem) -> ScannedScheduleDraft? {
        let subjectName = item.subjectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !subjectName.isEmpty else {
            return nil
        }

        guard let startTime = dateFromTimeString(item.startTime),
              let endTime = dateFromTimeString(item.endTime) else {
            return nil
        }

        return ScannedScheduleDraft(
            subjectName: subjectName,
            weekday: item.weekday,
            startTime: startTime,
            endTime: endTime,
            room: item.room?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            note: item.note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        )
    }

    private func dateFromTimeString(_ timeString: String) -> Date? {
        let normalized = timeString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "h", with: ":")
            .replacingOccurrences(of: "g", with: ":")

        let parts = normalized.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]),
              (0...23).contains(hour),
              (0...59).contains(minute) else {
            return nil
        }

        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0

        return Calendar.current.date(from: components)
    }

    @MainActor
    private func saveScheduleDrafts() {
        guard !scheduleDrafts.isEmpty else {
            errorMessage = "Chưa có lịch để lưu."
            return
        }
        
        if let validationMessage = validateDraftsBeforeSaving() {
            errorMessage = validationMessage
            successMessage = nil
            return
        }
        
        var createdCount = 0
        
        for draft in scheduleDrafts {
            let subjectName = draft.subjectName.trimmingCharacters(in: .whitespacesAndNewlines)
            let subject = findOrCreateSubject(named: subjectName)
            
            let schedule = ClassSchedule(
                weekday: draft.weekday,
                startTime: ScanTimetableTimeValidator.clampedStartTime(draft.startTime),
                endTime: draft.endTime,
                room: cleanedOptional(draft.room),
                note: cleanedOptional(draft.note),
                source: .manual,
                subject: subject
            )
            
            modelContext.insert(schedule)
            createdCount += 1
        }
        
        do {
            try modelContext.save()
            scheduleDrafts = []
            successMessage = "Đã lưu \(createdCount) lịch học vào thời khóa biểu."
            errorMessage = nil
        } catch {
            errorMessage = "Không lưu được lịch học: \(error.localizedDescription)"
        }
    }
    
    private func normalizedDraft(_ draft: ScannedScheduleDraft) -> ScannedScheduleDraft {
        var normalizedDraft = draft
        normalizedDraft.startTime = ScanTimetableTimeValidator.clampedStartTime(draft.startTime)
        
        if !ScanTimetableTimeValidator.isStartBeforeEnd(
            normalizedDraft.startTime,
            normalizedDraft.endTime
        ) {
            normalizedDraft.endTime = ScanTimetableTimeValidator.suggestedEndTime(
                after: normalizedDraft.startTime
            )
        }
        
        return normalizedDraft
    }
    
    private func updateDraftStartTime(_ draft: Binding<ScannedScheduleDraft>, _ newValue: Date) {
        let clampedStartTime = ScanTimetableTimeValidator.clampedStartTime(newValue)
        
        if draft.wrappedValue.startTime != clampedStartTime {
            draft.wrappedValue.startTime = clampedStartTime
        }
        
        if !ScanTimetableTimeValidator.isStartBeforeEnd(
            draft.wrappedValue.startTime,
            draft.wrappedValue.endTime
        ) {
            draft.wrappedValue.endTime = ScanTimetableTimeValidator.suggestedEndTime(
                after: draft.wrappedValue.startTime
            )
        }
    }
    
    private func updateDraftEndTime(_ draft: Binding<ScannedScheduleDraft>, _ newValue: Date) {
        guard ScanTimetableTimeValidator.isStartBeforeEnd(
            draft.wrappedValue.startTime,
            newValue
        ) else {
            draft.wrappedValue.endTime = ScanTimetableTimeValidator.suggestedEndTime(
                after: draft.wrappedValue.startTime
            )
            return
        }
        
        draft.wrappedValue.endTime = newValue
    }
    
    private func validateDraftsBeforeSaving() -> String? {
        for (index, draft) in scheduleDrafts.enumerated() {
            if let message = validationMessage(for: draft, index: index) {
                return message
            }
        }
        
        return duplicatedDraftConflictMessage()
    }
    
    private func validationMessage(for draft: ScannedScheduleDraft, index: Int) -> String? {
        let prefix = "Dòng \(index + 1): "
        let subjectName = draft.subjectName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !subjectName.isEmpty else {
            return prefix + "vui lòng nhập tên môn học."
        }
        
        guard (1...7).contains(draft.weekday) else {
            return prefix + "thứ không hợp lệ."
        }
        
        guard ScanTimetableTimeValidator.isStartTimeAllowed(draft.startTime) else {
            return prefix + "giờ bắt đầu chỉ được chọn từ 07:00 đến 22:00."
        }
        
        guard ScanTimetableTimeValidator.isStartBeforeEnd(draft.startTime, draft.endTime) else {
            return prefix + "giờ bắt đầu phải trước giờ kết thúc."
        }
        
        if let conflictSchedule = findExistingTimeConflict(for: draft) {
            return prefix + conflictMessage(
                subjectName: subjectName,
                weekday: draft.weekday,
                conflictSubjectName: conflictSchedule.subject.name,
                conflictStartTime: conflictSchedule.startTime,
                conflictEndTime: conflictSchedule.endTime
            )
        }
        
        return nil
    }
    
    private func draftWarningMessage(for draft: ScannedScheduleDraft) -> String? {
        guard (1...7).contains(draft.weekday) else {
            return "Thứ không hợp lệ."
        }
        
        guard ScanTimetableTimeValidator.isStartTimeAllowed(draft.startTime) else {
            return "Giờ bắt đầu chỉ được chọn từ 07:00 đến 22:00."
        }
        
        guard ScanTimetableTimeValidator.isStartBeforeEnd(draft.startTime, draft.endTime) else {
            return "Giờ bắt đầu phải trước giờ kết thúc."
        }
        
        if let conflictSchedule = findExistingTimeConflict(for: draft) {
            return "Trùng với \(conflictSchedule.subject.name), \(formatTime(conflictSchedule.startTime)) - \(formatTime(conflictSchedule.endTime))."
        }
        
        return nil
    }
    
    private func findExistingTimeConflict(for draft: ScannedScheduleDraft) -> ClassSchedule? {
        classSchedules.first { existingSchedule in
            guard existingSchedule.weekday == draft.weekday else {
                return false
            }
            
            return ScanTimetableTimeValidator.isOverlapping(
                draft.startTime,
                draft.endTime,
                existingSchedule.startTime,
                existingSchedule.endTime
            )
        }
    }
    
    private func duplicatedDraftConflictMessage() -> String? {
        guard scheduleDrafts.count > 1 else {
            return nil
        }
        
        for firstIndex in scheduleDrafts.indices {
            for secondIndex in scheduleDrafts.indices where secondIndex > firstIndex {
                let firstDraft = scheduleDrafts[firstIndex]
                let secondDraft = scheduleDrafts[secondIndex]
                
                guard firstDraft.weekday == secondDraft.weekday else {
                    continue
                }
                
                if ScanTimetableTimeValidator.isOverlapping(
                    firstDraft.startTime,
                    firstDraft.endTime,
                    secondDraft.startTime,
                    secondDraft.endTime
                ) {
                    return "Dòng \(firstIndex + 1) bị trùng thời gian với dòng \(secondIndex + 1) vào \(weekdayTitle(firstDraft.weekday))."
                }
            }
        }
        
        return nil
    }
    
    private func conflictMessage(
        subjectName: String,
        weekday: Int,
        conflictSubjectName: String,
        conflictStartTime: Date,
        conflictEndTime: Date
    ) -> String {
        "Lịch \(subjectName) bị trùng với \(conflictSubjectName) vào \(weekdayTitle(weekday)), từ \(formatTime(conflictStartTime)) đến \(formatTime(conflictEndTime))."
    }
    
    private func weekdayTitle(_ weekday: Int) -> String {
        weekdayOptions.first { $0.value == weekday }?.title ?? "Thứ không rõ"
    }
    
    private func formatTime(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .locale(Locale(identifier: "vi_VN"))
                .hour()
                .minute()
        )
    }
    
    private func findOrCreateSubject(named name: String) -> Subject {
        if let existing = subjects.first(where: {
            $0.name
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare(name) == .orderedSame
        }) {
            return existing
        }
        
        let subject = Subject(name: name)
        modelContext.insert(subject)
        return subject
    }
    
    private func cleanedOptional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
    
    private func friendlyErrorMessage(from error: Error) -> String {
        let message = error.localizedDescription.lowercased()
        
        if message.contains("could not connect")
            || message.contains("connection refused")
            || message.contains("offline")
            || message.contains("network")
            || message.contains("cannot connect") {
            return "Không kết nối được AI server. Hãy chạy FastAPI server và kiểm tra endpoint trong TimetableAIService."
        }
        
        if message.contains("401")
            || message.contains("api key")
            || message.contains("unauthorized") {
            return "AI server chưa phản hồi hợp lệ. Bạn kiểm tra backend hoặc endpoint nhé."
        }
        
        if message.contains("429")
            || message.contains("rate limit")
            || message.contains("too many requests") {
            return "AI server đang giới hạn hoặc quá tải. Bạn thử lại sau một lát nhé."
        }
        
        if message.contains("503")
            || message.contains("unavailable")
            || message.contains("overloaded") {
            return "AI server đang quá tải tạm thời. Bạn thử lại sau vài giây nhé."
        }
        
        if message.contains("json")
            || message.contains("decode")
            || message.contains("định dạng") {
            return "AI đã đọc được nội dung nhưng trả về dữ liệu chưa đúng định dạng."
        }
        
        return error.localizedDescription
    }
}

private enum ScanTimetableTimeValidator {
    private static let calendar = Calendar.current
    private static let earliestStartMinute = 7 * 60
    private static let latestStartMinute = 22 * 60
    
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

private enum ScanTimetableError: LocalizedError {
    case invalidImage
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Không đọc được ảnh đã chọn."
        }
    }
}
