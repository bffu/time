import XCTest
@testable import TimeApp

final class ReconciliationEngineTests: XCTestCase {
    func testConsolidatesDuplicateAppDetailsAndNormalizesHourlyOverflow() async throws {
        let day = DayStamp(year: 2026, month: 4, day: 9)
        let envelope = RecognitionEnvelope(
            screenshots: [],
            overview: RecognizedOverview(
                day: day,
                totalScreenMinutes: 100,
                categorySummaries: [:],
                topApps: [:]
            ),
            appDetails: [
                RecognizedAppDetail(
                    day: day,
                    appName: "Chat",
                    totalMinutes: 70,
                    averageDailyMinutes: nil,
                    notificationCount: nil,
                    hourlyUsage: [HourSlot(hour: 10, minutes: 60)]
                ),
                RecognizedAppDetail(
                    day: day,
                    appName: "Chat",
                    totalMinutes: 45,
                    averageDailyMinutes: nil,
                    notificationCount: nil,
                    hourlyUsage: [HourSlot(hour: 10, minutes: 45)]
                ),
                RecognizedAppDetail(
                    day: day,
                    appName: "Video",
                    totalMinutes: 50,
                    averageDailyMinutes: nil,
                    notificationCount: nil,
                    hourlyUsage: [HourSlot(hour: 10, minutes: 50)]
                )
            ]
        )

        let output = await DefaultReconciliationEngine().reconcile(envelope, manualBlocks: [])

        let unwrapped = try XCTUnwrap(output)
        XCTAssertEqual(unwrapped.dailyUsages.map(\.appName).sorted(), ["Chat", "Video"])
        XCTAssertEqual(unwrapped.hourlyUsages.filter { $0.hour == 10 }.reduce(0) { $0 + $1.minutes }, 60)
        XCTAssertTrue(unwrapped.warnings.contains { $0.contains("超过 60 分钟") })
        XCTAssertTrue(unwrapped.warnings.contains { $0.contains("超过总览时长") })
    }
}
