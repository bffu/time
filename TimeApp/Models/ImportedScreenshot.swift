import Foundation

struct ImportedScreenshot: Codable, Hashable, Sendable, Identifiable {
    let id: UUID
    var fileName: String
    var sourceURL: URL
    var sha256: String?
    var kind: ScreenshotKind
    var capturedDay: DayStamp?
    var recognizedAppName: String?
    var confidence: Double
    var importedAt: Date

    init(
        id: UUID = UUID(),
        fileName: String,
        sourceURL: URL,
        sha256: String? = nil,
        kind: ScreenshotKind = .unknown,
        capturedDay: DayStamp? = nil,
        recognizedAppName: String? = nil,
        confidence: Double = 0,
        importedAt: Date = .now
    ) {
        self.id = id
        self.fileName = fileName
        self.sourceURL = sourceURL
        self.sha256 = sha256
        self.kind = kind
        self.capturedDay = capturedDay
        self.recognizedAppName = recognizedAppName
        self.confidence = confidence
        self.importedAt = importedAt
    }
}

