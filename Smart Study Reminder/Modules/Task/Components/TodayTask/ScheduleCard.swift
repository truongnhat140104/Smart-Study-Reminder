//
//  ScheduleCard.swift
//  Smart Study Reminder
//

import SwiftUI

struct ScheduleCard: View {
    @Binding var selectedTab: MainTab

    let dateTitle: String
    let isToday: Bool
    let schedules: [TaskItem]

    var onEdit: ((TaskItem) -> Void)? = nil
    var onDelete: ((TaskItem) -> Void)? = nil
    var onDone: ((TaskItem) -> Void)? = nil
    var onCancel: ((TaskItem) -> Void)? = nil
    
    private let rowHeight: CGFloat = 86
    private let rowSpacing: CGFloat = 12
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            
            Divider()
            
            if schedules.isEmpty {
                emptyView
            } else {
                scheduleList
            }
        }
        .modifier(CardBackgroundModifier())
    }
    
    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "checklist")
                    .foregroundStyle(.red)

                Text(isToday ? "Công việc hôm nay" : "Công việc ngày: \(dateTitle)")
                    .font(.headline)
                    .foregroundStyle(.red)
            }
            
            Spacer()
            
            if selectedTab == .home {
                Button {
                    selectedTab = .task
                } label: {
                    Text("Xem tất cả")
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                }
            }
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.minus")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            
            Text("Trống lịch. Bạn có thể nghỉ ngơi!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var scheduleList: some View {
        List {
            ForEach(schedules, id: \.id) { task in
                SwipeableScheduleRow(
                    task: task,
                    onEdit: {
                        onEdit?(task)
                    },
                    onDelete: {
                        onDelete?(task)
                    },
                    onDone: {
                        onDone?(task)
                    },
                    onCancel: {
                        onCancel?(task)
                    }
                )
                .frame(height: rowHeight)
                .listRowInsets(
                    EdgeInsets(
                        top: rowSpacing / 2,
                        leading: 0,
                        bottom: rowSpacing / 2,
                        trailing: 0
                    )
                )
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollDisabled(true)
        .frame(height: CGFloat(schedules.count) * (rowHeight + rowSpacing))
    }
}
