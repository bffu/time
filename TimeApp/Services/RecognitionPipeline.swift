import Foundation

protocol RecognitionProcessing: Sendable {
    func process(batch: ImportBatch) async -> RecognitionEnvelope
}

struct RecognitionPipeline: RecognitionProcessing {
    let ocrService: ImageTextRecognizing
    let classifier: ScreenshotClassifying
    let overviewParser: OverviewParsing
    let appDetailParser: AppDetailParsing
    let chartParser: HourlyChartParsing

    func process(batch: ImportBatch) async -> RecognitionEnvelope {
        var screenshots: [ImportedScreenshot] = []
        var overview: RecognizedOverview?
        var appDetails: [RecognizedAppDetail] = []

        for screenshot in batch.screenshots {
            let blocks = (try? await ocrService.recognizeTextBlocks(from: screenshot.sourceURL)) ?? []
            let classified = await classifier.classify(blocks: blocks)

            var updated = screenshot
            updated.kind = classified.kind
            updated.confidence = classified.confidence

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
                    parsed.hourlyUsage = hourlyUsage
                    parsed.totalMinutes = hourlyUsage.reduce(0) { $0 + $1.minutes }
                }
                updated.capturedDay = parsed.day
                updated.recognizedAppName = parsed.appName
                appDetails.append(parsed)
            case .unknown:
                break
            }

            screenshots.append(updated)
        }

        return RecognitionEnvelope(screenshots: screenshots, overview: overview, appDetails: appDetails)
    }
}

