//
//  CalendarView.swift
//  Smart Study Reminder
//

import SwiftUI
import PhotosUI
import SwiftData

struct CalendarView: View {
    @Binding var selectedTab: MainTab
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        TodayScheduleCard(selectedTab: $selectedTab)
                        
                        WeeklyTimetableCard()
                        
                        ScanTimetableCard()
                    }
                    .padding(.vertical, 20)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink {
                        ManageTimetableView()
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }

                    NavigationLink {
                        AddTimetableView()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
    }
}

#Preview{
    CalendarView(selectedTab: .constant(.calendar))
        .modelContainer(for: AppModelContainer.models)

}
