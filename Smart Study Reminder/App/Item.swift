//
//  Item.swift
//  Smart Study Reminder
//
//  Created by Truong Nhat on 26/3/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var title: String
    var createdAt: Date

    init(title: String, createdAt: Date = Date()) {
        self.title = title
        self.createdAt = createdAt
    }
}
