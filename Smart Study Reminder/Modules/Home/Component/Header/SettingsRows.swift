//
//  SettingsRows.swift
//  Smart Study Reminder
//

import SwiftUI

struct SettingsIconBox: View {
    let icon: String
    let color: Color
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(color.gradient)
            .frame(width: 36, height: 36)
            .overlay {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            SettingsIconBox(icon: icon, color: iconColor)
            
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .frame(height: 58)
    }
}

struct SettingsStepperRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let valueText: String
    let onMinus: () -> Void
    let onPlus: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            SettingsIconBox(icon: icon, color: iconColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(valueText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 10) {
                Button {
                    onMinus()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                Button {
                    onPlus()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(height: 68)
    }
}

struct SettingsInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let trailingText: String
    
    var body: some View {
        HStack(spacing: 14) {
            SettingsIconBox(icon: icon, color: iconColor)
            
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Text(trailingText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .frame(height: 58)
    }
}
