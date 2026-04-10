import Foundation

struct RecognitionEnvelope: Sendable {
    var screenshots: [ImportedScreenshot]
    var overview: RecognizedOverview?
    var appDetails: [RecognizedAppDetail]
}

struct ReconciliationOutput: Sendable {
    var dayRecord: DayRecord
    var dailyUsages: [AppUsageDaily]
    var hourlyUsages: [AppUsageHourly]
    var warnings: [String]
}

protocol UsageReconciling: Sendable {
    func reconcile(_ envelope: RecognitionEnvelope, manualBlocks: [ManualActivityBlock]) async -> ReconciliationOutput?
}

struct DefaultReconciliationEngine: UsageReconciling {
    func reconcile(_ envelope: RecognitionEnvelope, manualBlocks: [ManualActivityBlock]) async -> ReconciliationOutput? {
        guard let day = envelope.overview?.day ?? envelope.appDetails.first?.day else {
            return nil
        }

        let appDetails = envelope.appDetails.filter { $0.appName != nil }
        let dailyUsages = appDetails.map { detail in
            AppUsageDaily(
                day: day,
                appName: detail.appName ?? "未知 App",
                totalMinutes: detail.totalMinutes ?? detail.hourlyUsage.reduce(0) { $0 + $1.minutes },
                color: .blue
            )
        }

        let hourlyUsages = appDetails.flatMap { detail in
            detail.hourlyUsage.map { slot in
                AppUsageHourly(day: day, appName: detail.appName ?? "未知 App", hour: slot.hour, minutes: slot.minutes)
            }
        }

        let totalScreenMinutes = envelope.overview?.totalScreenMinutes ?? dailyUsages.reduce(0) { $0 + $1.totalMinutes }
        let capturedMinutes = dailyUsages.reduce(0) { $0 + $1.totalMinutes }
        let manualMinutes = manualBlocks.reduce(0) { $0 + $1.durationMinutes }
        let otherAppsMinutes = max(0, totalScreenMinutes - capturedMinutes)
        let unrecordedMinutes = max(0, 1_440 - totalScreenMinutes - manualMinutes)
        let completeness: DayCompleteness = envelope.overview != nil ? .partial : .draft

        let record = DayRecord(
            day: day,
            totalScreenMinutes: totalScreenMinutes,
            otherAppsMinutes: otherAppsMinutes,
            unrecordedMinutes: unrecordedMinutes,
            completeness: completeness,
            screenshotIDs: envelope.screenshots.map(\.id)
        )

        var warnings: [String] = []
        if envelope.overview == nil {
            warnings.append("未导入总览图，日总时长来自 App 详情汇总。")
        }
        if otherAppsMinutes > 0 {
            warnings.append("存在未展开详情图的 App，已归入“其他 App”。")
        }

        return ReconciliationOutput(
            dayRecord: record,
            dailyUsages: dailyUsages,
            hourlyUsages: hourlyUsages,
            warnings: warnings
        )
    }
}

