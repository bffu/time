import Foundation

struct DaySnapshot: Sendable {
    var dayRecord: DayRecord
    var dailyUsages: [AppUsageDaily]
    var hourlyUsages: [AppUsageHourly]
    var manualBlocks: [ManualActivityBlock]
}

protocol DaySnapshotProviding: Sendable {
    func snapshot(for day: DayStamp) async -> DaySnapshot?
}

struct DaySnapshotService: DaySnapshotProviding {
    let dayRepository: DayRecordRepository
    let usageRepository: AppUsageRepository
    let manualRepository: ManualActivityRepository

    func snapshot(for day: DayStamp) async -> DaySnapshot? {
        guard let record = await dayRepository.fetch(day: day) else {
            return nil
        }

        async let dailyUsages = usageRepository.fetchDaily(day: day)
        async let hourlyUsages = usageRepository.fetchHourly(day: day)
        async let manualBlocks = manualRepository.fetch(day: day)

        return await DaySnapshot(
            dayRecord: record,
            dailyUsages: dailyUsages,
            hourlyUsages: hourlyUsages,
            manualBlocks: manualBlocks
        )
    }
}
