//
//  OpenAIModels.swift
//  Smart Study Reminder
//

import Foundation

struct OpenAIResponsesRequest: Encodable {
    let model: String
    let input: [OpenAIInputMessage]
    let temperature: Double?
    let maxOutputTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case model
        case input
        case temperature
        case maxOutputTokens = "max_output_tokens"
    }
}

struct OpenAIInputMessage: Encodable {
    let role: String
    let content: [OpenAIInputContent]
}

struct OpenAIInputContent: Encodable {
    let type: String
    let text: String
}

struct OpenAIResponsesResponse: Decodable {
    let outputText: String?
    let output: [OpenAIOutputItem]?
    
    enum CodingKeys: String, CodingKey {
        case outputText = "output_text"
        case output
    }
}

struct OpenAIOutputItem: Decodable {
    let content: [OpenAIOutputContent]?
}

struct OpenAIOutputContent: Decodable {
    let type: String?
    let text: String?
}

struct OpenAIErrorResponse: Decodable {
    let error: OpenAIErrorDetail?
}

struct OpenAIErrorDetail: Decodable {
    let message: String?
    let type: String?
    let code: String?
}
