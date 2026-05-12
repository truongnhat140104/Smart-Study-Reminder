import Foundation
import SwiftData
import SwiftUI

@Model
final class Subject {
    var id: UUID
    var name: String
    var code: String?
    var teacherName: String?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ClassSchedule.subject)
    var classSchedules: [ClassSchedule] = []

    init(
        id: UUID = UUID(),
        name: String,
        code: String? = nil,
        teacherName: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.code = code
        self.teacherName = teacherName
        self.createdAt = createdAt
    }
}

extension Subject {
    var displayColor: Color {
        let colors: [Color] = [
            .indigo,
            .blue,
            .green,
            .orange,
            .pink,
            .purple,
            .teal
        ]

        let index = abs(id.uuidString.hashValue) % colors.count
        return colors[index]
    }
}
