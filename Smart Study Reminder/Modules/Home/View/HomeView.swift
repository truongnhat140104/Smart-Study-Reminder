//
//  HomeView.swift
//  Smart Study Reminder
//

import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: MainTab
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        HomeHeader()
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        TodayScheduleCard(selectedTab: $selectedTab)
                        
                        TasksScheduleSection(selectedTab: $selectedTab)

                        ProgressCard()
                    }
                    .padding(.bottom, 30)
                }
            }
        }
    }
}
