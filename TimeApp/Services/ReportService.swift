import Foundation

protocol ReportProviding: Sendable {
    func snapshot(range: ReportRange, endingOn day: DayStamp) async -> ReportSnapshot
}

struct ReportService: ReportProviding {
    let dayRepository: DayRecordRepository
    let usageRepository: AppUsageRepository

    func snapshot(range: ReportRange, endingOn day: DayStamp) async -> ReportSnapshot {
        let allRecords = await dayRepository.fetchAll().sorted { $0.day < $1.day }
        let targetRange = reportWindow(for: range, endingOn: day)
        let targetRecords = allRecords.filter { targetRange.contains($0.day) }

        let summaries = await withTaskGroup(of: ReportDaySummary?.self) { group in
            for record in targetRecords {
                group.addTask {
                    let topApps = await usageRepository.fetchDaily(day: record.day)
                        .sorted { $0.totalMinutes > $1.totalMinutes }
                    return ReportDaySummary(day: record.day, totalScreenMinutes: record.totalScreenMinutes, topApps: Array(topApps.prefix(5)))
                }
            }

            var result: [ReportDaySummary] = []
            for await summary in group {
                if let summary {
                    result.append(summary)
                }
            }
            return result.sorted { $0.day < $1.day }
        }

        let appTrends = summaries.reduce(into: [String: [AppTrendPoint]]()) { partialResult, summary in
            for app in summary.topApps {
                partialResult[app.appName, default: []].append(AppTrendPoint(day: summary.day, minutes: app.totalMinutes))
            }
        }

        return ReportSnapshot(range: range, daySummaries: summaries, appTrends: appTrends)
    }

    private func reportWindow(for range: ReportRange, endingOn endDay: DayStamp) -> ClosedRange<DayStamp> {
        let calendar = Calendar.current
        let endDate = calendar.date(from: DateComponents(year: endDay.year, month: endDay.month, day: endDay.day)) ?? .now
        let daysToSubtract: Int

        switch range {
        case .week:
            daysToSubtract = 6
        case .month:
            daysToSubtract = 29
        }

        let startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: endDate) ?? endDate
        return DayStamp(date: startDate)...endDay
    }
}
