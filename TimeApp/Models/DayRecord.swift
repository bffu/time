import Foundation

struct DayRecord: Codable, Hashable, Sendable, Identifiable {
    let id: UUID
    var day: DayStamp
    var totalScreenMinutes: Int
    var otherAppsMinutes: Int
    var unrecordedMinutes: Int
    var completeness: DayCompleteness
    var notes: String
    var screenshotIDs: [UUID]

    init(
        id: UUID = UUID(),
        day: DayStamp,
        totalScreenMinutes: Int,
        otherAppsMinutes: Int = 0,
        unrecordedMinutes: Int = 0,
        completeness: DayCompleteness = .draft,
        notes: String = "",
        screenshotIDs: [UUID] = []
    ) {
        self.id = id
        self.day = day
        self.totalScreenMinutes = totalScreenMinutes
        self.otherAppsMinutes = otherAppsMinutes
        self.unrecordedMinutes = unrecordedMinutes
        self.completeness = completeness
        self.notes = notes
        self.screenshotIDs = screenshotIDs
    }
}

