import Foundation

actor InMemoryDayRecordRepository: DayRecordRepository {
    private var storage: [DayStamp: DayRecord] = [:]

    func save(_ record: DayRecord) async {
        storage[record.day] = record
    }

    func fetch(day: DayStamp) async -> DayRecord? {
        storage[day]
    }

    func fetchAll() async -> [DayRecord] {
        storage.values.sorted { $0.day < $1.day }
    }
}

actor InMemoryAppUsageRepository: AppUsageRepository {
    private var dailyStorage: [DayStamp: [AppUsageDaily]] = [:]
    private var hourlyStorage: [DayStamp: [AppUsageHourly]] = [:]

    func saveDaily(_ records: [AppUsageDaily]) async {
        guard let day = records.first?.day else { return }
        dailyStorage[day] = records
    }

    func saveHourly(_ records: [AppUsageHourly]) async {
        guard let day = records.first?.day else { return }
        hourlyStorage[day] = records
    }

    func replaceDaily(day: DayStamp, with records: [AppUsageDaily]) async {
        dailyStorage[day] = records
    }

    func replaceHourly(day: DayStamp, with records: [AppUsageHourly]) async {
        hourlyStorage[day] = records
    }

    func fetchDaily(day: DayStamp) async -> [AppUsageDaily] {
        dailyStorage[day] ?? []
    }

    func fetchHourly(day: DayStamp) async -> [AppUsageHourly] {
        hourlyStorage[day] ?? []
    }

    func fetchDaily(range: ClosedRange<DayStamp>) async -> [AppUsageDaily] {
        dailyStorage
            .filter { range.contains($0.key) }
            .sorted { $0.key < $1.key }
            .flatMap(\.value)
    }
}

actor InMemoryManualActivityRepository: ManualActivityRepository {
    private var storage: [DayStamp: [ManualActivityBlock]] = [:]

    func save(_ block: ManualActivityBlock) async {
        var blocks = storage[block.day] ?? []
        blocks.removeAll { $0.id == block.id }
        blocks.append(block)
        blocks.sort { $0.startMinuteOfDay < $1.startMinuteOfDay }
        storage[block.day] = blocks
    }

    func delete(id: UUID) async {
        for key in storage.keys {
            storage[key]?.removeAll { $0.id == id }
        }
    }

    func fetch(day: DayStamp) async -> [ManualActivityBlock] {
        storage[day] ?? []
    }
}

actor InMemoryImportBatchRepository: ImportBatchRepository {
    private var storage: [UUID: ImportBatch] = [:]

    func save(_ batch: ImportBatch) async {
        storage[batch.id] = batch
    }

    func fetchAll() async -> [ImportBatch] {
        storage.values.sorted { $0.createdAt > $1.createdAt }
    }

    func fetch(id: UUID) async -> ImportBatch? {
        storage[id]
    }
}
