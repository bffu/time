import XCTest
@testable import TimeApp

final class ScreenTimeTextParsingTests: XCTestCase {
    func testParsesDateFromFileName() {
        let url = URL(fileURLWithPath: "/tmp/screen-time-2026-04-09.png")

        let day = ScreenTimeTextParsing.day(in: [], imageURL: url)

        XCTAssertEqual(day, DayStamp(year: 2026, month: 4, day: 9))
    }

    func testParsesScreenTimeDurationNearLabel() {
        let minutes = ScreenTimeTextParsing.totalScreenMinutes(in: [
            "Screen Time",
            "6 hr 27 min"
        ])

        XCTAssertEqual(minutes, 387)
    }

    func testExtractsNamedDurations() {
        let durations = ScreenTimeTextParsing.namedDurations(in: [
            "TikTok 2 hr 15 min",
            "Messages 31 min",
            "Screen Time 6 hr 27 min"
        ])

        XCTAssertEqual(durations["TikTok"], 135)
        XCTAssertEqual(durations["Messages"], 31)
        XCTAssertNil(durations["Screen Time"])
    }
}
