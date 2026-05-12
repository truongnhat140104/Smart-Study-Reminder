//
//  DefaultTaskTag.swift
//  Smart Study Reminder
//

import Foundation

enum DefaultTaskTag: String, CaseIterable, Identifiable, Hashable {
    case study = "Học tập"
    case exam = "Ôn thi"
    case deadline = "Deadline"
    case project = "Dự án"
    case personal = "Việc riêng"
    case important = "Quan trọng"
    case other = "Khác"
    
    var id: String { rawValue }
    
    var title: String {
        rawValue
    }
    
    var systemImage: String {
        switch self {
        case .study:
            return "book.fill"
        case .exam:
            return "graduationcap.fill"
        case .deadline:
            return "calendar.badge.clock"
        case .project:
            return "folder.fill"
        case .personal:
            return "person.fill"
        case .important:
            return "exclamationmark.circle.fill"
        case .other:
            return "tag.fill"
        }
    }
}
