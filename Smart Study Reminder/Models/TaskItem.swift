import Foundation
import SwiftData

@Model
final class TaskItem {
    @Attribute(.unique)
    var id: UUID

    var title: String
    var detail: String?

    var startAt: Date
    var endAt: Date

    var status: TaskStatus
    var priority: TaskPriority

    var reminderAt: Date?
    var notificationIdentifier: String?

    var createdAt: Date
    var updatedAt: Date

    var tags: [Tag] = []

    init(
        id: UUID = UUID(),
        title: String,
        detail: String? = nil,
        startAt: Date,
        endAt: Date,
        status: TaskStatus = .notDone,
        priority: TaskPriority = .medium,
        reminderAt: Date? = nil,
        notificationIdentifier: String? = nil,
        tags: [Tag] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.startAt = startAt
        self.endAt = endAt
        self.status = status
        self.priority = priority
        self.reminderAt = reminderAt
        self.notificationIdentifier = notificationIdentifier
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
