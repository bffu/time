import Foundation

enum SampleDataFactory {
    static func makeDayRecord() -> DayRecord {
        DayRecord(
            day: DayStamp(date: .now),
            totalScreenMinutes: 387,
            otherAppsMinutes: 46,
            unrecordedMinutes: 530,
            completeness: .partial,
            notes: "样例数据用于骨架阶段预览。"
        )
    }

    static func makeDailyUsages(day: DayStamp = DayStamp(date: .now)) -> [AppUsageDaily] {
        [
            AppUsageDaily(day: day, appName: "抖音", totalMinutes: 206, color: .pink),
            AppUsageDaily(day: day, appName: "微信", totalMinutes: 74, color: .green),
            AppUsageDaily(day: day, appName: "不背单词", totalMinutes: 31, color: .orange),
            AppUsageDaily(day: day, appName: "Container", totalMinutes: 30, color: .blue)
        ]
    }

    static func makeHourlyUsages(day: DayStamp = DayStamp(date: .now)) -> [AppUsageHourly] {
        [
            AppUsageHourly(day: day, appName: "抖音", hour: 0, minutes: 26),
            AppUsageHourly(day: day, appName: "抖音", hour: 1, minutes: 18),
            AppUsageHourly(day: day, appName: "抖音", hour: 18, minutes: 21),
            AppUsageHourly(day: day, appName: "抖音", hour: 19, minutes: 34),
            AppUsageHourly(day: day, appName: "微信", hour: 12, minutes: 14),
            AppUsageHourly(day: day, appName: "微信", hour: 20, minutes: 18)
        ]
    }

    static func makeManualBlocks(day: DayStamp = DayStamp(date: .now)) -> [ManualActivityBlock] {
        [
            ManualActivityBlock(day: day, title: "睡觉", startMinuteOfDay: 0, endMinuteOfDay: 420, color: .gray),
            ManualActivityBlock(day: day, title: "通勤", startMinuteOfDay: 480, endMinuteOfDay: 540, color: .orange),
            ManualActivityBlock(day: day, title: "工作", startMinuteOfDay: 540, endMinuteOfDay: 1_020, color: .green)
        ]
    }
}
