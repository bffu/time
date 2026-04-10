import Foundation

protocol DayRecordRepository: Sendable {
    func save(_ record: DayRecord) async
    func fetch(day: DayStamp) async -> DayRecord?
    func fetchAll() async -> [DayRecord]
}

protocol AppUsageRepository: Sendable {
    func saveDaily(_ records: [AppUsageDaily]) async
    func saveHourly(_ records: [AppUsageHourly]) async
    func replaceDaily(day: DayStamp, with records: [AppUsageDaily]) async
    func replaceHourly(day: DayStamp, with records: [AppUsageHourly]) async
    func fetchDaily(day: DayStamp) async -> [AppUsageDaily]
    func fetchHourly(day: DayStamp) async -> [AppUsageHourly]
    func fetchDaily(range: ClosedRange<DayStamp>) async -> [AppUsageDaily]
}

protocol ManualActivityRepository: Sendable {
    func save(_ block: ManualActivityBlock) async
    func delete(id: UUID) async
    func fetch(day: DayStamp) async -> [ManualActivityBlock]
}

protocol ImportBatchRepository: Sendable {
    func save(_ batch: ImportBatch) async
    func fetchAll() async -> [ImportBatch]
    func fetch(id: UUID) async -> ImportBatch?
}
