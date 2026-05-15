import UIKit
import Vision

struct OCRLine {
    let text: String
    let boundingBox: CGRect
}

enum TimetableWeekday: String, CaseIterable, Hashable {
    case monday = "Thứ 2"
    case tuesday = "Thứ 3"
    case wednesday = "Thứ 4"
    case thursday = "Thứ 5"
    case friday = "Thứ 6"
    case saturday = "Thứ 7"
    case sunday = "Chủ nhật"

    var searchTokens: [String] {
        switch self {
        case .monday:
            return ["thu2", "thuhai"]
        case .tuesday:
            return ["thu3", "thuba"]
        case .wednesday:
            return ["thu4", "thutu"]
        case .thursday:
            return ["thu5", "thunam"]
        case .friday:
            return ["thu6", "thusau"]
        case .saturday:
            return ["thu7", "thubay"]
        case .sunday:
            return ["chunhat", "cn"]
        }
    }

    static let visibleWeekdays: [TimetableWeekday] = [
        .monday,
        .tuesday,
        .wednesday,
        .thursday,
        .friday,
        .saturday
    ]

    static func matchingHeader(in text: String) -> TimetableWeekday? {
        let normalizedText = text.normalizedForTimetableSearch

        return TimetableWeekday.visibleWeekdays.first { weekday in
            weekday.searchTokens.contains { token in
                normalizedText.contains(token)
            }
        }
    }
}

final class OCRService {
    /// Hàm chính cho màn hình đọc TKB.
    /// Trả text đã được lọc theo cột: Thứ 2 đọc dọc xuống hết Thứ 2,
    /// rồi mới tới Thứ 3, Thứ 4...
    static func extractText(from image: UIImage) async throws -> String {
        try await extractTimetableText(from: image)
    }

    /// Hàm OCR thường, đọc theo dòng ngang từ trên xuống.
    /// Chỉ dùng hàm này nếu bạn KHÔNG đọc ảnh thời khóa biểu.
    static func extractPlainText(from image: UIImage) async throws -> String {
        let lines = try await extractLines(from: image)

        return lines
            .sortedForPlainReading()
            .map(\.text)
            .joined(separator: "\n")
    }

    static func extractTimetableText(from image: UIImage) async throws -> String {
        let groupedText = try await extractTimetableTextByWeekday(from: image)

        return TimetableWeekday.visibleWeekdays.compactMap { weekday in
            guard let text = groupedText[weekday], !text.isEmpty else {
                return nil
            }

            return "\(weekday.rawValue)\n\(text)"
        }
        .joined(separator: "\n\n")
    }

    static func extractTimetableTextByWeekday(from image: UIImage) async throws -> [TimetableWeekday: String] {
        let lines = try await extractLines(from: image)
        return groupTimetableByWeekday(lines: lines)
    }

    static func extractLines(from image: UIImage) async throws -> [OCRLine] {
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
                    continuation.resume(returning: [])
                    return
                }

                let lines = observations.compactMap { observation -> OCRLine? in
                    guard let text = observation.topCandidates(1).first?.string
                        .trimmingCharacters(in: .whitespacesAndNewlines),
                          !text.isEmpty else {
                        return nil
                    }

                    return OCRLine(
                        text: text,
                        boundingBox: observation.boundingBox
                    )
                }

                continuation.resume(returning: lines)
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

    static func groupTimetableByWeekday(lines: [OCRLine]) -> [TimetableWeekday: String] {
        let columnRanges = makeWeekdayColumnRanges(from: lines)
        var groupedLines: [TimetableWeekday: [OCRLine]] = [:]

        for weekday in TimetableWeekday.visibleWeekdays {
            groupedLines[weekday] = []
        }

        for line in lines {
            // Bỏ qua dòng tiêu đề cột: "Thứ 2 (12/01)", "Thứ 3 (13/01)"...
            if TimetableWeekday.matchingHeader(in: line.text) != nil {
                continue
            }

            let centerX = line.boundingBox.midX

            guard let weekday = TimetableWeekday.visibleWeekdays.first(where: { weekday in
                guard let range = columnRanges[weekday] else { return false }
                return range.contains(centerX)
            }) else {
                continue
            }

            groupedLines[weekday, default: []].append(line)
        }

        var result: [TimetableWeekday: String] = [:]

        for weekday in TimetableWeekday.visibleWeekdays {
            let text = groupedLines[weekday, default: []]
                .sortedForColumnReading()
                .map(\.text)
                .joined(separator: "\n")

            result[weekday] = text
        }

        return result
    }

