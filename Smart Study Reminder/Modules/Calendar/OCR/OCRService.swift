//import Foundation
//import UIKit
//import Vision
//
//class OCRService {
//    
//    // Hàm nhận vào ảnh UIImage và trả ra chuỗi Text
//    static func extractText(from image: UIImage, completion: @escaping (String?) -> Void) {
//        guard let cgImage = image.cgImage else {
//            print("Lỗi: Không thể chuyển đổi định dạng ảnh.")
//            completion(nil)
//            return
//        }
//        
//        let request = VNRecognizeTextRequest { (request, error) in
//            if let error = error {
//                print("Lỗi OCR: \(error.localizedDescription)")
//                completion(nil)
//                return
//            } 
//            
//            guard let observations = request.results as? [VNRecognizedTextObservation] else {
//                completion(nil)
//                return
//            }
//            
//            // Lọc và nối các chữ lại với nhau
//            let recognizedStrings = observations.compactMap { observation in
//                return observation.topCandidates(1).first?.string
//            }
//            
//            let fullText = recognizedStrings.joined(separator: "\n")
//            completion(fullText)
//        }
//        
//        // Cấu hình tối ưu cho Tiếng Việt và độ chính xác cao
//        request.recognitionLevel = .accurate
//        request.recognitionLanguages = ["vi-VN", "en-US"]
//        request.usesLanguageCorrection = true
//        
//        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
//        
//        // Chạy request trong luồng ngầm để không đơ App
//        DispatchQueue.global(qos: .userInitiated).async {
//            do {
//                try requestHandler.perform([request])
//            } catch {
//                print("Lỗi khi chạy OCR Scanner: \(error)")
//                completion(nil)
//            }
//        }
//    }
//}

//
//  OCRService.swift
//  Smart Study Reminder
//

import UIKit
import Vision

final class OCRService {
    static func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                let lines = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                let text = lines.joined(separator: "\n")
                continuation.resume(returning: text)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["vi-VN", "en-US"]
            
            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: image.cgImagePropertyOrientation,
                options: [:]
            )
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

enum OCRError: LocalizedError {
    case invalidImage
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Không đọc được ảnh."
        }
    }
}

private extension UIImage {
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up:
            return .up
        case .down:
            return .down
        case .left:
            return .left
        case .right:
            return .right
        case .upMirrored:
            return .upMirrored
        case .downMirrored:
            return .downMirrored
        case .leftMirrored:
            return .leftMirrored
        case .rightMirrored:
            return .rightMirrored
        @unknown default:
            return .up
        }
    }
}
