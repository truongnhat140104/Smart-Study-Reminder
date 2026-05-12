//
//  ChatbotAPIService.swift
//  Smart Study Reminder
//

import Foundation

final class ChatbotAPIService {
    static let shared = ChatbotAPIService()
    
    private init() {}
    
    func sendMessage(_ prompt: String) async throws -> String {
        try await GroqService.shared.sendMessage(prompt)
    }
    
    func generateResponse(prompt: String) async throws -> String {
        try await sendMessage(prompt)
    }
    
    func generateResponse(for prompt: String) async throws -> String {
        try await sendMessage(prompt)
    }
    
    func sendMessages(_ messages: [(role: String, text: String)]) async throws -> String {
        try await GroqService.shared.sendMessages(messages)
    }
}
