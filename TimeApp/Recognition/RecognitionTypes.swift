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

struct PlaceholderOCRService: ImageTextRecognizing {
    func recognizeTextBlocks(from imageURL: URL) async throws -> [OCRTextBlock] {
        let descriptiveName = imageURL.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
        let parentFolder = imageURL.deletingLastPathComponent().lastPathComponent
        let syntheticText = "\(descriptiveName) \(parentFolder)"

        return [
            OCRTextBlock(
                text: syntheticText,
                normalizedBoundingBox: CGRectPayload(x: 0.1, y: 0.1, width: 0.8, height: 0.1),
                confidence: 0.5
            )
        ]
    }
}

struct RuleBasedScreenshotClassifier: ScreenshotClassifying {
    func classify(blocks: [OCRTextBlock]) async -> ClassifiedScreenshot {
        let joinedText = blocks.map(\.text).joined(separator: " ")
        if joinedText.contains("最常使用") || joinedText.contains("每天") {
            return ClassifiedScreenshot(kind: .overview, confidence: 0.7)
        }
        if joinedText.contains("通知") || joinedText.contains("日均") {
            return ClassifiedScreenshot(kind: .appDetail, confidence: 0.7)
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
        return ClassifiedScreenshot(kind: kind, confidence: 0.55)
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

struct PlaceholderOverviewParser: OverviewParsing {
    func parseOverview(from blocks: [OCRTextBlock], imageURL: URL) async -> RecognizedOverview {
        RecognizedOverview(
            day: DayStamp(date: .now),
            totalScreenMinutes: 387,
            categorySummaries: ["创意": 206, "信息与阅读": 32],
            topApps: ["抖音": 206, "微信": 74]
        )
    }
}

struct PlaceholderAppDetailParser: AppDetailParsing {
    func parseAppDetail(from blocks: [OCRTextBlock], imageURL: URL) async -> RecognizedAppDetail {
        let sampleApps = ["抖音", "微信", "哔哩哔哩", "小红书", "Safari", "网易云音乐"]
        let hashValue = imageURL.lastPathComponent.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
        let appName = sampleApps[abs(hashValue) % sampleApps.count]
        let hourlyUsage: [HourSlot] = [
            HourSlot(hour: 0, minutes: 26),
            HourSlot(hour: 1, minutes: 18),
            HourSlot(hour: 2, minutes: 12),
            HourSlot(hour: 12, minutes: 7),
            HourSlot(hour: 18, minutes: 21),
            HourSlot(hour: 19, minutes: 34),
            HourSlot(hour: 20, minutes: 15)
        ]

        return RecognizedAppDetail(
            day: DayStamp(date: .now),
            appName: appName,
            totalMinutes: hourlyUsage.reduce(0) { $0 + $1.minutes },
            averageDailyMinutes: 142,
            notificationCount: 16,
            hourlyUsage: hourlyUsage
        )
    }
}

struct PlaceholderHourlyChartParser: HourlyChartParsing {
    func parseHourlyUsage(from imageURL: URL, kind: ScreenshotKind) async -> [HourSlot] {
        switch kind {
        case .overview:
            return (0..<24).map { hour in
                let minutes = [0, 1, 2, 18, 19, 20].contains(hour) ? [26, 18, 12, 28, 36, 14].randomElement() ?? 10 : 0
                return HourSlot(hour: hour, minutes: minutes)
            }
        case .appDetail:
            return [
                HourSlot(hour: 0, minutes: 26),
                HourSlot(hour: 1, minutes: 18),
                HourSlot(hour: 2, minutes: 12),
                HourSlot(hour: 12, minutes: 7),
                HourSlot(hour: 18, minutes: 21),
                HourSlot(hour: 19, minutes: 34),
                HourSlot(hour: 20, minutes: 15)
            ]
        case .unknown:
            return []
        }
    }
}
