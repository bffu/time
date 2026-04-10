import Foundation

struct ManualActivityBlock: Codable, Hashable, Sendable, Identifiable {
    let id: UUID
    var day: DayStamp
    var title: String
    var startMinuteOfDay: Int
    var endMinuteOfDay: Int
    var color: AppColorToken
    var note: String

    var durationMinutes: Int {
        max(0, endMinuteOfDay - startMinuteOfDay)
    }

    init(
        id: UUID = UUID(),
        day: DayStamp,
        title: String,
        startMinuteOfDay: Int,
        endMinuteOfDay: Int,
        color: AppColorToken = .green,
        note: String = ""
    ) {
        self.id = id
        self.day = day
        self.title = title
        self.startMinuteOfDay = max(0, min(startMinuteOfDay, 1_439))
        self.endMinuteOfDay = max(0, min(endMinuteOfDay, 1_440))
        self.color = color
        self.note = note
    }
}

