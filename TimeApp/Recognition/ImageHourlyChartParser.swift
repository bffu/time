import Foundation
import UIKit

struct ImageHourlyChartParser: HourlyChartParsing {
    func parseHourlyUsage(from imageURL: URL, kind: ScreenshotKind) async -> [HourSlot] {
        guard kind != .unknown else {
            return []
        }

        return await Task.detached(priority: .utility) {
            guard let buffer = PixelBuffer(imageURL: imageURL) else {
                return [HourSlot]()
            }
            return Self.parseHourlyBars(in: buffer)
        }.value
    }

    private static func parseHourlyBars(in buffer: PixelBuffer) -> [HourSlot] {
        guard let band = strongestColorBand(in: buffer) else {
            return []
        }

        let chartXRange = horizontalChartRange(in: buffer, yRange: band)
        let slotWidth = max(1, (chartXRange.upperBound - chartXRange.lowerBound + 1) / 24)
        var rawHeights: [(hour: Int, height: Int)] = []

        for hour in 0..<24 {
            let slotStart = chartXRange.lowerBound + hour * slotWidth
            let slotEnd = hour == 23 ? chartXRange.upperBound : min(chartXRange.upperBound, slotStart + slotWidth - 1)
            var minY = Int.max
            var maxY = Int.min
            var hitCount = 0

            for x in slotStart...slotEnd {
                for y in band.lowerBound...band.upperBound where buffer.isScreenTimeChartPixel(x: x, y: y) {
                    minY = min(minY, y)
                    maxY = max(maxY, y)
                    hitCount += 1
                }
            }

            let minimumHits = max(3, slotWidth)
            guard hitCount >= minimumHits, minY <= maxY else {
                continue
            }
            rawHeights.append((hour, maxY - minY + 1))
        }

        guard let maxHeight = rawHeights.map(\.height).max(), maxHeight > 4 else {
            return []
        }

        return rawHeights.compactMap { item in
            let minutes = Int((Double(item.height) / Double(maxHeight) * 60.0).rounded())
            guard minutes > 0 else {
                return nil
            }
            return HourSlot(hour: item.hour, minutes: minutes)
        }
    }

    private static func strongestColorBand(in buffer: PixelBuffer) -> ClosedRange<Int>? {
        let yStart = Int(Double(buffer.height) * 0.12)
        let yEnd = Int(Double(buffer.height) * 0.78)
        let xStart = Int(Double(buffer.width) * 0.06)
        let xEnd = Int(Double(buffer.width) * 0.94)
        let threshold = max(4, Int(Double(xEnd - xStart) * 0.012))

        var currentStart: Int?
        var currentScore = 0
        var bestScore = 0
        var bestRange: ClosedRange<Int>?

        for y in yStart...yEnd {
            var rowScore = 0
            for x in xStart...xEnd where buffer.isScreenTimeChartPixel(x: x, y: y) {
                rowScore += 1
            }

            if rowScore >= threshold {
                if currentStart == nil {
                    currentStart = y
                }
                currentScore += rowScore
            } else if let start = currentStart {
                let range = start...max(start, y - 1)
                if isPlausibleBand(range, in: buffer), currentScore > bestScore {
                    bestScore = currentScore
                    bestRange = range
                }
                currentStart = nil
                currentScore = 0
            }
        }

        if let start = currentStart {
            let range = start...yEnd
            if isPlausibleBand(range, in: buffer), currentScore > bestScore {
                bestRange = range
            }
        }

        guard let range = bestRange else {
            return nil
        }

        let expandedStart = max(0, range.lowerBound - 8)
        let expandedEnd = min(buffer.height - 1, range.upperBound + 8)
        return expandedStart...expandedEnd
    }

    private static func isPlausibleBand(_ range: ClosedRange<Int>, in buffer: PixelBuffer) -> Bool {
        let height = range.upperBound - range.lowerBound + 1
        return height >= max(18, buffer.height / 48) && height <= max(32, buffer.height / 3)
    }

    private static func horizontalChartRange(in buffer: PixelBuffer, yRange: ClosedRange<Int>) -> ClosedRange<Int> {
        let xStart = Int(Double(buffer.width) * 0.06)
        let xEnd = Int(Double(buffer.width) * 0.94)
        let threshold = max(2, (yRange.upperBound - yRange.lowerBound + 1) / 14)
        var candidates: [Int] = []

        for x in xStart...xEnd {
            var score = 0
            for y in yRange where buffer.isScreenTimeChartPixel(x: x, y: y) {
                score += 1
            }
            if score >= threshold {
                candidates.append(x)
            }
        }

        guard let minX = candidates.min(),
              let maxX = candidates.max(),
              maxX - minX > buffer.width / 2 else {
            return xStart...xEnd
        }

        return max(xStart, minX - 12)...min(xEnd, maxX + 12)
    }
}

private struct PixelBuffer {
    let width: Int
    let height: Int
    private let data: [UInt8]
    private static let bytesPerPixel = 4

    init?(imageURL: URL, maxDimension: Int = 900) {
        guard let cgImage = UIImage(contentsOfFile: imageURL.path)?.cgImage else {
            return nil
        }

        let scale = min(1.0, Double(maxDimension) / Double(max(cgImage.width, cgImage.height)))
        width = max(1, Int(Double(cgImage.width) * scale))
        height = max(1, Int(Double(cgImage.height) * scale))

        var pixelData = [UInt8](repeating: 0, count: width * height * Self.bytesPerPixel)
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * Self.bytesPerPixel,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        data = pixelData
    }

    func isScreenTimeChartPixel(x: Int, y: Int) -> Bool {
        guard x >= 0, x < width, y >= 0, y < height else {
            return false
        }

        let offset = (y * width + x) * Self.bytesPerPixel
        let red = Double(data[offset])
        let green = Double(data[offset + 1])
        let blue = Double(data[offset + 2])
        let alpha = Double(data[offset + 3])
        guard alpha > 180 else {
            return false
        }

        let maximum = max(red, green, blue)
        let minimum = min(red, green, blue)
        guard maximum > 70 else {
            return false
        }

        let saturation = maximum == 0 ? 0 : (maximum - minimum) / maximum
        guard saturation > 0.22 else {
            return false
        }

        let blueLike = blue > red + 18 && blue >= green * 0.72
        let cyanLike = green > red + 18 && blue > red + 18
        let purpleLike = blue > green + 6 && red > green + 8
        return blueLike || cyanLike || purpleLike
    }
}
