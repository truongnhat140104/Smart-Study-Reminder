//
//  SettingView.swift
//  Smart Study Reminder
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var appSettings: [AppSettings]
    
    private var settings: AppSettings? {
        appSettings.first
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Cài đặt")
                            .font(.largeTitle.bold())
                            .padding(.top, 20)
                        
                        if let settings {
//                            SettingsAccountCard(settings: settings)
                            
                            SettingsPreferenceCard(settings: settings)
                            
//                            SettingsSyncCard(settings: settings)
                            
//                            SettingsLogoutCard()
                        } else {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                createDefaultSettingsIfNeeded()
            }
        }
    }
    
    private func createDefaultSettingsIfNeeded() {
        guard appSettings.isEmpty else { return }
        
        let settings = AppSettings()
        modelContext.insert(settings)
    }
}
