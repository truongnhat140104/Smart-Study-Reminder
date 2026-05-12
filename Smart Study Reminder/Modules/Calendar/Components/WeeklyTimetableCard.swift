//
//  WeeklyTimetableCard.swift
//  Smart Study Reminder
//

import SwiftUI
import SwiftData

struct WeeklyTimetableCard: View {
    @Query(sort: \ClassSchedule.weekday, order: .forward)
    private var schedules: [ClassSchedule]
    
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var cardWidth: CGFloat = 0
    
    private let baseColumnWidth: CGFloat = 140
    private let baseRowHeight: CGFloat = 50
    private let numberOfPeriods = 14
    
    private let maxZoom: CGFloat = 1.7
    
    private let days: [(title: String, weekday: Int)] = [
        ("Thứ 2", 2),
        ("Thứ 3", 3),
        ("Thứ 4", 4),
        ("Thứ 5", 5),
        ("Thứ 6", 6),
        ("Thứ 7", 7),
        ("CN", 1)
    ]
    
    private var minZoom: CGFloat {
        guard cardWidth > 0 else {
            return 0.4
        }
        
        let horizontalPadding: CGFloat = 40
        let availableWidth = cardWidth - horizontalPadding
        let fullTimetableWidth = baseColumnWidth * CGFloat(days.count)
        
        return max(0.35, min(1.0, availableWidth / fullTimetableWidth))
    }
    
    private var columnWidth: CGFloat {
        baseColumnWidth * zoomScale
    }
    
    private var rowHeight: CGFloat {
        baseRowHeight * zoomScale
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            
            ScrollView(.horizontal, showsIndicators: false) {
                timetableGrid
                    .padding(.horizontal, 20)
                    .simultaneousGesture(zoomGesture)
            }
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        updateCardWidth(proxy.size.width)
                    }
                    .onChange(of: proxy.size.width) { _, newWidth in
                        updateCardWidth(newWidth)
                    }
            }
        )
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Chi tiết tuần này")
                    .font(.headline)
                
                Text("Chụm hai ngón tay để phóng to / thu nhỏ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(Int(zoomScale * 100))%")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 15)
        .padding(.top, 5)
        .padding(.bottom, 5)
    }
    
    private var timetableGrid: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(days, id: \.weekday) { day in
                VStack(spacing: 0) {
                    Text(day.title)
                        .font(.system(size: max(9, 12 * zoomScale), weight: .bold))
                        .frame(width: columnWidth, height: rowHeight)
                        .background(Color(.systemGray6))
                        .border(Color(.systemGray5), width: 0.5)
                    
                    ZStack(alignment: .top) {
                        backgroundRows
                        
                        ForEach(schedulesForDay(day.weekday)) { schedule in
                            ClassBlock(
                                subject: blockText(for: schedule),
                                startPeriod: startPeriod(from: schedule.startTime),
                                duration: durationInPeriods(
                                    from: schedule.startTime,
                                    to: schedule.endTime
                                ),
                                color: schedule.subject.displayColor,
                                rowHeight: rowHeight,
                                colWidth: columnWidth,
                                zoomScale: zoomScale
                            )
                        }
                    }
                }
            }
        }
    }
    
    private var backgroundRows: some View {
        VStack(spacing: 0) {
            ForEach(1...numberOfPeriods, id: \.self) { _ in
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: columnWidth, height: rowHeight)
                    .border(Color(.systemGray5), width: 0.5)
            }
        }
    }
    
    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = lastZoomScale * value
                zoomScale = min(max(newScale, minZoom), maxZoom)
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    zoomScale = min(max(zoomScale, minZoom), maxZoom)
                    lastZoomScale = zoomScale
                }
            }
    }
    
    private func updateCardWidth(_ width: CGFloat) {
        cardWidth = width
        
        if zoomScale == 1.0 && lastZoomScale == 1.0 {
            zoomScale = minZoom
            lastZoomScale = minZoom
            return
        }
        
        if zoomScale < minZoom {
            zoomScale = minZoom
            lastZoomScale = minZoom
        }
    }
    
    private func schedulesForDay(_ weekday: Int) -> [ClassSchedule] {
        schedules
            .filter { $0.weekday == weekday }
            .sorted { $0.startTime < $1.startTime }
    }
    
    private func blockText(for schedule: ClassSchedule) -> String {
        """
        \(schedule.subject.name)
        Phòng: \(schedule.room ?? "Chưa có phòng")
        \(formatTime(schedule.startTime)) -> \(formatTime(schedule.endTime))
        """
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func startPeriod(from date: Date) -> Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let totalMinutes = hour * 60 + minute
        
        switch totalMinutes {
        case ..<450:
            return 1
        case 450..<500:
            return 1
        case 500..<550:
            return 2
        case 550..<610:
            return 3
        case 610..<660:
            return 4
        case 660..<780:
            return 5
        case 780..<830:
            return 6
        case 830..<880:
            return 7
        case 880..<950:
            return 8
        case 950..<1000:
            return 9
        case 1000..<1050:
            return 10
        case 1050..<1100:
            return 11
        case 1100..<1150:
            return 12
        case 1150..<1200:
            return 13
        default:
            return 14
        }
    }
    
    private func durationInPeriods(from startTime: Date, to endTime: Date) -> Int {
        let minutes = Calendar.current.dateComponents(
            [.minute],
            from: startTime,
            to: endTime
        ).minute ?? 50
        
        return max(1, Int(ceil(Double(minutes) / 50.0)))
    }
}

struct ClassBlock: View {
    let subject: String
    let startPeriod: Int
    let duration: Int
    let color: Color
    let rowHeight: CGFloat
    let colWidth: CGFloat
    let zoomScale: CGFloat
    
    var body: some View {
        Text(subject)
            .font(.system(size: max(7, 10 * zoomScale)))
            .multilineTextAlignment(.leading)
            .lineLimit(4)
            .minimumScaleFactor(0.7)
            .padding(max(2, 4 * zoomScale))
            .frame(
                width: colWidth - 2,
                height: rowHeight * CGFloat(duration) - 2,
                alignment: .topLeading
            )
            .background(color.opacity(0.2))
            .border(color.opacity(0.5), width: 1)
            .offset(y: rowHeight * CGFloat(startPeriod - 1))
    }
}
