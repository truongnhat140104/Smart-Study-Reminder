import SwiftData

enum AppModelContainer {
    static let models: [any PersistentModel.Type] = [
        Subject.self,
        ClassSchedule.self,
        TaskItem.self,
        Tag.self,
        ChatMessage.self,
        AppSettings.self,
    ]
}
