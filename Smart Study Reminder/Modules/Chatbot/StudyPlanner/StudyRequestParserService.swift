//
//  StudyRequestParserService.swift
//  Smart Study Reminder
//

import Foundation

final class StudyRequestParserService {
    static let shared = StudyRequestParserService()
    
    private init() {}
    
    func parse(
        _ userText: String,
        defaultDurationMinutes: Int
    ) async throws -> StudyPlanRequest? {
        let prompt = """
        Bạn là bộ phân tích ý định cho app Smart Study Reminder.

        Hãy đọc câu người dùng và trả về JSON duy nhất, không markdown, không giải thích.

        Nếu người dùng muốn tạo một phiên học / nhắc học / học một môn trong một khoảng thời gian, trả về:
        {
          "intent": "create_study_plan",
          "subject": "Tên môn hoặc nội dung học",
          "durationMinutes": số phút,
          "dateRange": "today" | "tomorrow" | "weekend" | "thisWeek" | "nextWeek" | "unknown",
          "preferredPartOfDay": "morning" | "afternoon" | "evening" | "unknown"
        }

        Nếu không phải yêu cầu tạo phiên học, trả về:
        {
          "intent": "other",
          "subject": "",
          "durationMinutes": 0,
          "dateRange": "unknown",
          "preferredPartOfDay": "unknown"
        }

        Quy tắc:
        - Nếu người dùng có nói thời lượng, hãy dùng thời lượng người dùng nói.
        - Nếu người dùng muốn học nhưng không nói thời lượng, đặt durationMinutes = \(defaultDurationMinutes).
        - 1 tiếng = 60 phút.
        - 2 tiếng = 120 phút.
        - 3 tiếng = 180 phút.
        - 30 phút = 30 phút.
        - ngày mai = tomorrow.
        - hôm nay = today.
        - cuối tuần = weekend.
        - tuần này = thisWeek.
        - tuần sau = nextWeek.
        - sáng = morning.
        - chiều = afternoon.
        - tối = evening.

        Ví dụ 1:
        Người dùng: "tôi muốn học địa lý vào ngày mai"
        JSON:
        {
          "intent": "create_study_plan",
          "subject": "Địa lý",
          "durationMinutes": \(defaultDurationMinutes),
          "dateRange": "tomorrow",
          "preferredPartOfDay": "unknown"
        }

        Ví dụ 2:
        Người dùng: "tôi muốn học toán 2 tiếng vào cuối tuần"
        JSON:
        {
          "intent": "create_study_plan",
          "subject": "Toán",
          "durationMinutes": 120,
          "dateRange": "weekend",
          "preferredPartOfDay": "unknown"
        }

        Câu người dùng:
        \(userText)
        """
        
        let responseText = try await ChatbotAPIService.shared.sendMessage(prompt)
        
        guard let jsonString = extractJSONString(from: responseText),
              let data = jsonString.data(using: .utf8) else {
            return nil
        }
        
        var request = try JSONDecoder().decode(StudyPlanRequest.self, from: data)
        
        guard request.intent == "create_study_plan",
              !request.subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        
        if request.durationMinutes <= 0 {
            request.durationMinutes = defaultDurationMinutes
        }
        
        return request
    }
    
    private func extractJSONString(from text: String) -> String? {
        var output = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if output.hasPrefix("{"), output.hasSuffix("}") {
            return output
        }
        
        guard let start = output.firstIndex(of: "{"),
              let end = output.lastIndex(of: "}") else {
            return nil
        }
        
        output = String(output[start...end])
        return output
    }
}
