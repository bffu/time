import Foundation

struct DayTimeline: Sendable {
    var day: DayStamp
    var slices: [TimelineSlice]
}

protocol TimelineBuilding: Sendable {
    func buildTimeline(
        dayRecord: DayRecord,
        appUsages: [AppUsageDaily],
        manualBlocks: [ManualActivityBlock]
    ) async -> DayTimeline
}

struct TimelineService: TimelineBuilding {
    func buildTimeline(
        dayRecord: DayRecord,
        appUsages: [AppUsageDaily],
        manualBlocks: [ManualActivityBlock]
    ) async -> DayTimeline {
        var slices: [TimelineSlice] = []
        var cursor = 0

        for block in manualBlocks.sorted(by: { $0.startMinuteOfDay < $1.startMinuteOfDay }) {
            slices.append(
                TimelineSlice(
                    id: block.id,
                    title: block.title,
                    source: .manualBlock,
                    color: block.color,
                    startMinuteOfDay: block.startMinuteOfDay,
                    durationMinutes: block.durationMinutes
                )
            )
            cursor = max(cursor, block.endMinuteOfDay)
        }

        for usage in appUsages.sorted(by: { $0.totalMinutes > $1.totalMinutes }) {
            let duration = usage.totalMinutes
            guard duration > 0 else { continue }

            slices.append(
                TimelineSlice(
                    id: usage.id,
                    title: usage.appName,
                    source: .importedApp,
                    color: usage.color,
                    startMinuteOfDay: cursor,
                    durationMinutes: min(duration, max(0, 1_440 - cursor))
                )
            )
            cursor = min(1_440, cursor + duration)
        }

        if dayRecord.otherAppsMinutes > 0 {
            slices.append(
                TimelineSlice(
                    id: UUID(),
                    title: "其他 App",
                    source: .derivedOtherApps,
                    color: .gray,
                    startMinuteOfDay: cursor,
                    durationMinutes: min(dayRecord.otherAppsMinutes, max(0, 1_440 - cursor))
                )
            )
            cursor = min(1_440, cursor + dayRecord.otherAppsMinutes)
        }

        if cursor < 1_440 {
            slices.append(
                TimelineSlice(
                    id: UUID(),
                    title: "未记录时间",
                    source: .unrecorded,
                    color: .red,
                    startMinuteOfDay: cursor,
                    durationMinutes: 1_440 - cursor
                )
            )
        }

        return DayTimeline(day: dayRecord.day, slices: slices)
    }
}

