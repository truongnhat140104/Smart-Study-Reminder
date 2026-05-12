//
//  ProgressCard.swift
//  Smart Study Reminder
//
//  Created by Truong Nhat on 26/3/26.
//

import SwiftUI
import SwiftData
// MARK: - Card: Tiến độ
struct ProgressCard: View {
    @Query(sort: \TaskItem.title, order: .forward) private var taskItems: [TaskItem]
    
    @State private var valueProgress: Double = 0
    
    private var doneCount: Int {
        taskItems.filter { task in
            Calendar.current.isDateInToday(task.startAt)
            && task.status == .done
        }.count
    }
    
    private var totalCount: Int {
        taskItems.filter { task in
            Calendar.current.isDateInToday(task.startAt)
        }.count
    }
    
    private var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(doneCount) / Double(totalCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Tiến độ công việc", systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Spacer()
//                Text("🔥 3 ngày streak")
//                    .font(.footnote)
//                    .fontWeight(.bold)
//                    .padding(.horizontal, 10)
//                    .padding(.vertical, 5)
//                    .background(Color.orange.opacity(0.15))
//                    .foregroundStyle(.orange)
//                    .clipShape(Capsule())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    
                    Text("Hoàn thành")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    
                    Text("\(doneCount)/\(totalCount)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                
                // Progress bar custom xịn xò hơn
                ProgressView(value: progress)
                    .foregroundStyle(.orange.gradient)
                    .scaleEffect(x: 1, y: 2.5, anchor: .center) // Làm dày thanh màu lên
                    .padding(.vertical, 4)
            }
        }
        .modifier(CardBackgroundModifier())
    }
}

