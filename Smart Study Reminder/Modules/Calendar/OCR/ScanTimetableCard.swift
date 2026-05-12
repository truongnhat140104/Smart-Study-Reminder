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
                
                Text("OCR ảnh TKB, Groq lọc lịch, bạn kiểm tra rồi lưu")
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
                displayedComponents: .hourAndMinute
            )
            
            DatePicker(
                "Kết thúc",
                selection: draft.endTime,
                displayedComponents: .hourAndMinute
            )
            
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
            
            let drafts = try await GroqTimetableParserService.shared.parseTimetable(from: text)
            
            if drafts.isEmpty {
                errorMessage = "Đã đọc được chữ nhưng Groq chưa tìm thấy lịch học hợp lệ."
            } else {
                scheduleDrafts = drafts
                successMessage = "Đã nhận diện \(drafts.count) lịch học. Bạn kiểm tra lại rồi bấm lưu."
            }
        } catch {
            errorMessage = friendlyErrorMessage(from: error)
        }
        
        isProcessing = false
    }
    
    @MainActor
    private func saveScheduleDrafts() {
        var createdCount = 0
        
        for draft in scheduleDrafts {
            let subjectName = draft.subjectName.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !subjectName.isEmpty else {
                continue
            }
            
            guard (1...7).contains(draft.weekday),
                  draft.startTime < draft.endTime else {
                continue
            }
            
            let subject = findOrCreateSubject(named: subjectName)
            
            let schedule = ClassSchedule(
                weekday: draft.weekday,
                startTime: draft.startTime,
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
            if createdCount > 0 {
                try modelContext.save()
                scheduleDrafts = []
                successMessage = "Đã lưu \(createdCount) lịch học vào thời khóa biểu."
                errorMessage = nil
            } else {
                errorMessage = "Chưa có lịch hợp lệ để lưu."
            }
        } catch {
            errorMessage = "Không lưu được lịch học: \(error.localizedDescription)"
        }
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
        
        if message.contains("401")
            || message.contains("api key")
            || message.contains("unauthorized") {
            return "Groq API key chưa hợp lệ. Bạn kiểm tra lại GroqConfig nhé."
        }
        
        if message.contains("429")
            || message.contains("rate limit")
            || message.contains("too many requests") {
            return "Groq đang giới hạn lượt gọi. Bạn thử lại sau một lát nhé."
        }
        
        if message.contains("503")
            || message.contains("unavailable")
            || message.contains("overloaded") {
            return "AI đang quá tải tạm thời. Bạn thử lại sau vài giây nhé."
        }
        
        if message.contains("json")
            || message.contains("decode")
            || message.contains("định dạng") {
            return "AI đã đọc được nội dung nhưng trả về dữ liệu chưa đúng định dạng."
        }
        
        return error.localizedDescription
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

#Preview {
    ScanTimetableCard()
        .modelContainer(for: AppModelContainer.models)
}
