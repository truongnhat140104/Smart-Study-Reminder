//
//  CalendarDayCell.swift
//  Smart Study Reminder
//

import SwiftUI

struct CalendarTasksDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEvent: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(.body, design: .rounded))
                .fontWeight(isSelected || isToday ? .bold : .medium)
                .foregroundStyle(textColor)
                .frame(width: 36, height: 36)
                .background(backgroundView)
                .clipShape(Circle())
            
            Circle()
                .fill(hasEvent ? (isSelected ? Color.red : Color.gray.opacity(0.5)) : Color.clear)
                .frame(width: 5, height: 5)
        }
        .frame(height: 44)
    }
    
    private var textColor: Color {
        if isSelected { return .white }
        if isToday { return .red }
        return .primary
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if isSelected {
            Circle().fill(Color.red.gradient)
        } else if isToday {
            Circle().fill(Color.red.opacity(0.15))
        } else {
            Circle().fill(Color.clear)
        }
    }
}

#Preview {
    CalendarTasksDayCell(date: Date(), isSelected: false, isToday: true, hasEvent: true)
}
