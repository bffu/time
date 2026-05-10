import XCTest
@testable import TimeApp

final class RecognitionClassifierTests: XCTestCase {
    func testOverviewAnchorsWinWhenDailyAverageAlsoAppears() async {
        let blocks = [
            block("屏幕使用时间"),
            block("每日平均"),
            block("最常使用"),
            block("类别")
        ]

        let result = await RuleBasedScreenshotClassifier().classify(blocks: blocks)

        XCTAssertEqual(result.kind, .overview)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.55)
    }

    func testAppDetailRecognizesNotificationSignals() async {
        let blocks = [
            block("Chat"),
            block("通知"),
            block("日均")
        ]

        let result = await RuleBasedScreenshotClassifier().classify(blocks: blocks)

        XCTAssertEqual(result.kind, .appDetail)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.55)
    }

    private func block(_ text: String) -> OCRTextBlock {
        OCRTextBlock(
            text: text,
            normalizedBoundingBox: CGRectPayload(x: 0, y: 0, width: 1, height: 0.1),
            confidence: 0.9
        )
    }
}
