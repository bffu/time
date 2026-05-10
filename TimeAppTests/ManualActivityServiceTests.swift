import XCTest
@testable import TimeApp

final class ManualActivityServiceTests: XCTestCase {
    func testRejectsOverlappingManualBlocks() async {
        let repository = InMemoryManualActivityRepository()
        let service = ManualActivityService(repository: repository)
        let day = DayStamp(year: 2026, month: 4, day: 9)

        let first = ManualActivityBlock(
            day: day,
            title: "Work",
            startMinuteOfDay: 9 * 60,
            endMinuteOfDay: 10 * 60
        )
        let overlapping = ManualActivityBlock(
            day: day,
            title: "Commute",
            startMinuteOfDay: 9 * 60 + 30,
            endMinuteOfDay: 10 * 60 + 30
        )

        XCTAssertTrue(await service.save(block: first))
        XCTAssertFalse(await service.save(block: overlapping))
        XCTAssertEqual(await service.blocks(for: day).count, 1)
    }
}
