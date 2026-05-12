//
//  CardBackgroundModifier.swift
//  Smart Study Reminder
//
//  Created by Truong Nhat on 26/3/26.
//

import SwiftUI

// MARK: - Card Modifier (Dùng chung cho các thẻ để đồng bộ UI)
struct CardBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 5)
            .padding(.horizontal)
    }
}
