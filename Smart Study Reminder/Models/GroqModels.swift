//
//  GroqModels.swift
//  Smart Study Reminder
//

import Foundation

struct GroqChatRequest: Encodable {
    let model: String
    let messages: [GroqMessage]
    let temperature: Double?
    let maxTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
    }
}

struct GroqMessage: Encodable {
    let role: String
    let content: String
}

struct GroqChatResponse: Decodable {
    let choices: [GroqChoice]
}

struct GroqChoice: Decodable {
    let message: GroqResponseMessage
}

struct GroqResponseMessage: Decodable {
    let role: String?
    let content: String?
}

struct GroqErrorResponse: Decodable {
    let error: GroqErrorDetail?
}

struct GroqErrorDetail: Decodable {
    let message: String?
    let type: String?
    let code: String?
}
