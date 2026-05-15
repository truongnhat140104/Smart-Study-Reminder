//
//  ScheduleRow.swift
//  Smart Study Reminder
//

import SwiftUI

struct ScheduleRow: View {
    let title: String
    let detail: String?
    let time: String
    let icon: String
    let reminderOffsetMinutes: Int?
    let isDone: Bool
    let priority: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(isDone ? .gray : .red)
                .frame(width: 46, height: 46)
                .background((isDone ? Color.gray : Color.red).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            
            VStack(alignment: .leading, spacing: 5) {
                HStack{
                    Text(title)
                        .font(.system(.callout, design: .rounded))
                        .fontWeight(.semibold)
                        .strikethrough(isDone)
                        .foregroundStyle(isDone ? .secondary : .primary)
                    
                    Spacer()
                                        
                    Text(priority)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.12))
                        .foregroundStyle(.red)
                        .clipShape(Capsule())
                    
                }
                
                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 5) {
                    Image(systemName: "clock")
                    Text(time)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                if let reminderOffsetMinutes {
                    HStack(spacing: 5) {
                        Image(systemName: "bell")
                        
                        Text(reminderText(from: reminderOffsetMinutes))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if isDone {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            }
        }
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
