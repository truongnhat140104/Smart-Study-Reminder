//
//  TaskFilterMode.swift
//  Smart Study Reminder
//

import Foundation

enum TaskFilterMode: String, CaseIterable, Identifiable {
    case all = "Tất cả"
    case priority = "Ưu tiên"
    case tag = "Nhãn"
    
    var id: String { rawValue }
}
