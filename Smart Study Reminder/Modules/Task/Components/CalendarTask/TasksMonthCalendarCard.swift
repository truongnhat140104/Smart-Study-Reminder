//
//  TasksMonthCalendarCard.swift
//  Smart Study Reminder
//

import SwiftUI
import SwiftData

struct TasksMonthCalendarCard: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    
    @Query(sort: \TaskItem.startAt) private var tasks: [TaskItem]
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            monthHeader
            Divider()
            monthGridCard
        }
        .modifier(CardBackgroundModifier())
    }
    
    private var monthHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(monthTitle(from: currentMonth))
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            HStack(spacing: 15) {
                Button {
                    withAnimation(.easeInOut) {
                        changeMonth(by: -1)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 35, height: 35)
                        .background(Circle().fill(Color.red))
                        .clipShape(Circle())
                        .foregroundStyle(.white)
                }
                .contentShape(Circle())
                
                Button {
                    withAnimation(.easeInOut) {
                        changeMonth(by: 1)
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 35, height: 35)
                        .background(Circle().fill(Color.red))
                        .clipShape(Circle())
                        .foregroundStyle(.white)
                }
                .contentShape(Circle())
            }
        }
    }
    
    private var monthGridCard: some View {
        let days = monthDays()
        
        return VStack(alignment: .leading, spacing: 20) {
            weekdayHeader
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(days.indices, id: \.self) { index in
                    if let date = days[index] {
                        let selected = calendar.isDate(date, inSameDayAs: selectedDate)
                        
                        CalendarTasksDayCell(
                            date: date,
                            isSelected: selected,
                            isToday: calendar.isDateInToday(date),
                            hasEvent: !tasksForDate(date).isEmpty
                        )
                        .id("\(index)-\(selected)")
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDate = calendar.startOfDay(for: date)
                            }
                        }
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
    }
    
    private var weekdayHeader: some View {
        let weekdays = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
        
        return HStack {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func tasksForDate(_ date: Date) -> [TaskItem] {
        tasks
            .filter { task in
                calendar.isDate(task.startAt, inSameDayAs: date)
            }
            .sorted { $0.startAt < $1.startAt }
    }
    
    private func changeMonth(by value: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) else {
            return
        }
        
        currentMonth = newMonth
        
        let currentDay = calendar.component(.day, from: selectedDate)
        let year = calendar.component(.year, from: newMonth)
        let month = calendar.component(.month, from: newMonth)
        let maxDay = calendar.range(of: .day, in: .month, for: newMonth)?.count ?? 28
        let newDay = min(currentDay, maxDay)
        
        if let adjustedDate = calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: newDay
            )
        ) {
            selectedDate = calendar.startOfDay(for: adjustedDate)
        }
    }
    
    private func monthTitle(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "MMMM - yyyy"
        return formatter.string(from: date).capitalized
    }
    
    private func monthDays() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday,
              let daysRange = calendar.range(of: .day, in: .month, for: currentMonth) else {
            return []
        }
        
        let firstDayOffset = (firstWeekday + 5) % 7
        var days: [Date?] = Array(repeating: nil, count: firstDayOffset)
        
        for day in daysRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) {
                days.append(date)
            }
        }
        
        return days
    }
}
