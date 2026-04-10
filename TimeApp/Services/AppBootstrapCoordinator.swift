import Foundation

protocol AppBootstrapping: Sendable {
    func seedPreviewDataIfNeeded() async
}

struct AppBootstrapCoordinator: AppBootstrapping {
    let dayRepository: DayRecordRepository
    let usageRepository: AppUsageRepository
    let manualRepository: ManualActivityRepository

    func seedPreviewDataIfNeeded() async {
        let records = await dayRepository.fetchAll()
        guard records.isEmpty else { return }

        let today = DayStamp(date: .now)
        let yesterday = DayStamp(date: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now)
        let twoDaysAgo = DayStamp(date: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now)

        let sampleDays = [twoDaysAgo, yesterday, today]
        for (offset, day) in sampleDays.enumerated() {
            let record = DayRecord(
                day: day,
                totalScreenMinutes: 320 + (offset * 35),
                otherAppsMinutes: 40,
                unrecordedMinutes: 520 - (offset * 20),
                completeness: .partial
            )
            await dayRepository.save(record)
            await usageRepository.saveDaily(SampleDataFactory.makeDailyUsages(day: day))
            await usageRepository.saveHourly(SampleDataFactory.makeHourlyUsages(day: day))
            for block in SampleDataFactory.makeManualBlocks(day: day) {
                await manualRepository.save(block)
            }
        }
    }
}

