import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let appGroupIdentifier = "group.com.example.TimeApp"
    private let incomingFolderName = "IncomingShares"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        handleSharedImages()
    }

    private func handleSharedImages() {
        guard let inputItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            completeRequest()
            return
        }

        let providers = inputItems
            .flatMap { $0.attachments ?? [] }
            .filter { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }

        if providers.isEmpty {
            completeRequest()
            return
        }

        persistSharedImages(from: providers) { [weak self] in
            self?.completeRequest()
        }
    }

    private func persistSharedImages(from providers: [NSItemProvider], completion: @escaping () -> Void) {
        let fileManager = FileManager.default
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            completion()
            return
        }

        let batchID = UUID()
        let batchDirectory = containerURL
            .appendingPathComponent(incomingFolderName, isDirectory: true)
            .appendingPathComponent(batchID.uuidString, isDirectory: true)

        do {
            try fileManager.createDirectory(at: batchDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            completion()
            return
        }

        let group = DispatchGroup()
        let lock = NSLock()
        var nextIndex = 0
        var fileNames: [String] = []

        for provider in providers {
            group.enter()
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                defer { group.leave() }
                guard let data else { return }

                lock.lock()
                nextIndex += 1
                let index = nextIndex
                lock.unlock()

                let fileName = "shared-\(index).\(self.preferredFileExtension(for: provider))"
                let fileURL = batchDirectory.appendingPathComponent(fileName)

                do {
                    try data.write(to: fileURL, options: [.atomic])
                    lock.lock()
                    fileNames.append(fileName)
                    lock.unlock()
                } catch {
                    try? fileManager.removeItem(at: fileURL)
                }
            }
        }

        group.notify(queue: .main) {
            guard !fileNames.isEmpty else {
                try? fileManager.removeItem(at: batchDirectory)
                completion()
                return
            }

            let manifest = ShareExtensionImportManifest(
                id: batchID,
                createdAt: .now,
                imageFileNames: fileNames.sorted()
            )

            do {
                let data = try JSONEncoder.shareExtensionManifestEncoder.encode(manifest)
                let manifestURL = batchDirectory.appendingPathComponent("manifest.json")
                try data.write(to: manifestURL, options: [.atomic])
            } catch {
                try? fileManager.removeItem(at: batchDirectory)
            }

            completion()
        }
    }

    private func preferredFileExtension(for provider: NSItemProvider) -> String {
        provider.registeredTypeIdentifiers
            .compactMap { UTType($0) }
            .first { $0.conforms(to: .image) }?
            .preferredFilenameExtension ?? "jpg"
    }

    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}

private struct ShareExtensionImportManifest: Codable {
    var id: UUID
    var createdAt: Date
    var imageFileNames: [String]
}

private extension JSONEncoder {
    static var shareExtensionManifestEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
