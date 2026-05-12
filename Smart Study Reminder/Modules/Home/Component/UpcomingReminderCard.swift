//
//  UpcomingReminderCard.swift
//  Smart Study Reminder
//
//  Created by Truong Nhat on 26/3/26.
//

import SwiftUI

// MARK: - Card: Nhắc nhở sắp tới
struct UpcomingReminderCard: View {
    @Binding var selectedTab: MainTab
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            HStack{
                Label("Công việc hôm nay", systemImage: "checklist")
                    .font(.headline)
                    .foregroundStyle(.red)
                
                Spacer()
                
                Button{
                    selectedTab = .task
                } label: {
                    Text("Xem tất cả")
                        .font(Font.subheadline.bold())
                        .foregroundStyle(.red)
                }
            }
            
            Divider()
            
            VStack(spacing: 16) {
                ReminderRowView(title: "Ôn bài kiểm tra SwiftUI", time: "18:00", isUrgent: true)
                ReminderRowView(title: "Làm bài tập Toán", time: "20:00", isUrgent: false)
                ReminderRowView(title: "Đọc tài liệu UI Design", time: "07:00", isUrgent: false)
            }
        }
        .modifier(CardBackgroundModifier())
    }
}

struct ReminderRowView: View {
    let title: String
    let time: String
    let isUrgent: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Vòng tròn để người dùng có cảm giác muốn tick hoàn thành
            Image(systemName: "circle")
                .font(.title3)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(false) // Chuẩn bị cho animation hoàn thành task sau này
                
                Text(time)
                    .font(.caption)
                    .foregroundStyle(isUrgent ? .red : .secondary)
            }
            Spacer()
        }
    }
}
