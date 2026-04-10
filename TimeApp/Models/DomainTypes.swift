import Foundation

struct DayStamp: Codable, Hashable, Sendable, Comparable, Identifiable {
    let year: Int
    let month: Int
    let day: Int

    var id: String { iso8601String }

    var iso8601String: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        self.year = components.year ?? 1970
        self.month = components.month ?? 1
        self.day = components.day ?? 1
    }

    static func < (lhs: DayStamp, rhs: DayStamp) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}

enum ScreenshotKind: String, Codable, Sendable, CaseIterable {
    case overview
    case appDetail
    case unknown
}

enum ImportBatchStatus: String, Codable, Sendable, CaseIterable {
    case draft
    case processing
    case readyForReview
    case imported
    case failed

    var title: String {
        switch self {
        case .draft:
            return "待识别"
        case .processing:
            return "处理中"
        case .readyForReview:
            return "待复核"
        case .imported:
            return "已导入"
        case .failed:
            return "失败"
        }
    }
}

enum DayCompleteness: String, Codable, Sendable, CaseIterable {
    case draft
    case partial
    case complete
}

enum ActivitySource: String, Codable, Sendable, CaseIterable {
    case importedApp
    case manualBlock
    case derivedOtherApps
    case unrecorded
}

enum ReportRange: String, Codable, Sendable, CaseIterable, Identifiable {
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week:
            return "最近 7 天"
        case .month:
            return "最近 30 天"
        }
    }
}

struct HourSlot: Codable, Hashable, Sendable, Identifiable {
    let hour: Int
    let minutes: Int

    var id: Int { hour }

    init(hour: Int, minutes: Int) {
        self.hour = hour
        self.minutes = max(0, min(minutes, 60))
    }
}

struct AppColorToken: Codable, Hashable, Sendable {
    let hex: String

    static let blue = AppColorToken(hex: "#3B82F6")
    static let green = AppColorToken(hex: "#10B981")
    static let orange = AppColorToken(hex: "#F59E0B")
    static let pink = AppColorToken(hex: "#EC4899")
    static let gray = AppColorToken(hex: "#64748B")
    static let red = AppColorToken(hex: "#EF4444")
}

struct TimelineSlice: Codable, Hashable, Sendable, Identifiable {
    let id: UUID
    let title: String
    let source: ActivitySource
    let color: AppColorToken
    let startMinuteOfDay: Int
    let durationMinutes: Int
}
