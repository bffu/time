import Foundation

protocol RecognitionProcessing: Sendable {
    func process(batch: ImportBatch) async -> RecognitionEnvelope
}

struct RecognitionPipeline: RecognitionProcessing {
    private static let minimumAcceptedConfidence = 0.55

    let ocrService: ImageTextRecognizing
    let classifier: ScreenshotClassifying
    let overviewParser: OverviewParsing
    let appDetailParser: AppDetailParsing
    let chartParser: HourlyChartParsing

    func process(batch: ImportBatch) async -> RecognitionEnvelope {
        var screenshots: [ImportedScreenshot] = []
        var overview: RecognizedOverview?
        var appDetails: [RecognizedAppDetail] = []
        var warnings: [String] = []

        for screenshot in batch.screenshots {
            let blocks: [OCRTextBlock]
            do {
                blocks = try await ocrService.recognizeTextBlocks(from: screenshot.sourceURL)
            } catch {
                var updated = screenshot
                updated.kind = .unknown
                updated.confidence = 0
                screenshots.append(updated)
                warnings.append("\(screenshot.fileName) OCR 失败：\(error.localizedDescription)")
                continue
            }

            guard !blocks.isEmpty else {
                var updated = screenshot
                updated.kind = .unknown
                updated.confidence = 0
                screenshots.append(updated)
                warnings.append("\(screenshot.fileName) 未识别到文字，已留待复核。")
                continue
            }

            let classified = await classifier.classify(blocks: blocks)

            var updated = screenshot
            updated.kind = classified.kind
            updated.confidence = classified.confidence

            guard classified.confidence >= Self.minimumAcceptedConfidence else {
                updated.kind = .unknown
                screenshots.append(updated)
                warnings.append("\(screenshot.fileName) 分类置信度偏低，已留待复核。")
                continue
            }

            switch classified.kind {
            case .overview:
                let parsedOverview = await overviewParser.parseOverview(from: blocks, imageURL: screenshot.sourceURL)
                let hourlyUsage = await chartParser.parseHourlyUsage(from: screenshot.sourceURL, kind: .overview)
                updated.capturedDay = parsedOverview.day
                overview = RecognizedOverview(
                    day: parsedOverview.day,
                    totalScreenMinutes: parsedOverview.totalScreenMinutes ?? hourlyUsage.reduce(0) { $0 + $1.minutes },
                    categorySummaries: parsedOverview.categorySummaries,
                    topApps: parsedOverview.topApps
                )
            case .appDetail:
                var parsed = await appDetailParser.parseAppDetail(from: blocks, imageURL: screenshot.sourceURL)
                let hourlyUsage = await chartParser.parseHourlyUsage(from: screenshot.sourceURL, kind: .appDetail)
                if !hourlyUsage.isEmpty {
                    parsed.hourlyUsage = Self.scale(hourlyUsage, to: parsed.totalMinutes)
                    parsed.totalMinutes = parsed.totalMinutes ?? parsed.hourlyUsage.reduce(0) { $0 + $1.minutes }
                }
                updated.capturedDay = parsed.day
                updated.recognizedAppName = parsed.appName
                appDetails.append(parsed)
            case .unknown:
                break
            }

            screenshots.append(updated)
        }

        return RecognitionEnvelope(screenshots: screenshots, overview: overview, appDetails: appDetails, warnings: warnings)
    }

    private static func scale(_ slots: [HourSlot], to targetMinutes: Int?) -> [HourSlot] {
        guard let targetMinutes, targetMinutes > 0 else {
            return slots
        }

        let currentTotal = slots.reduce(0) { $0 + $1.minutes }
        guard currentTotal > 0, currentTotal != targetMinutes else {
            return slots
        }

        let minimumMinutes = slots.count > targetMinutes ? 0 : 1
        var scaled = slots.map { slot -> HourSlot in
            let minutes = max(minimumMinutes, min(60, Int((Double(slot.minutes) / Double(currentTotal) * Double(targetMinutes)).rounded())))
            return HourSlot(hour: slot.hour, minutes: minutes)
        }

        var delta = targetMinutes - scaled.reduce(0) { $0 + $1.minutes }
        var index = 0
        while delta != 0, !scaled.isEmpty, index < scaled.count * 4 {
            let slotIndex = index % scaled.count
            let current = scaled[slotIndex]
            if delta > 0, current.minutes < 60 {
                scaled[slotIndex] = HourSlot(hour: current.hour, minutes: current.minutes + 1)
                delta -= 1
            } else if delta < 0, current.minutes > minimumMinutes {
                scaled[slotIndex] = HourSlot(hour: current.hour, minutes: current.minutes - 1)
                delta += 1
            }
            index += 1
        }

        return scaled
    }
}