    private static func makeWeekdayColumnRanges(from lines: [OCRLine]) -> [TimetableWeekday: ClosedRange<CGFloat>] {
        let detectedHeaders = lines.compactMap { line -> (weekday: TimetableWeekday, centerX: CGFloat)? in
            guard let weekday = TimetableWeekday.matchingHeader(in: line.text) else {
                return nil
            }

            return (weekday, line.boundingBox.midX)
        }

        let uniqueHeaders = Dictionary(grouping: detectedHeaders) { header in
            header.weekday
        }
        .map { weekday, headers in
            let averageX = headers.map(\.centerX).reduce(0, +) / CGFloat(headers.count)
            return (weekday: weekday, centerX: averageX)
        }
        .sorted { $0.centerX < $1.centerX }

        guard uniqueHeaders.count >= 2 else {
            return makeFallbackWeekdayColumnRanges()
        }

        var ranges: [TimetableWeekday: ClosedRange<CGFloat>] = [:]

        for index in uniqueHeaders.indices {
            let current = uniqueHeaders[index]
            let lowerBound: CGFloat
            let upperBound: CGFloat

            if index == uniqueHeaders.startIndex {
                let next = uniqueHeaders[index + 1]
                let halfWidth = (next.centerX - current.centerX) / 2
                lowerBound = max(0, current.centerX - halfWidth)
            } else {
                let previous = uniqueHeaders[index - 1]
                lowerBound = (previous.centerX + current.centerX) / 2
            }

            if index == uniqueHeaders.index(before: uniqueHeaders.endIndex) {
                let previous = uniqueHeaders[index - 1]
                let halfWidth = (current.centerX - previous.centerX) / 2
                upperBound = min(1, current.centerX + halfWidth)
            } else {
                let next = uniqueHeaders[index + 1]
                upperBound = (current.centerX + next.centerX) / 2
            }

            ranges[current.weekday] = lowerBound...upperBound
        }

        return ranges
    }

    private static func makeFallbackWeekdayColumnRanges() -> [TimetableWeekday: ClosedRange<CGFloat>] {
        let weekdays = TimetableWeekday.visibleWeekdays
        let columnWidth = CGFloat(1.0) / CGFloat(weekdays.count)
        var ranges: [TimetableWeekday: ClosedRange<CGFloat>] = [:]

        for (index, weekday) in weekdays.enumerated() {
            let lowerBound = CGFloat(index) * columnWidth
            let upperBound = index == weekdays.count - 1 ? CGFloat(1.0) : CGFloat(index + 1) * columnWidth
            ranges[weekday] = lowerBound...upperBound
        }

        return ranges
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

private extension Array where Element == OCRLine {
    /// Đọc OCR thường: từ trên xuống, nếu cùng hàng thì từ trái sang phải.
    func sortedForPlainReading() -> [OCRLine] {
        sorted { lhs, rhs in
            let yDifference = abs(lhs.boundingBox.midY - rhs.boundingBox.midY)

            if yDifference > 0.01 {
                return lhs.boundingBox.midY > rhs.boundingBox.midY
            }

            return lhs.boundingBox.minX < rhs.boundingBox.minX
        }
    }

    /// Đọc trong 1 cột TKB: chỉ cần từ trên xuống dưới.
    func sortedForColumnReading() -> [OCRLine] {
        sorted { lhs, rhs in
            let yDifference = abs(lhs.boundingBox.midY - rhs.boundingBox.midY)

            if yDifference > 0.01 {
                return lhs.boundingBox.midY > rhs.boundingBox.midY
            }

            return lhs.boundingBox.minX < rhs.boundingBox.minX
        }
    }
}

private extension String {
    var normalizedForTimetableSearch: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN"))
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
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
