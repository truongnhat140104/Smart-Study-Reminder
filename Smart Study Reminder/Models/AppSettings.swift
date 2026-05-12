import Foundation
import SwiftData

@Model
final class AppSettings {
    @Attribute(.unique)
    var id: UUID

    var displayName: String?
    var defaultReminderMinutes: Int
    var preferredStudyDurationMinutes: Int
    var enableNotifications: Bool
    var enableCalendarSync: Bool

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        displayName: String? = nil,
        defaultReminderMinutes: Int = 15,
        preferredStudyDurationMinutes: Int = 60,
        enableNotifications: Bool = true,
        enableCalendarSync: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        self.defaultReminderMinutes = defaultReminderMinutes
        self.preferredStudyDurationMinutes = preferredStudyDurationMinutes
        self.enableNotifications = enableNotifications
        self.enableCalendarSync = enableCalendarSync
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
