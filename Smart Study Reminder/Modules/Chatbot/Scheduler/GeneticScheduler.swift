//
//  GeneticScheduler.swift
//  Smart Study Reminder
//

import Foundation

final class GeneticScheduler {
    private let calendar = Calendar.current
    
    func generateSchedule(
        tasks: [TaskItem],
        classSchedules: [ClassSchedule],
        settings: AppSettings,
        from startDate: Date,
        to endDate: Date
    ) -> [TaskScheduleResult] {
        let notDoneTasks = tasks.filter { $0.status == .notDone }
        
        guard !notDoneTasks.isEmpty else {
            return []
        }
        
        let freeSlots = generateFreeSlots(
            from: startDate,
            to: endDate,
            classSchedules: classSchedules
        )
        
        guard !freeSlots.isEmpty else {
            return []
        }
        
        let populationSize = 30
        let generations = 60
        let eliteCount = 8
        
        var population = makeInitialPopulation(
            taskCount: notDoneTasks.count,
            size: populationSize
        )
        
        for _ in 0..<generations {
            let ranked = population.sorted {
                fitness(
                    chromosome: $0,
                    tasks: notDoneTasks,
                    freeSlots: freeSlots,
                    settings: settings
                ) >
                fitness(
                    chromosome: $1,
                    tasks: notDoneTasks,
                    freeSlots: freeSlots,
                    settings: settings
                )
            }
            
            var nextPopulation = Array(ranked.prefix(eliteCount))
            
            while nextPopulation.count < populationSize {
                let parentA = ranked[Int.random(in: 0..<eliteCount)]
                let parentB = ranked[Int.random(in: 0..<eliteCount)]
                
                var child = crossover(parentA, parentB)
                mutate(&child)
                
                nextPopulation.append(child)
            }
            
            population = nextPopulation
        }
        
        guard let bestChromosome = population.max(by: {
            fitness(
                chromosome: $0,
                tasks: notDoneTasks,
                freeSlots: freeSlots,
                settings: settings
            ) <
            fitness(
                chromosome: $1,
                tasks: notDoneTasks,
                freeSlots: freeSlots,
                settings: settings
            )
        }) else {
            return []
        }
        
        return buildSchedule(
            chromosome: bestChromosome,
            tasks: notDoneTasks,
            freeSlots: freeSlots,
            settings: settings
        )
    }
    
    private func makeInitialPopulation(taskCount: Int, size: Int) -> [[Int]] {
        let baseChromosome = Array(0..<taskCount)
        
        return (0..<size).map { _ in
            baseChromosome.shuffled()
        }
    }
    
    private func fitness(
        chromosome: [Int],
        tasks: [TaskItem],
        freeSlots: [TimeSlot],
        settings: AppSettings
    ) -> Double {
        let results = buildSchedule(
            chromosome: chromosome,
            tasks: tasks,
            freeSlots: freeSlots,
            settings: settings
        )
        
        var score = Double(results.count) * 10_000
        
        for result in results {
            if result.endAt > result.task.endAt {
                let lateMinutes = calendar.dateComponents(
                    [.minute],
                    from: result.task.endAt,
                    to: result.endAt
                ).minute ?? 0
                
                score -= Double(lateMinutes) * 5
            } else {
                let minutesBeforeDeadline = calendar.dateComponents(
                    [.minute],
                    from: result.endAt,
                    to: result.task.endAt
                ).minute ?? 0
                
                score += min(Double(minutesBeforeDeadline), 720) * 0.1
            }
        }
        
        return score
    }
    
