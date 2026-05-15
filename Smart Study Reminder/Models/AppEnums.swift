//
//  AppNums.swift
//  Smart Study Reminder
//
//  Created by Truong Nhat on 4/5/26.
//

import Foundation

enum TaskStatus: String, Codable, CaseIterable {
    case done
    case notDone
    
    var title: String {
        switch self {
        case .done:
            return "Đã hoàn thành"
        case .notDone:
            return "Chưa hoàn thành"
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        switch rawValue {
        case "done":
            self = .done
            
        case "notDone", "todo", "not_done", "pending":
            self = .notDone
            
        default:
            self = .notDone
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum TaskPriority: String, Codable, CaseIterable, Hashable {
    case low
    case medium
    case high
    
    var title: String {
        switch self {
        case .low:
            return "Thấp"
        case .medium:
            return "Trung bình"
        case .high:
            return "Cao"
        }
    }
}

enum TaskRepeatRule: String, Codable, CaseIterable, Identifiable {
    case none
    case daily
    case weekly
    case monthly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:
            return "Không lặp lại"
        case .daily:
            return "Hằng ngày"
        case .weekly:
            return "Hằng tuần"
        case .monthly:
            return "Hằng tháng"
        case .yearly:
            return "Hằng năm"
        }
    }
}

enum OCRStatus: String, Codable {
    case pendingReview
    case confirmed
    case rejected
}

enum ChatRole: String, Codable, CaseIterable {
    case user
    case assistant
}

enum ChatMessageStatus: String, Codable, CaseIterable {
    case sending
    case sent
    case failed
}

enum ClassSource: String, Codable {
    case manual
    case ocr
}
