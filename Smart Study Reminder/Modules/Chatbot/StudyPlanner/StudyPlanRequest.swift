//
//  StudyPlanRequest.swift
//  Smart Study Reminder
//

import Foundation

enum StudyDateRange: String, Codable {
    case today
    case tomorrow
    case weekend
    case thisWeek
    case nextWeek
    case unknown
}

enum StudyPartOfDay: String, Codable {
    case morning
    case afternoon
    case evening
    case unknown
}

struct StudyPlanRequest: Codable {
    var intent: String
    var subject: String
    var durationMinutes: Int
    var dateRange: StudyDateRange
    var preferredPartOfDay: StudyPartOfDay?
}

struct StudySlotCandidate: Identifiable, Hashable {
    let id = UUID()
    let startAt: Date
    let endAt: Date
    
    var durationMinutes: Int {
        Calendar.current.dateComponents([.minute], from: startAt, to: endAt).minute ?? 0
    }
}
