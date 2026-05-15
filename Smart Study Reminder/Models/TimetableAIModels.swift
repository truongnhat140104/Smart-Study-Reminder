import Foundation

struct TimetableAIRequest: Codable {
    let text: String
}

struct TimetableAIResponse: Codable {
    let items: [TimetableAIItem]
    let rawOutput: String?
    let error: String?
}

struct TimetableAIItem: Codable, Identifiable {
    var id: UUID = UUID()

    let subjectName: String
    let weekday: Int
    let startTime: String
    let endTime: String
    let room: String?
    let note: String?

    enum CodingKeys: String, CodingKey {
        case subjectName
        case weekday
        case startTime
        case endTime
        case room
        case note
    }
}
