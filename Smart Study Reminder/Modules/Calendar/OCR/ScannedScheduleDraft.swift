//
//  ScannedScheduleDraft.swift
//  Smart Study Reminder
//

import Foundation

struct ScannedScheduleDraft: Identifiable, Hashable {
    let id = UUID()
    
    var subjectName: String
    var weekday: Int
    var startTime: Date
    var endTime: Date
    var room: String
    var note: String
}
