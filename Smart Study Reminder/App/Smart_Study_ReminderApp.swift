import SwiftUI
import SwiftData

@main
struct Smart_Study_ReminderApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                }
        }
        .modelContainer(for: AppModelContainer.models)

    }
}
