//
//  StudySlotFinder.swift
//  Smart Study Reminder
//

import Foundation

final class StudySlotFinder {
    private let calendar = Calendar.current
    
    func findSlots(
        request: StudyPlanRequest,
        tasks: [TaskItem],
        classSchedules: [ClassSchedule],
        maxResults: Int = 3
    ) -> [StudySlotCandidate] {
        let days = candidateDays(for: request.dateRange)
        var candidates: [StudySlotCandidate] = []
        
        for day in days {
            let freeSlots = freeSlotsForDay(
                day,
                tasks: tasks,
                classSchedules: classSchedules
            )
            
            for slot in freeSlots {
                guard slot.durationMinutes >= request.durationMinutes else {
                    continue
                }
                
                guard let endAt = calendar.date(
                    byAdding: .minute,
                    value: request.durationMinutes,
                    to: slot.start
                ) else {
                    continue
                }
                
                let candidate = StudySlotCandidate(
                    startAt: slot.start,
                    endAt: endAt
                )
                
                candidates.append(candidate)
            }
        }
        
        return candidates
            .filter { matchesPreferredPartOfDay($0, preferredPartOfDay: request.preferredPartOfDay) }
            .sorted { $0.startAt < $1.startAt }
            .prefix(maxResults)
            .map { $0 }
    }
    
    private func candidateDays(for range: StudyDateRange) -> [Date] {
        let today = calendar.startOfDay(for: Date())
        
        switch range {
        case .today:
            return [today]
            
        case .tomorrow:
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) {
                return [tomorrow]
            }
            return [today]
            
        case .weekend:
            return nextDays(count: 14)
                .filter {
                    let weekday = calendar.component(.weekday, from: $0)
                    return weekday == 7 || weekday == 1
                }
                .prefix(2)
                .map { $0 }
            
        case .thisWeek:
            return nextDays(count: 7)
            
        case .nextWeek:
            guard let nextWeekStart = calendar.date(byAdding: .day, value: 7, to: today) else {
                return nextDays(count: 7)
            }
            
            return (0..<7).compactMap {
                calendar.date(byAdding: .day, value: $0, to: nextWeekStart)
            }
            
        case .unknown:
            return nextDays(count: 7)
        }
    }
    
    private func nextDays(count: Int) -> [Date] {
        let today = calendar.startOfDay(for: Date())
        
        return (0..<count).compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }
    }
    
    private func freeSlotsForDay(
        _ day: Date,
        tasks: [TaskItem],
        classSchedules: [ClassSchedule]
    ) -> [TimeSlot] {
        guard let dayStart = calendar.date(
            bySettingHour: 8,
            minute: 0,
            second: 0,
            of: day
        ),
        let dayEnd = calendar.date(
            bySettingHour: 22,
            minute: 0,
            second: 0,
            of: day
        ) else {
            return []
        }
        
        let weekday = calendar.component(.weekday, from: day)
        
        let classBusySlots = classSchedules
            .filter { $0.weekday == weekday }
            .compactMap { schedule -> TimeSlot? in
                guard let start = timeOnDay(schedule.startTime, day: day),
                      let end = timeOnDay(schedule.endTime, day: day),
                      start < end else {
                    return nil
                }
                
                return TimeSlot(start: start, end: end)
            }
        
        let taskBusySlots = tasks
            .filter {
                calendar.isDate($0.startAt, inSameDayAs: day)
            }
            .compactMap { task -> TimeSlot? in
                guard task.startAt < task.endAt else {
                    return nil
                }
                
                return TimeSlot(start: task.startAt, end: task.endAt)
            }
        
        let busySlots = (classBusySlots + taskBusySlots)
            .sorted { $0.start < $1.start }
        
        return subtractBusySlots(
            dayStart: dayStart,
            dayEnd: dayEnd,
            busySlots: busySlots
        )
    }
    
    private func subtractBusySlots(
        dayStart: Date,
        dayEnd: Date,
        busySlots: [TimeSlot]
    ) -> [TimeSlot] {
        var freeSlots: [TimeSlot] = []
        var cursor = dayStart
        
        for busy in busySlots {
            if cursor < busy.start {
                freeSlots.append(
                    TimeSlot(
                        start: cursor,
                        end: min(busy.start, dayEnd)
                    )
                )
            }
            
            if busy.end > cursor {
                cursor = busy.end
            }
        }
        
        if cursor < dayEnd {
            freeSlots.append(
                TimeSlot(
                    start: cursor,
                    end: dayEnd
                )
            )
        }
        
        return freeSlots
            .filter { $0.durationMinutes >= 15 }
    }
    
    private func timeOnDay(_ time: Date, day: Date) -> Date? {
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        
        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: day
        )
    }
    
    private func matchesPreferredPartOfDay(
        _ slot: StudySlotCandidate,
        preferredPartOfDay: StudyPartOfDay?
    ) -> Bool {
        guard let preferredPartOfDay,
              preferredPartOfDay != .unknown else {
            return true
        }
        
        let hour = calendar.component(.hour, from: slot.startAt)
        
        switch preferredPartOfDay {
        case .morning:
            return hour >= 6 && hour < 12
        case .afternoon:
            return hour >= 12 && hour < 18
        case .evening:
            return hour >= 18 && hour <= 22
        case .unknown:
            return true
        }
    }
}
