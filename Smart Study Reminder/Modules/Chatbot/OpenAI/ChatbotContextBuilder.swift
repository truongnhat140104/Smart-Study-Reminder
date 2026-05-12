//
//  ChatbotContextBuilder.swift
//  Smart Study Reminder
//

import Foundation

struct ChatbotContextBuilder {
    static func build(
        tasks: [TaskItem],
        classSchedules: [ClassSchedule],
        appSettings: [AppSettings]
    ) -> String {
        """
        \(scheduleContext(from: classSchedules))
        
        \(taskContext(from: tasks))
        
        \(settingsContext(from: appSettings.first))
        """
    }
    
    private static func scheduleContext(from schedules: [ClassSchedule]) -> String {
        if schedules.isEmpty {
            return "Lịch học: chưa có dữ liệu."
        }
        
        let text = schedules
            .sorted {
                if $0.weekday == $1.weekday {
                    return $0.startTime < $1.startTime
                }
                
                return $0.weekday < $1.weekday
            }
            .map { schedule in
                """
                - Thứ: \(weekdayText(schedule.weekday))
                  Môn: \(schedule.subject.name)
                  Phòng: \(schedule.room ?? "Chưa có phòng")
                  Giờ: \(formatTime(schedule.startTime)) - \(formatTime(schedule.endTime))
                """
            }
            .joined(separator: "\n")
        
        return """
        Lịch học:
        \(text)
        """
    }
    
    private static func taskContext(from tasks: [TaskItem]) -> String {
        if tasks.isEmpty {
            return "Công việc: chưa có dữ liệu."
        }
        
        let text = tasks
            .sorted { $0.startAt < $1.startAt }
            .map { task in
                let statusText = task.status == .done ? "Đã hoàn thành" : "Chưa hoàn thành"
                
                return """
                - Tiêu đề: \(task.title)
                  Chi tiết: \(task.detail ?? "Không có")
                  Thời gian: \(formatDateTime(task.startAt)) - \(formatDateTime(task.endAt))
                  Trạng thái: \(statusText)
                """
            }
            .joined(separator: "\n")
        
        return """
        Công việc:
        \(text)
        """
    }
    
    private static func settingsContext(from settings: AppSettings?) -> String {
        guard let settings else {
            return "Cài đặt: chưa có dữ liệu."
        }
        
        return """
        Cài đặt:
        - Nhắc trước mặc định: \(settings.defaultReminderMinutes) phút
        - Thời lượng học ưu tiên: \(settings.preferredStudyDurationMinutes) phút
        - Bật thông báo: \(settings.enableNotifications ? "Có" : "Không")
        - Đồng bộ lịch: \(settings.enableCalendarSync ? "Có" : "Không")
        """
    }
    
    private static func weekdayText(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "Chủ nhật"
        case 2: return "Thứ 2"
        case 3: return "Thứ 3"
        case 4: return "Thứ 4"
        case 5: return "Thứ 5"
        case 6: return "Thứ 6"
        case 7: return "Thứ 7"
        default: return "Không rõ"
        }
    }
    
    private static func formatTime(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .locale(Locale(identifier: "vi_VN"))
                .hour()
                .minute()
        )
    }
    
    private static func formatDateTime(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .locale(Locale(identifier: "vi_VN"))
                .day()
                .month()
                .year()
                .hour()
                .minute()
        )
    }
}
