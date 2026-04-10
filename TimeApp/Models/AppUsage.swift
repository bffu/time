import Foundation

struct AppUsageDaily: Codable, Hashable, Sendable, Identifiable {
    let id: UUID
    var day: DayStamp
    var appName: String
    var totalMinutes: Int
    var color: AppColorToken

    init(
        id: UUID = UUID(),
        day: DayStamp,
        appName: String,
        totalMinutes: Int,
        color: AppColorToken = .blue
    ) {
        self.id = id
        self.day = day
        self.appName = appName
        self.totalMinutes = totalMinutes
        self.color = color
    }
}

struct AppUsageHourly: Codable, Hashable, Sendable, Identifiable {
    let id: UUID
    var day: DayStamp
    var appName: String
    var hour: Int
    var minutes: Int

    init(
        id: UUID = UUID(),
        day: DayStamp,
        appName: String,
        hour: Int,
        minutes: Int
    ) {
        self.id = id
        self.day = day
        self.appName = appName
        self.hour = max(0, min(hour, 23))
        self.minutes = max(0, min(minutes, 60))
    }
}

