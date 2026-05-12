//
//  ChatbotView.swift
//  Smart Study Reminder
//

import SwiftUI
import SwiftData

struct ChatbotView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ChatMessage.createdAt, order: .forward)
    private var messages: [ChatMessage]

    @Query(sort: \TaskItem.startAt, order: .forward)
    private var tasks: [TaskItem]

    @Query(sort: \ClassSchedule.startTime, order: .forward)
    private var classSchedules: [ClassSchedule]

    @Query private var appSettings: [AppSettings]

    @State private var inputText: String = ""
    @State private var isSending = false

    // Dùng cho GA: "Sắp lịch học cho tôi tuần này"
    @State private var pendingScheduleResults: [TaskScheduleResult] = []

    // Dùng cho flow: "Tôi muốn học Toán 2 tiếng vào cuối tuần"
    @State private var pendingStudyRequest: StudyPlanRequest?
    @State private var pendingStudySlots: [StudySlotCandidate] = []

    @FocusState private var isInputFocused: Bool

    private let apiService = ChatbotAPIService.shared
    private let studyRequestParser = StudyRequestParserService.shared
    private let studySlotFinder = StudySlotFinder()

    private let scheduler = GeneticScheduler()
    private let calendar = Calendar.current

    private let quickActions: [(title: String, icon: String, prompt: String)] = [
        ("Tìm giờ học", "clock.badge.checkmark", "Tôi muốn học Toán 2 tiếng vào cuối tuần"),
        ("Lịch học hôm nay", "sun.max", "Lịch học hôm nay?"),
        ("Xem công việc", "checklist", "Hôm nay tôi có công việc gì?")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView

                Divider()

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(messages, id: \.id) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            if isSending {
                                typingBubble
                            }
                        }
                        .padding()
                    }
                    .background(Color(.systemGroupedBackground))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isInputFocused = false
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onAppear {
                        createWelcomeMessageIfNeeded()
                        scrollToBottom(with: proxy, animated: false)
                    }
                    .onChange(of: messages.count) { _, _ in
                        scrollToBottom(with: proxy)
                    }
                    .onChange(of: isSending) { _, _ in
                        scrollToBottom(with: proxy)
                    }
                }

                if !pendingScheduleResults.isEmpty {
                    applyScheduleView
                }

                if !pendingStudySlots.isEmpty {
                    studySlotSelectionView
                }

                Divider()

                quickActionsView

                ChatInputBar(
                    text: $inputText,
                    onSend: sendMessage,
                    isFocused: $isInputFocused
                )
                .disabled(isSending)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
        }
    }

    private var headerView: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 48, height: 48)

                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Study Assistant")
                    .font(.headline)

                HStack(spacing: 6) {
                    Circle()
                        .fill(isSending ? .orange : .green)
                        .frame(width: 8, height: 8)

                    Text(isSending ? "Đang trả lời..." : "Đang hoạt động")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Menu {
                Button(role: .destructive) {
                    deleteAllMessages()
                } label: {
                    Label("Xóa hội thoại", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var quickActionsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(quickActions, id: \.title) { item in
                    QuickActionChip(
                        title: item.title,
                        icon: item.icon
                    ) {
                        sendQuickAction(item.prompt)
                    }
                    .disabled(isSending)
                }
            }
            .padding([.top, .leading, .trailing], 10)
        }
    }

    private var typingBubble: some View {
        HStack {
            Text("Đang suy nghĩ...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )

            Spacer(minLength: 40)
        }
    }

    private var applyScheduleView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.purple.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.purple)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Lịch tự động đã đề xuất")
                        .font(.headline)

                    Text("\(pendingScheduleResults.count) công việc đã được sắp xếp")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(pendingScheduleResults.prefix(3)) { result in
                    HStack(spacing: 10) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundStyle(.purple)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(result.task.title)
                                .font(.subheadline.bold())
                                .lineLimit(1)

                            Text("\(formatDateShort(result.startAt)) \(formatTime(result.startAt)) - \(formatTime(result.endAt))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(10)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                if pendingScheduleResults.count > 3 {
                    Text("+ \(pendingScheduleResults.count - 3) công việc khác")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            HStack(spacing: 10) {
                Button {
                    isInputFocused = false
                    pendingScheduleResults.removeAll()
                    addMessage("Mình đã hủy lịch đề xuất. Bạn có thể yêu cầu mình lập lịch lại.", role: .assistant)
                } label: {
                    Text("Hủy")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .foregroundStyle(.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    isInputFocused = false
                    applyGeneratedSchedule()
                } label: {
                    Label("Áp dụng", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.purple.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
    
    private var studySlotSelectionView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Chọn khung giờ học")
                        .font(.headline)

                    if let pendingStudyRequest {
                        Text("Học \(pendingStudyRequest.subject) trong \(pendingStudyRequest.durationMinutes) phút")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Chọn một khung giờ phù hợp")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            VStack(spacing: 10) {
                ForEach(Array(pendingStudySlots.enumerated()), id: \.element.id) { index, slot in
                    Button {
                        isInputFocused = false
                        acceptStudySlot(at: index)
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.12))
                                    .frame(width: 34, height: 34)

                                Text("\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.blue)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Khung giờ \(index + 1)")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.primary)

                                Text("\(formatDateShort(slot.startAt)) \(formatTime(slot.startAt)) - \(formatTime(slot.endAt))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "checkmark.circle")
                                .font(.title3)
                                .foregroundStyle(.blue)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                isInputFocused = false
                cancelPendingStudyPlan()
            } label: {
                Text("Hủy đề xuất")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .foregroundStyle(.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, !isSending else { return }

        isInputFocused = false

        addMessage(trimmedText, role: .user)
        inputText = ""

        Task {
            await handleUserMessage(trimmedText)
        }
    }

    private func sendQuickAction(_ prompt: String) {
        guard !isSending else { return }

        isInputFocused = false

        addMessage(prompt, role: .user)

        Task {
            await handleUserMessage(prompt)
        }
    }

    @MainActor
    private func handleUserMessage(_ text: String) async {
        if let selectedIndex = selectedSlotIndex(from: text),
           !pendingStudySlots.isEmpty {
            acceptStudySlot(at: selectedIndex)
            return
        }

        if isAutoScheduleRequest(text) {
            generateScheduleFromChat()
            return
        }
        
        if isTodayTaskQuestion(text) {
            replyTodayTasks()
            return
        }
        
        if isTodayClassScheduleQuestion(text) {
            replyTodayClassSchedules()
            return
        }

        if mightBeStudyPlanRequest(text) {
            let handled = await handleStudyPlanRequest(text)

            if handled {
                return
            }
        }

        await sendMessageToAPI(text)
    }

    @MainActor
    private func sendMessageToAPI(_ text: String) async {
        isSending = true

        do {
            let context = ChatbotContextBuilder.build(
                tasks: tasks,
                classSchedules: classSchedules,
                appSettings: appSettings
            )

            let prompt = buildOpenAIPrompt(
                userText: text,
                appContext: context,
                recentMessages: Array(messages.suffix(10))
            )

            let reply = try await apiService.sendMessage(prompt)

            addMessage(reply, role: .assistant)
        } catch {
            addMessage(
                friendlyAPIErrorMessage(from: error),
                role: .assistant
            )
        }

        isSending = false
    }

    private func buildOpenAIPrompt(
        userText: String,
        appContext: String,
        recentMessages: [ChatMessage]
    ) -> String {
        let recentConversation = recentMessages.map { message in
            let roleText = message.role == .user ? "Người dùng" : "Trợ lý"
            return "\(roleText): \(message.content)"
        }
        .joined(separator: "\n")

        return """
        Bạn là trợ lý học tập trong app Smart Study Reminder.
        Hãy trả lời bằng tiếng Việt, ngắn gọn, rõ ràng, thân thiện.
        Dựa vào dữ liệu trong app nếu câu hỏi liên quan đến lịch học, công việc, lớp học hoặc cài đặt học tập.

        Quy tắc:
        - Nếu người dùng hỏi lịch học, công việc, deadline, hãy trả lời dựa trên dữ liệu app.
        - Nếu dữ liệu app chưa có thông tin, hãy nói rõ là chưa có dữ liệu.
        - Không tự ý nói đã tạo, đã lưu, đã xóa nếu app chưa thực hiện thao tác đó.
        - Nếu người dùng muốn tạo phiên học, app sẽ tự tìm khung giờ rảnh và hỏi người dùng chọn.

        Dữ liệu hiện tại trong app:
        \(appContext)

        Hội thoại gần đây:
        \(recentConversation)

        Câu hỏi mới của người dùng:
        \(userText)
        """
    }

    private func isAutoScheduleRequest(_ text: String) -> Bool {
        let lowercased = text.lowercased()

        return lowercased.contains("sắp lịch")
            || lowercased.contains("xếp lịch")
            || lowercased.contains("lập lịch tự động")
            || lowercased.contains("tự động lập lịch")
            || lowercased.contains("tối ưu lịch")
    }

    private func mightBeStudyPlanRequest(_ text: String) -> Bool {
        let lowercased = text.lowercased()

        let hasStudyWord = lowercased.contains("học")
            || lowercased.contains("ôn")
            || lowercased.contains("luyện")

        let hasDateOrTimeWord = lowercased.contains("tiếng")
            || lowercased.contains("phút")
            || lowercased.contains("giờ")
            || lowercased.contains("hôm nay")
            || lowercased.contains("ngày mai")
            || lowercased.contains("mai")
            || lowercased.contains("cuối tuần")
            || lowercased.contains("tuần này")
            || lowercased.contains("tuần sau")
            || lowercased.contains("tuần")

        return hasStudyWord && hasDateOrTimeWord
    }

    @MainActor
    private func handleStudyPlanRequest(_ text: String) async -> Bool {
        isSending = true

        do {
            let settings = getOrCreateAppSettings()
            
            guard let request = try await studyRequestParser.parse(
                text,
                defaultDurationMinutes: settings.preferredStudyDurationMinutes
            ) else {
                isSending = false
                return false
            }

            let slots = studySlotFinder.findSlots(
                request: request,
                tasks: tasks,
                classSchedules: classSchedules,
                maxResults: 3
            )

            isSending = false

            if slots.isEmpty {
                addMessage(
                    "Mình chưa tìm thấy khung giờ rảnh phù hợp để học \(request.subject) trong \(request.durationMinutes) phút.",
                    role: .assistant
                )
                return true
            }

            pendingStudyRequest = request
            pendingStudySlots = slots

            addMessage(
                studySlotSuggestionText(
                    request: request,
                    slots: slots
                ),
                role: .assistant
            )

            return true
        } catch {
            isSending = false
            
            addMessage(
                friendlyAPIErrorMessage(from: error),
                role: .assistant
            )

            return true
        }
    }

    private func studySlotSuggestionText(
        request: StudyPlanRequest,
        slots: [StudySlotCandidate]
    ) -> String {
        let slotText = slots.enumerated().map { index, slot in
            "\(index + 1). \(formatDateShort(slot.startAt)) \(formatTime(slot.startAt)) - \(formatTime(slot.endAt))"
        }
        .joined(separator: "\n")

        return """
        Mình tìm được các khung giờ phù hợp để học \(request.subject) trong \(request.durationMinutes) phút:

        \(slotText)

        Bạn có thể bấm chọn khung giờ bên dưới hoặc nhắn "chọn 1", "chọn 2".
        """
    }

    private func selectedSlotIndex(from text: String) -> Int? {
        let lowercased = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if lowercased.contains("chọn 1") || lowercased == "1" {
            return 0
        }

        if lowercased.contains("chọn 2") || lowercased == "2" {
            return 1
        }

        if lowercased.contains("chọn 3") || lowercased == "3" {
            return 2
        }

        if lowercased.contains("đồng ý")
            || lowercased.contains("ok")
            || lowercased.contains("được") {
            return 0
        }

        return nil
    }

    private func acceptStudySlot(at index: Int) {
        guard pendingStudySlots.indices.contains(index),
              let request = pendingStudyRequest else {
            return
        }

        let slot = pendingStudySlots[index]
        let settings = getOrCreateAppSettings()

        let reminderAt = calendar.date(
            byAdding: .minute,
            value: -settings.defaultReminderMinutes,
            to: slot.startAt
        )

        let task = TaskItem(
            title: "Học \(request.subject)",
            detail: "Tạo từ Study Assistant",
            startAt: slot.startAt,
            endAt: slot.endAt,
            status: .notDone,
            priority: .medium,
            reminderAt: reminderAt,
            notificationIdentifier: nil
        )

        modelContext.insert(task)
        
        if settings.enableNotifications,
           let reminderAt,
           reminderAt > Date() {
            NotificationManager.shared.scheduleTaskReminder(for: task)
        }

        do {
            try modelContext.save()
        } catch {
            addMessage(
                "Mình đã tạo lịch học nhưng chưa lưu được: \(error.localizedDescription)",
                role: .assistant
            )
            return
        }

        pendingStudyRequest = nil
        pendingStudySlots.removeAll()

        addMessage(
            """
            Mình đã tạo công việc học \(request.subject):

            \(formatDateShort(slot.startAt)) \(formatTime(slot.startAt)) - \(formatTime(slot.endAt))

            Nhắc trước \(settings.defaultReminderMinutes) phút.
            """,
            role: .assistant
        )
    }

    private func cancelPendingStudyPlan() {
        pendingStudyRequest = nil
        pendingStudySlots.removeAll()

        addMessage(
            "Mình đã hủy đề xuất khung giờ học.",
            role: .assistant
        )
    }

    private func generateScheduleFromChat() {
        let settings = getOrCreateAppSettings()
        let startDate = Date()
        let endDate = calendar.date(byAdding: .day, value: 7, to: startDate) ?? startDate

        let results = scheduler.generateSchedule(
            tasks: tasks,
            classSchedules: classSchedules,
            settings: settings,
            from: startDate,
            to: endDate
        )

        if results.isEmpty {
            addMessage(
                "Mình chưa tìm được lịch phù hợp. Có thể bạn chưa có công việc cần sắp lịch hoặc tuần này quá kín.",
                role: .assistant
            )
            return
        }

        pendingScheduleResults = results

        addMessage(
            scheduleResultText(results),
            role: .assistant
        )
    }

    private func applyGeneratedSchedule() {
        for result in pendingScheduleResults {
            result.task.startAt = result.startAt
            result.task.endAt = result.endAt
            result.task.updatedAt = .now
        }

        pendingScheduleResults.removeAll()

        try? modelContext.save()

        addMessage(
            "Mình đã áp dụng lịch đề xuất vào danh sách công việc của bạn.",
            role: .assistant
        )
    }

    private func scheduleResultText(_ results: [TaskScheduleResult]) -> String {
        let text = results.map { result in
            """
            - \(result.task.title)
              \(formatDateShort(result.startAt)) \(formatTime(result.startAt)) - \(formatTime(result.endAt))
            """
        }
        .joined(separator: "\n\n")

        return """
        Mình đã tạo lịch học đề xuất cho bạn:

        \(text)

        Nếu thấy hợp lý, hãy bấm “Áp dụng lịch đề xuất”.
        """
    }

    private func createWelcomeMessageIfNeeded() {
        guard messages.isEmpty else { return }

        addMessage(
            """
            Chào bạn! Mình là trợ lý học tập của bạn.

            Mình có thể:
            - Trả lời câu hỏi dựa trên dữ liệu trong app.
            - Tìm khung giờ rảnh để tạo công việc.
            - Tự động sắp lịch học.
            """,
            role: .assistant
        )
    }

    private func addMessage(_ content: String, role: ChatRole) {
        let message = ChatMessage(
            content: content,
            role: role
        )

        modelContext.insert(message)
        try? modelContext.save()
    }

    private func deleteAllMessages() {
        isInputFocused = false

        for message in messages {
            modelContext.delete(message)
        }

        pendingScheduleResults.removeAll()
        pendingStudyRequest = nil
        pendingStudySlots.removeAll()

        try? modelContext.save()
    }

    private func getOrCreateAppSettings() -> AppSettings {
        if let settings = appSettings.first {
            return settings
        }

        let settings = AppSettings()
        modelContext.insert(settings)
        try? modelContext.save()

        return settings
    }

    private func scrollToBottom(with proxy: ScrollViewProxy, animated: Bool = true) {
        guard let lastMessage = messages.last else { return }

        if animated {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
    
    private func friendlyAPIErrorMessage(from error: Error) -> String {
        let message = error.localizedDescription.lowercased()
        
        if message.contains("503")
            || message.contains("unavailable")
            || message.contains("high demand")
            || message.contains("overloaded")
            || message.contains("quá tải") {
            return "Hiện tại AI đang quá tải. Bạn thử lại sau vài giây nhé."
        }
        
        if message.contains("429")
            || message.contains("rate limit")
            || message.contains("quota")
            || message.contains("too many requests") {
            return "API đang bị giới hạn lượt gọi. Bạn chờ một lát rồi thử lại nhé."
        }
        
        if message.contains("401")
            || message.contains("unauthorized")
            || message.contains("api key")
            || message.contains("invalid key") {
            return "API key chưa hợp lệ. Bạn kiểm tra lại cấu hình API nhé."
        }
        
        if message.contains("403")
            || message.contains("permission")
            || message.contains("forbidden") {
            return "API key hiện không có quyền dùng model này. Bạn kiểm tra lại model hoặc quyền truy cập API."
        }
        
        if message.contains("network")
            || message.contains("internet")
            || message.contains("offline")
            || message.contains("timed out")
            || message.contains("cannot connect") {
            return "Kết nối mạng đang không ổn định. Bạn kiểm tra Internet rồi thử lại nhé."
        }
        
        if message.contains("json")
            || message.contains("decode")
            || message.contains("data couldn’t be read")
            || message.contains("định dạng") {
            return "AI đã phản hồi nhưng dữ liệu chưa đúng định dạng. Bạn thử nhập lại rõ hơn nhé."
        }
        
        return "Mình chưa xử lý được yêu cầu này lúc này. Bạn thử lại sau nhé."
    }
    
    private func isTodayTaskQuestion(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        
        let asksToday = lowercased.contains("hôm nay")
            || lowercased.contains("today")
        
        let asksTask = lowercased.contains("công việc")
            || lowercased.contains("việc")
            || lowercased.contains("task")
            || lowercased.contains("deadline")
            || lowercased.contains("lời nhắc")
        
        return asksToday && asksTask
    }
    
    private func isTodayClassScheduleQuestion(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        
        let asksToday = lowercased.contains("hôm nay")
            || lowercased.contains("today")
        
        let asksSchedule = lowercased.contains("lịch học")
            || lowercased.contains("lịch")
            || lowercased.contains("môn")
            || lowercased.contains("học gì")
            || lowercased.contains("phòng")
            || lowercased.contains("lớp")
        
        return asksToday && asksSchedule
    }
    
    private func replyTodayClassSchedules() {
        let todayWeekday = calendar.component(.weekday, from: Date())
        
        let todaySchedules = classSchedules
            .filter { schedule in
                schedule.weekday == todayWeekday
            }
            .sorted { $0.startTime < $1.startTime }
        
        if todaySchedules.isEmpty {
            addMessage(
                "Hôm nay bạn không có lịch học.",
                role: .assistant
            )
            return
        }
        
        let scheduleText = todaySchedules.enumerated().map { index, schedule in
            let subjectName = schedule.subject.name
            let roomText = schedule.room ?? "Chưa có phòng"
            
            var text = """
            \(index + 1). \(subjectName)
               \(formatTime(schedule.startTime)) - \(formatTime(schedule.endTime))
               Phòng: \(roomText)
            """
            
            if let note = schedule.note,
               !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                text += "\n   Ghi chú: \(note)"
            }
            
            return text
        }
        .joined(separator: "\n\n")
        
        addMessage(
            """
            Hôm nay bạn có \(todaySchedules.count) lịch học:

            \(scheduleText)
            """,
            role: .assistant
        )
    }
    
    private func replyTodayTasks() {
        let todayTasks = tasks
            .filter { task in
                calendar.isDateInToday(task.startAt)
            }
            .sorted { $0.startAt < $1.startAt }
        
        if todayTasks.isEmpty {
            addMessage(
                "Hôm nay bạn chưa có công việc nào.",
                role: .assistant
            )
            return
        }
        
        let taskText = todayTasks.enumerated().map { index, task in
            let statusText = task.status == .done ? "Đã hoàn thành" : "Chưa hoàn thành"
            
            var text = """
            \(index + 1). \(task.title)
               \(formatTime(task.startAt)) - \(formatTime(task.endAt))
               Ưu tiên: \(task.priority.title) • \(statusText)
            """
            
            if let detail = task.detail,
               !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                text += "\n   Ghi chú: \(detail)"
            }
            
            return text
        }
        .joined(separator: "\n\n")
        
        addMessage(
            """
            Hôm nay bạn có \(todayTasks.count) công việc:

            \(taskText)
            """,
            role: .assistant
        )
    }

    private func formatTime(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .locale(Locale(identifier: "vi_VN"))
                .hour()
                .minute()
        )
    }

    private func formatDateShort(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .locale(Locale(identifier: "vi_VN"))
                .day()
                .month()
        )
    }
}

#Preview {
    ChatbotView()
        .modelContainer(for: AppModelContainer.models)
}
