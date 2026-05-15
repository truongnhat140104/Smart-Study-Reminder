//
//  SwipeableScheduleRow.swift
//  Smart Study Reminder
//

import SwiftUI

struct SwipeableScheduleRow: View {
    let task: TaskItem
    
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var onDone: (() -> Void)? = nil
    var onCancel: (() -> Void)? = nil
    
    private let rowHeight: CGFloat = 86
    
    var body: some View {
        ScheduleRow(
            title: task.title,
            detail: task.detail,
            time: task.scheduleTimeText,
            icon: task.scheduleIconName,
            reminderOffsetMinutes: task.reminderOffsetMinutes,
            isDone: task.status == .done,
            priority: task.priority.title
        )
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: rowHeight, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label("Xóa", systemImage: "trash")
            }
            
            Button {
                onEdit?()
            } label: {
                Label("Sửa", systemImage: "pencil")
            }
            .tint(.orange)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if task.status == .notDone {
                Button {
                    onDone?()
                } label: {
                    Label("Xong", systemImage: "checkmark")
                }
                .tint(.green)
            } else {
                Button {
                    onCancel?()
                } label: {
                    Label("Hủy", systemImage: "x.circle.fill")
                }
                .tint(.orange)
            }
        }
    }
}
