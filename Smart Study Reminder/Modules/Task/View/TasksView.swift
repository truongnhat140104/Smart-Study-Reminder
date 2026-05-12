import SwiftUI
import SwiftData

struct TasksView: View {
    
    @State private var currentMonth: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    
    @Binding var selectedTab: MainTab
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        TasksMonthCalendarCard(
                            currentMonth: $currentMonth,
                            selectedDate: $selectedDate
                        )
                        .padding(.top, 10)

                        TasksScheduleSection(
                            selectedTab: $selectedTab,
                            selectedDate: selectedDate
                        )
                    }
                    .padding(.bottom, 30)
                    .padding(.bottom, 30)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    TasksToolbarButtons()
                }
            }
        }
    }
}

#Preview {
    TasksView(selectedTab: .constant(.task))
        .modelContainer(for: AppModelContainer.models)
}
