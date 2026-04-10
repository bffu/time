import Foundation

protocol Importing: Sendable {
    func createBatch(from imageURLs: [URL]) async -> ImportBatch
}

struct ImportService: Importing {
    func createBatch(from imageURLs: [URL]) async -> ImportBatch {
        let screenshots = imageURLs.map { url in
            ImportedScreenshot(
                fileName: url.lastPathComponent,
                sourceURL: url
            )
        }

        return ImportBatch(screenshots: screenshots, status: .draft)
    }
}

