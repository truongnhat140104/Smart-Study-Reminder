import Foundation

final class TimetableAIService {
    static let shared = TimetableAIService()

    private init() {}

    // Simulator dùng localhost được.
    // Nếu chạy trên iPhone thật, thay bằng IP máy Mac, ví dụ:
    // http://192.168.1.10:8000/parse-timetable
    private let endpoint = URL(string: "http://127.0.0.1:8000/parse-timetable")!

    func parseTimetable(from ocrText: String) async throws -> TimetableAIResponse {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = TimetableAIRequest(text: ocrText)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw TimetableAIError.badResponse
        }

        return try JSONDecoder().decode(TimetableAIResponse.self, from: data)
    }
}

enum TimetableAIError: LocalizedError {
    case badResponse

    var errorDescription: String? {
        switch self {
        case .badResponse:
            return "Server AI phản hồi không hợp lệ."
        }
    }
}
