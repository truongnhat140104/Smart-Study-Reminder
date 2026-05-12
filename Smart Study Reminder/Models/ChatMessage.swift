import Foundation
import SwiftData

@Model
final class ChatMessage {
    @Attribute(.unique)
    var id: UUID

    var content: String
    var role: ChatRole
    var createdAt: Date

    init(
        id: UUID = UUID(),
        content: String,
        role: ChatRole,
        createdAt: Date = .now
    ) {
        self.id = id
        self.content = content
        self.role = role
        self.createdAt = createdAt
    }
}

extension ChatMessage {
    var isFromUser: Bool {
        role == .user
    }
}
