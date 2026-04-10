import Foundation

protocol ManualActivityManaging: Sendable {
    func save(block: ManualActivityBlock) async
    func delete(blockID: UUID) async
    func blocks(for day: DayStamp) async -> [ManualActivityBlock]
}

struct ManualActivityService: ManualActivityManaging {
    let repository: ManualActivityRepository

    func save(block: ManualActivityBlock) async {
        await repository.save(block)
    }

    func delete(blockID: UUID) async {
        await repository.delete(id: blockID)
    }

    func blocks(for day: DayStamp) async -> [ManualActivityBlock] {
        await repository.fetch(day: day)
    }
}

