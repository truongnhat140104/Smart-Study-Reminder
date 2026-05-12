//
//  ClassSchedule.swift
//  Smart Study Reminder
//
//

import Foundation
import SwiftData

@Model
final class ClassSchedule {
    var id: UUID
    var weekday: Int
    var startTime: Date
    var endTime: Date
    var room: String?
    var note: String?
    var source: ClassSource
    var createdAt: Date

    var subject: Subject

    init(
        id: UUID = UUID(),
        weekday: Int,
        startTime: Date,
        endTime: Date,
        room: String? = nil,
        note: String? = nil,
        source: ClassSource = .manual,
        subject: Subject,
        createdAt: Date = .now
    ) {
        self.id = id
        self.weekday = weekday
        self.startTime = startTime
        self.endTime = endTime
        self.room = room
        self.note = note
        self.source = source
        self.subject = subject
        self.createdAt = createdAt
    }
}
