import Foundation

protocol ManualActivityManaging: Sendable {
    @discardableResult
    func save(block: ManualActivityBlock) async -> Bool
    func delete(blockID: UUID) async
    func blocks(for day: DayStamp) async -> [ManualActivityBlock]
}

struct ManualActivityService: ManualActivityManaging {
    let repository: ManualActivityRepository

    func save(block: ManualActivityBlock) async -> Bool {
        let existingBlocks = await repository.fetch(day: block.day)
        let overlapsExistingBlock = existingBlocks.contains { existing in
            existing.id != block.id
                && block.startMinuteOfDay < existing.endMinuteOfDay
                && block.endMinuteOfDay > existing.startMinuteOfDay
        }

        guard !overlapsExistingBlock else {
            return false
        }

        await repository.save(block)
        return true
    }

    func delete(blockID: UUID) async {
        await repository.delete(id: blockID)
    }

    func blocks(for day: DayStamp) async -> [ManualActivityBlock] {
        await repository.fetch(day: day)
    }
}
