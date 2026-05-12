//
//  TasksToolbarButtons.swift
//  Smart Study Reminder
//

import SwiftUI

struct TasksToolbarButtons: View {
    var body: some View {
        NavigationLink {
            ManageTaskView()
        } label: {
            Image(systemName: "list.bullet.circle.fill")
                .font(.title2)
                .foregroundStyle(.red)
        }
        .accessibilityLabel("Quản lý công việc")
        
        NavigationLink {
            AddTaskView()
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(.red)
        }
        .accessibilityLabel("Thêm công việc")
    }
}
