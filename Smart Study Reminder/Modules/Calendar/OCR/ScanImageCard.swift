//
//  ScanImageCard.swift
//  Smart Study Reminder
//

import SwiftUI
import PhotosUI

struct ScanImageCard: View {
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Quét thời khóa biểu")
                        .font(.headline)
                    
                    Text("Chọn ảnh từ thư viện để AI bóc tách")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "viewfinder.rectangular")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .background(Color.blue.opacity(0.05).clipShape(RoundedRectangle(cornerRadius: 16)))
                    .frame(height: 140)
                    .overlay {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.stack")
                                .font(.system(size: 32))
                                .foregroundStyle(.blue.opacity(0.8))
                            
                            Text("Chưa có ảnh nào")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                    }
            }
            
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                HStack {
                    Image(systemName: selectedImage == nil ? "photo.badge.plus" : "arrow.triangle.2.circlepath.camera")
                    Text(selectedImage == nil ? "Chọn ảnh" : "Chọn ảnh khác")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .modifier(CardBackgroundModifier())
        .task(id: selectedPhotoItem) {
            await loadSelectedPhoto()
        }
    }
    
    private func loadSelectedPhoto() async {
        guard let selectedPhotoItem else { return }
        
        do {
            if let data = try await selectedPhotoItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                withAnimation(.easeInOut) {
                    selectedImage = image
                }
            }
        } catch {
            print("Failed to load photo: \(error)")
        }
    }
}
