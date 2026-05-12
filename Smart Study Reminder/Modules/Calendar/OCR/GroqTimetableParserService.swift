//
//  GroqTimetableParserService.swift
//  Smart Study Reminder
//

import Foundation

final class GroqTimetableParserService {
    static let shared = GroqTimetableParserService()
    
    private init() {}
    
    func parseTimetable(from ocrText: String) async throws -> [ScannedScheduleDraft] {
        let prompt = """
        Bạn là bộ lọc dữ liệu thời khóa biểu cho app Smart Study Reminder.

        Hãy đọc text OCR và trả về JSON hợp lệ duy nhất.
        Không markdown. Không giải thích. Không bọc ```json.

        Schema JSON bắt buộc:
        {
          "schedules": [
            {
              "subjectName": "Tên môn học",
              "weekday": 2,
              "startTime": "HH:mm",
              "endTime": "HH:mm",
              "room": "Phòng học hoặc null",
              "note": "Ghi chú hoặc null"
            }
          ]
        }

        Quy đổi weekday:
        - Chủ nhật = 1
        - Thứ 2 = 2
        - Thứ 3 = 3
        - Thứ 4 = 4
        - Thứ 5 = 5
        - Thứ 6 = 6
        - Thứ 7 = 7

        Quy tắc:
        - Nếu không có phòng học thì room = null.
        - Nếu không có ghi chú thì note = null.
        - Nếu không tìm thấy lịch hợp lệ thì trả:
          { "schedules": [] }
        - Giờ phải là dạng 24h HH:mm, ví dụ "07:30", "13:00".
        - Nếu OCR có "7h30" thì đổi thành "07:30".
        - Nếu OCR có "13:00 - 15:50" thì tách startTime và endTime.
        - Chỉ lấy dữ liệu thật sự là lịch học.

        Text OCR:
        \(ocrText)
        """
        
        let responseText = try await GroqService.shared.sendMessage(prompt)
        let jsonString = extractJSONString(from: responseText)
        
        guard let data = jsonString.data(using: .utf8) else {
            throw GroqTimetableParserError.invalidJSON
        }
        
        do {
            let decoded = try JSONDecoder().decode(GroqTimetableResponse.self, from: data)
            
            return decoded.schedules.compactMap { item in
                guard let start = makeTimeDate(from: item.startTime),
                      let end = makeTimeDate(from: item.endTime),
                      start < end,
                      (1...7).contains(item.weekday),
                      !item.subjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    return nil
                }
                
                return ScannedScheduleDraft(
                    subjectName: item.subjectName,
                    weekday: item.weekday,
                    startTime: start,
                    endTime: end,
                    room: item.room ?? "",
                    note: item.note ?? ""
                )
            }
        } catch {
            print("Decode timetable JSON failed:", error.localizedDescription)
            print("Raw Groq output:", responseText)
            print("Cleaned JSON:", jsonString)
            throw GroqTimetableParserError.invalidJSON
        }
    }
    
    private func extractJSONString(from text: String) -> String {
        var output = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let start = output.firstIndex(of: "{"),
           let end = output.lastIndex(of: "}") {
            output = String(output[start...end])
        }
        
        return output
    }
    
    private func makeTimeDate(from timeText: String) -> Date? {
        let normalized = timeText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "h", with: ":")
        
        let parts = normalized.split(separator: ":")
        
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]),
              (0...23).contains(hour),
              (0...59).contains(minute) else {
            return nil
        }
        
        return Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: Date()
        )
    }
}

private struct GroqTimetableResponse: Decodable {
    let schedules: [GroqScheduleItem]
}

private struct GroqScheduleItem: Decodable {
    let subjectName: String
    let weekday: Int
    let startTime: String
    let endTime: String
    let room: String?
    let note: String?
    
    enum CodingKeys: String, CodingKey {
        case subjectName
        case subject
        case weekday
        case startTime
        case endTime
        case room
        case note
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.subjectName =
            try container.decodeIfPresent(String.self, forKey: .subjectName)
            ?? container.decodeIfPresent(String.self, forKey: .subject)
            ?? ""
        
        self.weekday = try container.decodeIfPresent(Int.self, forKey: .weekday) ?? 0
        self.startTime = try container.decodeIfPresent(String.self, forKey: .startTime) ?? ""
        self.endTime = try container.decodeIfPresent(String.self, forKey: .endTime) ?? ""
        self.room = try container.decodeIfPresent(String.self, forKey: .room)
        self.note = try container.decodeIfPresent(String.self, forKey: .note)
    }
}

enum GroqTimetableParserError: LocalizedError {
    case invalidJSON
    
    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "Groq trả về dữ liệu chưa đúng định dạng thời khóa biểu."
        }
    }
}
