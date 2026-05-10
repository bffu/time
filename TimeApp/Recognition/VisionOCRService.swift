import Foundation
import Vision

struct VisionOCRService: ImageTextRecognizing {
    func recognizeTextBlocks(from imageURL: URL) async throws -> [OCRTextBlock] {
        try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]

            let handler = VNImageRequestHandler(url: imageURL, options: [:])
            try handler.perform([request])

            return (request.results ?? []).compactMap { observation in
                guard let candidate = observation.topCandidates(1).first else {
                    return nil
                }

                let rect = observation.boundingBox
                return OCRTextBlock(
                    text: candidate.string,
                    normalizedBoundingBox: CGRectPayload(
                        x: Double(rect.origin.x),
                        y: Double(rect.origin.y),
                        width: Double(rect.width),
                        height: Double(rect.height)
                    ),
                    confidence: Double(candidate.confidence)
                )
            }
        }.value
    }
}
