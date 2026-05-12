import SwiftUI
import SwiftData

struct TodayScheduleCard: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClassSchedule.startTime, order: .forward) private var schedules: [ClassSchedule]
    
    @Binding var selectedTab: MainTab

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Label("Lịch học hôm nay", systemImage: "calendar.badge.clock")
                    .font(.headline)
                    .foregroundStyle(.blue)
                Spacer()
                
                if selectedTab == .home {
                    Button{
                        selectedTab = .calendar
                    } label: {
                        Text("Xem tất cả")
                            .font(Font.subheadline.bold())
                            .foregroundStyle(.blue)
                    }
                }
                                
            }
            
            Divider()
            
            VStack(spacing: 16) {
                let todaySchedules = schedules.filter { $0.weekday == todayWeekDay() }

                if todaySchedules.isEmpty {
                    Text("Hôm nay không có lịch học")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(todaySchedules) { schedule in
                        StudyRowView(
                            subject: schedule.subject.name,
                            room: schedule.room ?? "Chưa có phòng",
                            time: getTime(from: schedule),
                            color: schedule.subject.displayColor
                        )

                        Divider()
                    }
                }
            }
        }
        .modifier(CardBackgroundModifier())
    }
    
    private func todayWeekDay() -> Int {
        Calendar.current.component(.weekday, from: Date())
    }
    
    private func getTime(from schedule: ClassSchedule) -> String {
        let locale = Locale(identifier: "vi_VN")
        
        let startTime = schedule.startTime.formatted(
            .dateTime
                .locale(locale)
                .hour()
                .minute()
        )

        let endTime = schedule.endTime.formatted(
            .dateTime
                .locale(locale)
                .hour()
                .minute()
        )
        
        return "\(startTime) - \(endTime)"
    }
}
