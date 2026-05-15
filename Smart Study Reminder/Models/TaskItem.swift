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

    var reminderOffsetMinutes: Int?
    var notificationIdentifier: String?
    
    var repeatRule: TaskRepeatRule

    var earlyReminderOffsetMinutes: Int?
    var earlyNotificationIdentifier: String?

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
        reminderOffsetMinutes: Int? = nil,
        notificationIdentifier: String? = nil,
        repeatRule: TaskRepeatRule = .none,
        earlyReminderOffsetMinutes: Int? = nil,
        earlyNotificationIdentifier: String? = nil,
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
        self.reminderOffsetMinutes = reminderOffsetMinutes
        self.notificationIdentifier = notificationIdentifier
        self.repeatRule = repeatRule
        self.earlyReminderOffsetMinutes = earlyReminderOffsetMinutes
        self.earlyNotificationIdentifier = earlyNotificationIdentifier
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
