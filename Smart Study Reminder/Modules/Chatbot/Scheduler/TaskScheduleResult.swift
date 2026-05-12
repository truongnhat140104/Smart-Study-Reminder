//
//  TaskScheduleResult.swift
//  Smart Study Reminder
//

import Foundation

struct TaskScheduleResult: Identifiable {
    let id = UUID()
    let task: TaskItem
    let startAt: Date
    let endAt: Date
}

struct TimeSlot {
    var start: Date
    var end: Date
    
    var durationMinutes: Int {
        Calendar.current.dateComponents([.minute], from: start, to: end).minute ?? 0
    }
}
