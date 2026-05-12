//
//  GroqService.swift
//  Smart Study Reminder
//

import Foundation

enum GroqServiceError: LocalizedError {
    case invalidResponse
    case emptyResponse
    case apiError(statusCode: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Phản hồi Groq không hợp lệ."
        case .emptyResponse:
            return "Groq không trả về nội dung."
        case .apiError(let statusCode, let message):
            return "Groq API lỗi \(statusCode): \(message)"
        }
    }
}

final class GroqService {
    static let shared = GroqService()
    
    private let urlSession: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    func sendMessage(_ prompt: String) async throws -> String {
        let requestBody = GroqChatRequest(
            model: GroqConfig.model,
            messages: [
                GroqMessage(
                    role: "system",
                    content: """
                    Bạn là trợ lý học tập trong app Smart Study Reminder.
                    Hãy trả lời bằng tiếng Việt, ngắn gọn, rõ ràng, thân thiện.
                    Nếu dữ liệu app không có thông tin, hãy nói rõ là chưa có dữ liệu.
                    Không tự ý nói đã tạo, đã lưu, đã xóa nếu app chưa thực hiện thao tác đó.
                    """
                ),
                GroqMessage(
                    role: "user",
                    content: prompt
                )
            ],
            temperature: 0.4,
            maxTokens: 1024
        )
        
        return try await send(requestBody)
    }
    
    func sendMessages(_ messages: [(role: String, text: String)]) async throws -> String {
        let groqMessages = messages.map { item in
            GroqMessage(
                role: mapRole(item.role),
                content: item.text
            )
        }
        
        let requestBody = GroqChatRequest(
            model: GroqConfig.model,
            messages: groqMessages,
            temperature: 0.4,
            maxTokens: 1024
        )
        
        return try await send(requestBody)
    }
    
    private func send(_ requestBody: GroqChatRequest) async throws -> String {
        var request = URLRequest(url: GroqConfig.endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(GroqConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(requestBody)
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GroqServiceError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw GroqServiceError.apiError(
                statusCode: httpResponse.statusCode,
                message: decodeErrorMessage(from: data)
            )
        }
        
        let decoded = try decoder.decode(GroqChatResponse.self, from: data)
        
        guard let text = decoded.choices.first?.message.content?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            throw GroqServiceError.emptyResponse
        }
        
        return text
    }
    
    private func decodeErrorMessage(from data: Data) -> String {
        if let decoded = try? decoder.decode(GroqErrorResponse.self, from: data),
           let message = decoded.error?.message {
            return message
        }
        
        return String(data: data, encoding: .utf8) ?? "Không rõ lỗi từ Groq."
    }
    
    private func mapRole(_ role: String) -> String {
        switch role.lowercased() {
        case "assistant":
            return "assistant"
        case "system", "developer":
            return "system"
        default:
            return "user"
        }
    }
}
