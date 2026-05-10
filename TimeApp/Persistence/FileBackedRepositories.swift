import Foundation

actor FileBackedDayRecordRepository: DayRecordRepository {
    private let store = JSONFileStore<[DayRecord]>(fileName: "day-records.json", defaultValue: [])

    func save(_ record: DayRecord) async {
        await store.mutate { records in
            records.removeAll { $0.day == record.day }
            records.append(record)
        }
    }

    func fetch(day: DayStamp) async -> DayRecord? {
        await store.read().first { $0.day == day }
    }

    func fetchAll() async -> [DayRecord] {
        await store.read().sorted { $0.day < $1.day }
    }
}

actor FileBackedAppUsageRepository: AppUsageRepository {
    private let store = JSONFileStore<AppUsageStoreState>(fileName: "app-usages.json", defaultValue: AppUsageStoreState())

    func saveDaily(_ records: [AppUsageDaily]) async {
        guard let day = records.first?.day else { return }
        await replaceDaily(day: day, with: records)
    }

    func saveHourly(_ records: [AppUsageHourly]) async {
        guard let day = records.first?.day else { return }
        await replaceHourly(day: day, with: records)
    }

    func replaceDaily(day: DayStamp, with records: [AppUsageDaily]) async {
        await store.mutate { state in
            state.daily.removeAll { $0.day == day }
            state.daily.append(contentsOf: records)
        }
    }

    func replaceHourly(day: DayStamp, with records: [AppUsageHourly]) async {
        await store.mutate { state in
            state.hourly.removeAll { $0.day == day }
            state.hourly.append(contentsOf: records)
        }
    }

    func fetchDaily(day: DayStamp) async -> [AppUsageDaily] {
        await store.read().daily.filter { $0.day == day }
    }

    func fetchHourly(day: DayStamp) async -> [AppUsageHourly] {
        await store.read().hourly.filter { $0.day == day }
    }

    func fetchDaily(range: ClosedRange<DayStamp>) async -> [AppUsageDaily] {
        await store.read().daily.filter { range.contains($0.day) }
    }
}

actor FileBackedManualActivityRepository: ManualActivityRepository {
    private let store = JSONFileStore<[ManualActivityBlock]>(fileName: "manual-blocks.json", defaultValue: [])

    func save(_ block: ManualActivityBlock) async {
        await store.mutate { blocks in
            blocks.removeAll { $0.id == block.id }
            blocks.append(block)
        }
    }

    func delete(id: UUID) async {
        await store.mutate { blocks in
            blocks.removeAll { $0.id == id }
        }
    }

    func fetch(day: DayStamp) async -> [ManualActivityBlock] {
        await store.read()
            .filter { $0.day == day }
            .sorted { $0.startMinuteOfDay < $1.startMinuteOfDay }
    }
}

actor FileBackedImportBatchRepository: ImportBatchRepository {
    private let store = JSONFileStore<[ImportBatch]>(fileName: "import-batches.json", defaultValue: [])

    func save(_ batch: ImportBatch) async {
        await store.mutate { batches in
            batches.removeAll { $0.id == batch.id }
            batches.append(batch)
        }
    }

    func fetchAll() async -> [ImportBatch] {
        await store.read().sorted { $0.createdAt > $1.createdAt }
    }

    func fetch(id: UUID) async -> ImportBatch? {
        await store.read().first { $0.id == id }
    }
}

private struct AppUsageStoreState: Codable, Sendable {
    var daily: [AppUsageDaily] = []
    var hourly: [AppUsageHourly] = []
}

private actor JSONFileStore<Value: Codable & Sendable> {
    private let fileURL: URL
    private let defaultValue: @Sendable () -> Value
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileName: String, defaultValue: Value) {
        self.fileURL = Self.applicationSupportDirectory().appendingPathComponent(fileName)
        self.defaultValue = { defaultValue }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func read() -> Value {
        guard let data = try? Data(contentsOf: fileURL),
              let value = try? decoder.decode(Value.self, from: data) else {
            return defaultValue()
        }
        return value
    }

    func mutate(_ update: @Sendable (inout Value) -> Void) {
        var value = read()
        update(&value)
        write(value)
    }

    private func write(_ value: Value) {
        do {
            let directoryURL = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            let data = try encoder.encode(value)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            assertionFailure("Unable to persist TimeApp data: \(error.localizedDescription)")
        }
    }

    private static func applicationSupportDirectory() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return baseURL.appendingPathComponent("TimeApp", isDirectory: true)
    }
}
