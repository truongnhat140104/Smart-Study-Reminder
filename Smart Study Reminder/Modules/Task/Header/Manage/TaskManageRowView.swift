//
//  TaskManageRowView.swift
//  Smart Study Reminder
//

import SwiftUI

struct TaskManageRowView: View {
    let viLocale = Locale(identifier: "vi_VN")
    
    let task: TaskItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                    
                    if let detail = task.detail, !detail.isEmpty {
                        Text(detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Text(task.priority.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.12))
                    .foregroundStyle(.red)
                    .clipShape(Capsule())
            }
            
            HStack(){
                Image(systemName: "clock")
                Text("Deadline: \(timeText)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            
            if let reminderOffsetMinutes = task.reminderOffsetMinutes {
                HStack(){
                    Image(systemName: "bell")
                    
                    Text(reminderText(from: reminderOffsetMinutes))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            if !task.tags.isEmpty {
                HStack(spacing: 6) {
                    
                    Text("Tag: ")
                        .font(.caption2)
                    
                    ForEach(Array(task.tags.prefix(3)), id: \.id) { tag in
                        Text(tag.name)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.12))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                    }
                    
                    if task.tags.count > 3 {
                        Text("+\(task.tags.count - 3)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
    
    private var timeText: String {

        let dateText = task.startAt.formatted(
            .dateTime
                .locale(viLocale)
                .day()
                .month(.abbreviated)
                .year()
        )

        let startTime = task.startAt.formatted(
            .dateTime
                .locale(viLocale)
                .hour()
                .minute()
        )

        let endTime = task.endAt.formatted(
            .dateTime
                .locale(viLocale)
                .hour()
                .minute()
        )
        
        return "\(dateText) lúc \(startTime) - \(endTime)"
    }
    
    private func reminderText(from minutes: Int) -> String {
        switch minutes {
        case 0:
            return "Nhắc đúng giờ"
        case 1..<60:
            return "Nhắc trước \(minutes) phút"
        case 60:
            return "Nhắc trước 1 giờ"
        case 61..<1440 where minutes % 60 == 0:
            return "Nhắc trước \(minutes / 60) giờ"
        case 1440:
            return "Nhắc trước 1 ngày"
        case 1441... where minutes % 1440 == 0:
            return "Nhắc trước \(minutes / 1440) ngày"
        default:
            return "Nhắc trước \(minutes) phút"
        }
    }
}
