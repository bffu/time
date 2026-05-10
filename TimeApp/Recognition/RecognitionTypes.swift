import Foundation

struct OCRTextBlock: Codable, Hashable, Sendable, Identifiable {
    let id: UUID
    var text: String
    var normalizedBoundingBox: CGRectPayload
    var confidence: Double

    init(
        id: UUID = UUID(),
        text: String,
        normalizedBoundingBox: CGRectPayload,
        confidence: Double
    ) {
        self.id = id
        self.text = text
        self.normalizedBoundingBox = normalizedBoundingBox
        self.confidence = confidence
    }
}

struct CGRectPayload: Codable, Hashable, Sendable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}

struct ClassifiedScreenshot: Codable, Hashable, Sendable {
    var kind: ScreenshotKind
    var confidence: Double
}

struct RecognizedOverview: Codable, Hashable, Sendable {
    var day: DayStamp?
    var totalScreenMinutes: Int?
    var categorySummaries: [String: Int]
    var topApps: [String: Int]
}

struct RecognizedAppDetail: Codable, Hashable, Sendable {
    var day: DayStamp?
    var appName: String?
    var totalMinutes: Int?
    var averageDailyMinutes: Int?
    var notificationCount: Int?
    var hourlyUsage: [HourSlot]
}

protocol ImageTextRecognizing: Sendable {
    func recognizeTextBlocks(from imageURL: URL) async throws -> [OCRTextBlock]
}

protocol ScreenshotClassifying: Sendable {
    func classify(blocks: [OCRTextBlock]) async -> ClassifiedScreenshot
}

protocol OverviewParsing: Sendable {
    func parseOverview(from blocks: [OCRTextBlock], imageURL: URL) async -> RecognizedOverview
}

protocol AppDetailParsing: Sendable {
    func parseAppDetail(from blocks: [OCRTextBlock], imageURL: URL) async -> RecognizedAppDetail
}

protocol HourlyChartParsing: Sendable {
    func parseHourlyUsage(from imageURL: URL, kind: ScreenshotKind) async -> [HourSlot]
}

struct RuleBasedScreenshotClassifier: ScreenshotClassifying {
    func classify(blocks: [OCRTextBlock]) async -> ClassifiedScreenshot {
        let joinedText = blocks.map(\.text).joined(separator: " ")
        let normalized = joinedText.lowercased()
        let overviewSignals = [
            ("最常使用", 3),
            ("类别", 2),
            ("拿起次数", 2),
            ("每天", 1),
            ("屏幕使用时间", 1),
            ("most used", 3),
            ("categories", 2),
            ("pickups", 2),
            ("screen time", 1)
        ]
        let appDetailSignals = [
            ("通知", 3),
            ("限额", 2),
            ("日均", 1),
            ("每日平均", 1),
            ("notifications", 3),
            ("limits", 2),
            ("daily average", 1)
        ]

        let overviewScore = overviewSignals.reduce(0) { score, signal in
            normalized.contains(signal.0.lowercased()) ? score + signal.1 : score
        }
        let detailScore = appDetailSignals.reduce(0) { score, signal in
            normalized.contains(signal.0.lowercased()) ? score + signal.1 : score
        }

        if overviewScore >= 2, overviewScore >= detailScore {
            return ClassifiedScreenshot(kind: .overview, confidence: min(0.92, 0.58 + Double(overviewScore) * 0.05))
        }
        if detailScore > 0 {
            return ClassifiedScreenshot(kind: .appDetail, confidence: min(0.92, 0.58 + Double(detailScore) * 0.06))
        }
        if overviewScore > 0 {
            return ClassifiedScreenshot(kind: .overview, confidence: min(0.7, 0.55 + Double(overviewScore) * 0.04))
        }
        return fallback(for: joinedText)
    }

    private func fallback(for joinedText: String) -> ClassifiedScreenshot {
        let normalized = joinedText.lowercased()
        if let importIndex = importIndex(in: normalized) {
            let kind: ScreenshotKind = importIndex == 1 ? .overview : .appDetail
            return ClassifiedScreenshot(kind: kind, confidence: 0.58)
        }
        if normalized.contains("overview") || normalized.contains("screen time") {
            return ClassifiedScreenshot(kind: .overview, confidence: 0.6)
        }
        if normalized.contains("app") || normalized.contains("detail") || normalized.contains("notification") {
            return ClassifiedScreenshot(kind: .appDetail, confidence: 0.6)
        }

        let hashValue = joinedText.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
        let kind: ScreenshotKind = (hashValue % 2 == 0) ? .overview : .appDetail
        return ClassifiedScreenshot(kind: kind, confidence: 0.45)
    }

    private func importIndex(in normalized: String) -> Int? {
        guard let range = normalized.range(of: #"import[\s-]?(\d+)"#, options: .regularExpression) else {
            return nil
        }

        let matched = String(normalized[range])
        let digits = matched.filter { $0.isNumber }
        return Int(digits)
    }
}
