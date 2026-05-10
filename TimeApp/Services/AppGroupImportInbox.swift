import Foundation

protocol SharedImportInboxReading: Sendable {
    func takePendingImageBatches() async -> [[URL]]
}

struct AppGroupImportInbox: SharedImportInboxReading {
    private let appGroupIdentifier = "group.com.example.TimeApp"
    private let incomingFolderName = "IncomingShares"
    private let manifestFileName = "manifest.json"
    private let processedManifestFileName = "manifest.processed.json"

    func takePendingImageBatches() async -> [[URL]] {
        await Task.detached(priority: .utility) {
            let fileManager = FileManager.default
            guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
                return [[URL]]()
            }

            let incomingURL = containerURL.appendingPathComponent(incomingFolderName, isDirectory: true)
            guard let batchDirectories = try? fileManager.contentsOfDirectory(
                at: incomingURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else {
                return [[URL]]()
            }

            var pendingBatches: [[URL]] = []
            for batchDirectory in batchDirectories {
                guard isDirectory(batchDirectory, fileManager: fileManager) else {
                    continue
                }

                let manifestURL = batchDirectory.appendingPathComponent(manifestFileName)
                guard fileManager.fileExists(atPath: manifestURL.path),
                      let data = try? Data(contentsOf: manifestURL),
                      let manifest = try? JSONDecoder.shareExtensionManifestDecoder.decode(ShareExtensionImportManifest.self, from: data) else {
                    continue
                }

                let imageURLs = manifest.imageFileNames
                    .map { batchDirectory.appendingPathComponent($0) }
                    .filter { fileManager.fileExists(atPath: $0.path) }

                guard !imageURLs.isEmpty else {
                    continue
                }

                pendingBatches.append(imageURLs)
                markManifestConsumed(at: manifestURL, in: batchDirectory, fileManager: fileManager)
            }

            return pendingBatches
        }.value
    }

    private func isDirectory(_ url: URL, fileManager: FileManager) -> Bool {
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
        return values?.isDirectory == true
    }

    private func markManifestConsumed(at manifestURL: URL, in batchDirectory: URL, fileManager: FileManager) {
        let processedURL = batchDirectory.appendingPathComponent(processedManifestFileName)
        if fileManager.fileExists(atPath: processedURL.path) {
            try? fileManager.removeItem(at: processedURL)
        }
        try? fileManager.moveItem(at: manifestURL, to: processedURL)
    }
}

private struct ShareExtensionImportManifest: Codable {
    var id: UUID
    var createdAt: Date
    var imageFileNames: [String]
}

private extension JSONDecoder {
    static var shareExtensionManifestDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
