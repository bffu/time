import Foundation

struct ReportDaySummary: Codable, Hashable, Sendable, Identifiable {
    let id: UUID
    var day: DayStamp
    var totalScreenMinutes: Int
    var topApps: [AppUsageDaily]

    init(id: UUID = UUID(), day: DayStamp, totalScreenMinutes: Int, topApps: [AppUsageDaily]) {
        self.id = id
        self.day = day
        self.totalScreenMinutes = totalScreenMinutes
        self.topApps = topApps
    }
}

struct AppTrendPoint: Codable, Hashable, Sendable, Identifiable {
    let id: UUID
    var day: DayStamp
    var minutes: Int

    init(id: UUID = UUID(), day: DayStamp, minutes: Int) {
        self.id = id
        self.day = day
        self.minutes = minutes
    }
}

struct ReportSnapshot: Codable, Hashable, Sendable {
    var range: ReportRange
    var daySummaries: [ReportDaySummary]
    var appTrends: [String: [AppTrendPoint]]
}

