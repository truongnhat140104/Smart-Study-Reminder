//
//  MainTabView.swift
//  Smart Study Reminder
//
//  Created by Truong Nhat on 26/3/26.
//

import SwiftUI
import SwiftData

enum MainTab {
    case home
    case calendar
    case chatbot
    case task
}

struct MainTabView: View {
    @State private var selectedTab: MainTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Trang chủ", systemImage: "house.fill")
                }
                .tag(MainTab.home)
            
            CalendarView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Lịch học", systemImage: "calendar")
                }
                .tag(MainTab.calendar)
            
            TasksView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Lời nhắc", systemImage: "checklist")
                }
                .tag(MainTab.task)
            
            ChatbotView()
                .tabItem {
                    Label("Chatbot", systemImage: "ellipsis.rectangle")
                }
                .tag(MainTab.chatbot)
        }
    }
}


#Preview {
    MainTabView()
        .modelContainer(for: AppModelContainer.models)

}
