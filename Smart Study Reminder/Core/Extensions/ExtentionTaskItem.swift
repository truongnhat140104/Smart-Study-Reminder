import SwiftUI

extension TaskItem {
    var reminderAt: Date? {
        guard let reminderOffsetMinutes else {
            return nil
        }

        return Calendar.current.date(
            byAdding: .minute,
            value: -reminderOffsetMinutes,
            to: startAt
        )
    }
}
