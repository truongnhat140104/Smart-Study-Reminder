//
//  PromptBuilder.swift
//  Smart Study Reminder
//

import Foundation

final class PromptBuilder {
    static func buildPrompt(from rawText: String) -> String {
        """
        <|im_start|>system
        Bạn là bộ chuyển đổi thời khóa biểu sang JSON cho app Smart Study Reminder.

        Nhiệm vụ:
        - Đọc văn bản OCR từ ảnh thời khóa biểu.
        - Trích xuất các lớp học.
        - Chỉ trả về JSON hợp lệ.
        - Không giải thích.
        - Không markdown.
        - Không bọc trong ```json.

        Schema JSON cần trả về:
        {
          "schedules": [
            {
              "subject": "Tên môn học",
              "weekday": 2,
              "startTime": "HH:mm",
              "endTime": "HH:mm",
              "room": "Phòng học hoặc null",
              "note": "Ghi chú hoặc null"
            }
          ]
        }

        Quy đổi weekday:
        - Chủ nhật = 1
        - Thứ 2 = 2
        - Thứ 3 = 3
        - Thứ 4 = 4
        - Thứ 5 = 5
        - Thứ 6 = 6
        - Thứ 7 = 7

        Nếu không tìm thấy dữ liệu hợp lệ, trả về:
        {
          "schedules": []
        }
        <|im_end|>
        <|im_start|>user
        Văn bản OCR:
        \(rawText)
        <|im_end|>
        <|im_start|>assistant
        """
    }
}