    private func buildSchedule(
        chromosome: [Int],
        tasks: [TaskItem],
        freeSlots: [TimeSlot],
        settings: AppSettings
    ) -> [TaskScheduleResult] {
        var availableSlots = freeSlots.sorted { $0.start < $1.start }
        var results: [TaskScheduleResult] = []
        
        for taskIndex in chromosome {
            let task = tasks[taskIndex]
            let duration = durationMinutes(for: task, settings: settings)
            
            guard let slotIndex = availableSlots.firstIndex(where: { $0.durationMinutes >= duration }) else {
                continue
            }
            
            let slot = availableSlots[slotIndex]
            
            guard let endAt = calendar.date(
                byAdding: .minute,
                value: duration,
                to: slot.start
            ) else {
                continue
            }
            
            guard endAt <= slot.end else {
                continue
            }
            
            results.append(
                TaskScheduleResult(
                    task: task,
                    startAt: slot.start,
                    endAt: endAt
                )
            )
            
            if endAt < slot.end {
                availableSlots[slotIndex].start = endAt
            } else {
                availableSlots.remove(at: slotIndex)
            }
        }
        
        return results.sorted { $0.startAt < $1.startAt }
    }
    
    private func durationMinutes(for task: TaskItem, settings: AppSettings) -> Int {
        let minutes = calendar.dateComponents(
            [.minute],
            from: task.startAt,
            to: task.endAt
        ).minute ?? settings.preferredStudyDurationMinutes
        
        if minutes <= 0 {
            return settings.preferredStudyDurationMinutes
        }
        
        return max(15, minutes)
    }
    
    private func crossover(_ parentA: [Int], _ parentB: [Int]) -> [Int] {
        let count = parentA.count
        
        guard count > 2 else {
            return parentA
        }
        
        let cut1 = Int.random(in: 0..<count)
        let cut2 = Int.random(in: cut1..<count)
        
        var child = Array(repeating: -1, count: count)
        var used = Set<Int>()
        
        for index in cut1...cut2 {
            child[index] = parentA[index]
            used.insert(parentA[index])
        }
        
        var parentBIndex = 0
        
        for index in 0..<count {
            if child[index] == -1 {
                while parentBIndex < count && used.contains(parentB[parentBIndex]) {
                    parentBIndex += 1
                }
                
                if parentBIndex < count {
                    child[index] = parentB[parentBIndex]
                    used.insert(parentB[parentBIndex])
                }
            }
        }
        
        return child
    }
    
    private func mutate(_ chromosome: inout [Int]) {
        guard chromosome.count > 1 else {
            return
        }
        
        if Double.random(in: 0...1) < 0.25 {
            let indexA = Int.random(in: 0..<chromosome.count)
            let indexB = Int.random(in: 0..<chromosome.count)
            chromosome.swapAt(indexA, indexB)
        }
    }
    
    private func generateFreeSlots(
        from startDate: Date,
        to endDate: Date,
        classSchedules: [ClassSchedule]
    ) -> [TimeSlot] {
        var slots: [TimeSlot] = []
        var currentDay = calendar.startOfDay(for: startDate)
        let finalDay = calendar.startOfDay(for: endDate)
        
        while currentDay <= finalDay {
            guard let dayStart = calendar.date(
                bySettingHour: 8,
                minute: 0,
                second: 0,
                of: currentDay
            ),
            let dayEnd = calendar.date(
                bySettingHour: 22,
                minute: 0,
                second: 0,
                of: currentDay
            ) else {
                break
            }
            
            let weekday = calendar.component(.weekday, from: currentDay)
            
            let busySlots = classSchedules
                .filter { $0.weekday == weekday }
                .compactMap { schedule -> TimeSlot? in
                    guard let start = timeOnDay(schedule.startTime, day: currentDay),
                          let end = timeOnDay(schedule.endTime, day: currentDay),
                          start < end else {
                        return nil
                    }
                    
                    return TimeSlot(start: start, end: end)
                }
                .sorted { $0.start < $1.start }
            
            slots.append(
                contentsOf: subtractBusySlots(
                    dayStart: dayStart,
                    dayEnd: dayEnd,
                    busySlots: busySlots
                )
            )
            
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else {
                break
            }
            
            currentDay = nextDay
        }
        
        return slots.filter { $0.durationMinutes >= 15 }
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
}
