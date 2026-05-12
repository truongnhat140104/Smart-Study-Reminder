//
//  TaskItem+Display.swift
//  Smart Study Reminder
//

import Foundation

extension TaskItem {
    var isDone: Bool {
        status == .done
    }

    var scheduleTimeText: String {
        let viLocale = Locale(identifier: "vi_VN")

        let start = startAt.formatted(
            .dateTime
                .locale(viLocale)
                .hour()
                .minute()
        )

        let end = endAt.formatted(
            .dateTime
                .locale(viLocale)
                .hour()
                .minute()
        )

        return "\(start) - \(end)"
    }

    var scheduleIconName: String {
        if status == .done {
            return "checkmark.circle.fill"
        }

        if tags.contains(where: { $0.name == "Ôn thi" }) {
            return "graduationcap.fill"
        }

        if tags.contains(where: { $0.name == "Deadline" }) {
            return "calendar.badge.clock"
        }

        if tags.contains(where: { $0.name == "Quan trọng" }) {
            return "exclamationmark.circle.fill"
        }

        if tags.contains(where: { $0.name == "Dự án" }) {
            return "folder.fill"
        }

        return "checklist"
    }
}
