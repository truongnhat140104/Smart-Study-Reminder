//
//  TodayStudyCard.swift
//  Smart Study Reminder
//
//  Created by Truong Nhat on 26/3/26.
//

import SwiftUI

// MARK: - Card: Hôm nay học gì
struct TodayStudyCard: View {
    @Binding var selectedTab: MainTab
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Label("Lịch học hôm nay", systemImage: "calendar.badge.clock")
                    .font(.headline)
                    .foregroundStyle(.blue)
                Spacer()
                                
                Button{
                    selectedTab = .calendar
                } label: {
                    Text("Xem tất cả")
                        .font(Font.subheadline.bold())
                        .foregroundStyle(.blue)
                }
            }
            
            Divider()
            
            VStack(spacing: 16) {
                StudyRowView(
                    subject: "Toán rời rạc",
                    room: "Phòng B1-201",
                    time: "08:00 - 09:30",
                    color: .indigo
                )
                
                Divider() // Thêm đường kẻ chia tách các dòng
                
                StudyRowView(
                    subject: "Lập trình SwiftUI",
                    room: "Lab 2",
                    time: "14:00 - 15:30",
                    color: .orange
                )
            }
        }
        .modifier(CardBackgroundModifier())
    }
}

struct StudyRowView: View {
    let subject: String
    let room: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon có nền mờ hiện đại
            Image(systemName: "book.closed.fill")
                .font(.system(size: 20))
                .foregroundStyle(color.gradient)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(subject)
                    .font(.system(.callout, design: .rounded))
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    Label(time, systemImage: "clock")
                    Label(room, systemImage: "mappin.and.ellipse")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
