//
//  NotificationManager.swift
//  Smart Study Reminder
//

import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    private let center = UNUserNotificationCenter.current()
    
    private override init() {
        super.init()
        center.delegate = self
    }
    
    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error {
                print("Notification permission error:", error.localizedDescription)
            }
            
            print("Notification permission granted:", granted)
        }
    }
    
    func scheduleTaskReminder(for task: TaskItem) {
        guard let reminderAt = task.reminderAt else {
            return
        }
        
        guard reminderAt > Date() else {
            print("Reminder time is in the past:", reminderAt)
            return
        }
        
        let identifier = task.notificationIdentifier ?? task.id.uuidString
        task.notificationIdentifier = identifier
        
        let content = UNMutableNotificationContent()
        content.title = "Nhắc nhở công việc"
        content.body = task.title
        content.sound = .default
        
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderAt
        )
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error {
                print("Failed to schedule notification:", error.localizedDescription)
            } else {
                print("Scheduled notification:", identifier, reminderAt)
            }
        }
    }
    
    func cancelTaskReminder(for task: TaskItem) {
        guard let identifier = task.notificationIdentifier else {
            return
        }
        
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Cancelled notification:", identifier)
    }
    
    func cancelTaskReminder(identifier: String?) {
        guard let identifier else {
            return
        }
        
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Cancelled notification:", identifier)
    }
    
    // Cho phép hiện notification khi app đang mở foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }
}
