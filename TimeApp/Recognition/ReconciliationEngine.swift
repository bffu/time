import Foundation

struct RecognitionEnvelope: Sendable {
    var screenshots: [ImportedScreenshot]
    var overview: RecognizedOverview?
    var appDetails: [RecognizedAppDetail]
    var warnings: [String]

    init(
        screenshots: [ImportedScreenshot],
        overview: RecognizedOverview?,
        appDetails: [RecognizedAppDetail],
        warnings: [String] = []
    ) {
        self.screenshots = screenshots
        self.overview = overview
        self.appDetails = appDetails
        self.warnings = warnings
    }
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

        let appDetails = consolidateAppDetails(envelope.appDetails)
        let dailyUsages = appDetails.map { detail in
            AppUsageDaily(
                day: day,
                appName: detail.appName ?? "未知 App",
                totalMinutes: detail.totalMinutes ?? detail.hourlyUsage.reduce(0) { $0 + $1.minutes },
                color: .blue
            )
        }

        let rawHourlyUsages = appDetails.flatMap { detail in
            detail.hourlyUsage.map { slot in
                AppUsageHourly(day: day, appName: detail.appName ?? "未知 App", hour: slot.hour, minutes: slot.minutes)
            }
        }
        let normalizedHourly = normalizeHourlyTotals(rawHourlyUsages)

        let rawTotalScreenMinutes = envelope.overview?.totalScreenMinutes ?? dailyUsages.reduce(0) { $0 + $1.totalMinutes }
        let totalScreenMinutes = min(1_440, rawTotalScreenMinutes)
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

        var warnings = envelope.warnings
        if envelope.overview == nil {
            warnings.append("未导入总览图，日总时长来自 App 详情汇总。")
        }
        if otherAppsMinutes > 0 {
            warnings.append("存在未展开详情图的 App，已归入“其他 App”。")
        }
        if rawTotalScreenMinutes > 1_440 {
            warnings.append("识别到的屏幕时间超过 24 小时，已按 24 小时封顶。")
        }
        if capturedMinutes > totalScreenMinutes {
            warnings.append("App 详情汇总超过总览时长，请复核重复截图或识别结果。")
        }
        if hasOverlappingManualBlocks(manualBlocks) {
            warnings.append("手动补录时间段存在重叠，请复核当天记录。")
        }
        warnings.append(contentsOf: normalizedHourly.warnings)

        return ReconciliationOutput(
            dayRecord: record,
            dailyUsages: dailyUsages,
            hourlyUsages: normalizedHourly.records,
            warnings: deduplicated(warnings)
        )
    }

    private func consolidateAppDetails(_ details: [RecognizedAppDetail]) -> [RecognizedAppDetail] {
        let namedDetails = details.compactMap { detail -> (String, RecognizedAppDetail)? in
            guard let name = detail.appName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
                return nil
            }
            var normalized = detail
            normalized.appName = name
            return (name, normalized)
        }

        return Dictionary(grouping: namedDetails, by: { $0.0 }).map { name, entries in
            var best = entries
                .map(\.1)
                .max { score(for: $0) < score(for: $1) } ?? entries[0].1

            let bestTotal = entries
                .map(\.1)
                .compactMap { $0.totalMinutes ?? totalHourlyMinutes($0.hourlyUsage) }
                .max()

            best.appName = name
            best.totalMinutes = bestTotal
            best.hourlyUsage = mergeHourlySlots(entries.flatMap { $0.1.hourlyUsage })
            return best
        }
        .sorted { ($0.totalMinutes ?? 0) > ($1.totalMinutes ?? 0) }
    }

    private func mergeHourlySlots(_ slots: [HourSlot]) -> [HourSlot] {
        Dictionary(grouping: slots, by: \.hour)
            .map { hour, values in
                HourSlot(hour: hour, minutes: values.map(\.minutes).max() ?? 0)
            }
            .sorted { $0.hour < $1.hour }
    }

    private func normalizeHourlyTotals(_ records: [AppUsageHourly]) -> (records: [AppUsageHourly], warnings: [String]) {
        let groupedByHour = Dictionary(grouping: records, by: \.hour)
        var normalized: [AppUsageHourly] = []
        var warnings: [String] = []

        for hour in groupedByHour.keys.sorted() {
            let hourRecords = groupedByHour[hour] ?? []
            let total = hourRecords.reduce(0) { $0 + $1.minutes }
            guard total > 60 else {
                normalized.append(contentsOf: hourRecords)
                continue
            }

            warnings.append("\(hour):00 的 App 小时用量超过 60 分钟，已按比例压缩。")
            normalized.append(contentsOf: scale(hourRecords, to: 60))
        }

        return (
            normalized.sorted { lhs, rhs in
                if lhs.hour == rhs.hour {
                    return lhs.appName < rhs.appName
                }
                return lhs.hour < rhs.hour
            },
            warnings
        )
    }

    private func scale(_ records: [AppUsageHourly], to targetMinutes: Int) -> [AppUsageHourly] {
        let currentTotal = records.reduce(0) { $0 + $1.minutes }
        guard currentTotal > 0 else { return records }

        let minimumMinutes = records.count > targetMinutes ? 0 : 1
        var scaled = records.map { record -> AppUsageHourly in
            let minutes = max(minimumMinutes, Int((Double(record.minutes) / Double(currentTotal) * Double(targetMinutes)).rounded()))
            return AppUsageHourly(day: record.day, appName: record.appName, hour: record.hour, minutes: minutes)
        }

        var delta = targetMinutes - scaled.reduce(0) { $0 + $1.minutes }
        var index = 0
        while delta != 0, !scaled.isEmpty, index < scaled.count * 4 {
            let recordIndex = index % scaled.count
            let current = scaled[recordIndex]
            if delta > 0, current.minutes < 60 {
                scaled[recordIndex] = AppUsageHourly(day: current.day, appName: current.appName, hour: current.hour, minutes: current.minutes + 1)
                delta -= 1
            } else if delta < 0, current.minutes > minimumMinutes {
                scaled[recordIndex] = AppUsageHourly(day: current.day, appName: current.appName, hour: current.hour, minutes: current.minutes - 1)
                delta += 1
            }
            index += 1
        }

        return scaled
    }

    private func hasOverlappingManualBlocks(_ blocks: [ManualActivityBlock]) -> Bool {
        let sorted = blocks.sorted { $0.startMinuteOfDay < $1.startMinuteOfDay }
        for index in sorted.indices.dropFirst() where sorted[index].startMinuteOfDay < sorted[index - 1].endMinuteOfDay {
            return true
        }
        return false
    }

    private func score(for detail: RecognizedAppDetail) -> Int {
        let totalScore = detail.totalMinutes == nil ? 0 : 2
        let hourlyScore = detail.hourlyUsage.isEmpty ? 0 : 1
        return totalScore + hourlyScore
    }

    private func totalHourlyMinutes(_ slots: [HourSlot]) -> Int? {
        let total = slots.reduce(0) { $0 + $1.minutes }
        return total > 0 ? total : nil
    }

    private func deduplicated(_ warnings: [String]) -> [String] {
        var result: [String] = []
        for warning in warnings where !result.contains(warning) {
            result.append(warning)
        }
        return result
    }
}
