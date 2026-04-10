import Foundation

struct ImportBatch: Codable, Hashable, Sendable, Identifiable {
    let id: UUID
    var createdAt: Date
    var screenshots: [ImportedScreenshot]
    var candidateDay: DayStamp?
    var status: ImportBatchStatus
    var warningMessages: [String]
    var errorMessage: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        screenshots: [ImportedScreenshot],
        candidateDay: DayStamp? = nil,
        status: ImportBatchStatus = .draft,
        warningMessages: [String] = [],
        errorMessage: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.screenshots = screenshots
        self.candidateDay = candidateDay
        self.status = status
        self.warningMessages = warningMessages
        self.errorMessage = errorMessage
    }
}

