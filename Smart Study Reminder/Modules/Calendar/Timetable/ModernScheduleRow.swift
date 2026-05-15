import SwiftUI

struct ModernScheduleRow: View {
    let subject: String
    let time: String
    let room: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon hình vuông bo góc hiện đại
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 54, height: 54)
                
                Image(systemName: "book.closed.fill")
                    .font(.title2)
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(subject)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text(time)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                        Text(room)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
