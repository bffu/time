import Foundation

struct TextOverviewParser: OverviewParsing {
    func parseOverview(from blocks: [OCRTextBlock], imageURL: URL) async -> RecognizedOverview {
        let lines = ScreenTimeTextParsing.lines(from: blocks)
        let namedDurations = ScreenTimeTextParsing.namedDurations(in: lines)

        return RecognizedOverview(
            day: ScreenTimeTextParsing.day(in: lines, imageURL: imageURL),
            totalScreenMinutes: ScreenTimeTextParsing.totalScreenMinutes(in: lines),
            categorySummaries: namedDurations,
            topApps: namedDurations
        )
    }
}

struct TextAppDetailParser: AppDetailParsing {
    func parseAppDetail(from blocks: [OCRTextBlock], imageURL: URL) async -> RecognizedAppDetail {
        let lines = ScreenTimeTextParsing.lines(from: blocks)

        return RecognizedAppDetail(
            day: ScreenTimeTextParsing.day(in: lines, imageURL: imageURL),
            appName: ScreenTimeTextParsing.appName(in: lines, imageURL: imageURL),
            totalMinutes: ScreenTimeTextParsing.appTotalMinutes(in: lines),
            averageDailyMinutes: ScreenTimeTextParsing.averageDailyMinutes(in: lines),
            notificationCount: ScreenTimeTextParsing.notificationCount(in: lines),
            hourlyUsage: []
        )
    }
}

enum ScreenTimeTextParsing {
    static func lines(from blocks: [OCRTextBlock]) -> [String] {
        blocks
            .sorted {
                let yDistance = abs($0.normalizedBoundingBox.y - $1.normalizedBoundingBox.y)
                if yDistance > 0.018 {
                    return $0.normalizedBoundingBox.y > $1.normalizedBoundingBox.y
                }
                return $0.normalizedBoundingBox.x < $1.normalizedBoundingBox.x
            }
            .map { clean($0.text) }
            .filter { !$0.isEmpty }
    }

    static func day(in lines: [String], imageURL: URL) -> DayStamp? {
        let searchText = ([imageURL.deletingPathExtension().lastPathComponent] + lines).joined(separator: " ")
        let normalized = clean(searchText).lowercased()

        if normalized.contains("今天") || normalized.contains("today") {
            return DayStamp(date: .now)
        }
        if normalized.contains("昨天") || normalized.contains("yesterday") {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
            return DayStamp(date: yesterday)
        }

        if let match = firstMatch(#"(\d{4})[年\-/._ ]+(\d{1,2})[月\-/._ ]+(\d{1,2})"#, in: normalized),
           let year = intGroup(match, 1, in: normalized),
           let month = intGroup(match, 2, in: normalized),
           let day = intGroup(match, 3, in: normalized) {
            return DayStamp(year: year, month: month, day: day)
        }

        if let match = firstMatch(#"(\d{4})(\d{2})(\d{2})"#, in: normalized),
           let year = intGroup(match, 1, in: normalized),
           let month = intGroup(match, 2, in: normalized),
           let day = intGroup(match, 3, in: normalized) {
            return DayStamp(year: year, month: month, day: day)
        }

        if let match = firstMatch(#"(\d{1,2})\s*月\s*(\d{1,2})\s*日"#, in: normalized),
           let month = intGroup(match, 1, in: normalized),
           let day = intGroup(match, 2, in: normalized) {
            return DayStamp(year: Calendar.current.component(.year, from: .now), month: month, day: day)
        }

        if let englishDate = englishMonthDate(in: normalized) {
            return englishDate
        }

        return nil
    }

    static func totalScreenMinutes(in lines: [String]) -> Int? {
        let prioritized = lines.enumerated().compactMap { index, line -> (priority: Int, minutes: Int)? in
            guard let minutes = durationMinutes(in: line) else {
                return nil
            }

            let nearby = nearbyText(lines: lines, index: index).lowercased()
            if nearby.contains("屏幕使用时间") || nearby.contains("screen time") {
                return (0, minutes)
            }
            if nearby.contains("总") || nearby.contains("total") {
                return (1, minutes)
            }
            return (2, minutes)
        }

        return prioritized
            .sorted {
                if $0.priority == $1.priority {
                    return $0.minutes > $1.minutes
                }
                return $0.priority < $1.priority
            }
            .first?
            .minutes
    }

    static func appTotalMinutes(in lines: [String]) -> Int? {
        let durations = lines.compactMap { durationMinutes(in: $0) }
        return durations.max()
    }

    static func averageDailyMinutes(in lines: [String]) -> Int? {
        for (index, line) in lines.enumerated() {
            let nearby = nearbyText(lines: lines, index: index).lowercased()
            guard nearby.contains("日均") || nearby.contains("每日平均") || nearby.contains("daily average") || nearby.contains("average") else {
                continue
            }
            if let minutes = durationMinutes(in: line) {
                return minutes
            }
            if index + 1 < lines.count, let minutes = durationMinutes(in: lines[index + 1]) {
                return minutes
            }
        }
        return nil
    }

    static func notificationCount(in lines: [String]) -> Int? {
        for (index, line) in lines.enumerated() {
            let nearby = nearbyText(lines: lines, index: index).lowercased()
            guard nearby.contains("通知") || nearby.contains("notification") else {
                continue
            }
            if let value = firstInteger(in: line) {
                return value
            }
            if index > 0, let value = firstInteger(in: lines[index - 1]) {
                return value
            }
            if index + 1 < lines.count, let value = firstInteger(in: lines[index + 1]) {
                return value
            }
        }
        return nil
    }

    static func namedDurations(in lines: [String]) -> [String: Int] {
        var result: [String: Int] = [:]

        for (index, line) in lines.enumerated() {
            guard let minutes = durationMinutes(in: line), minutes > 0 else {
                continue
            }

            let name = nameBesideDuration(in: line) ?? nearbyName(lines: lines, before: index)
            guard let name, !isSectionOrMetricName(name) else {
                continue
            }

            result[name, default: 0] += minutes
        }

        return result
    }

    static func appName(in lines: [String], imageURL: URL) -> String? {
        for line in lines.prefix(8) {
            let candidate = candidateTitle(from: line)
            if let candidate, !isSectionOrMetricName(candidate) {
                return candidate
            }
        }

        for line in lines {
            let candidate = nameBesideDuration(in: line)
            if let candidate, !isSectionOrMetricName(candidate) {
                return candidate
            }
        }

        return appNameFromFileName(imageURL.deletingPathExtension().lastPathComponent)
    }

    private static func candidateTitle(from line: String) -> String? {
        guard durationMinutes(in: line) == nil,
              firstInteger(in: line) == nil,
              day(in: [line], imageURL: URL(fileURLWithPath: "")) == nil else {
            return nil
        }

        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (2...28).contains(trimmed.count) else {
            return nil
        }
        return trimmed
    }

    private static func nameBesideDuration(in line: String) -> String? {
        var stripped = replaceMatches(#"(\d+(?:[.,]\d+)?)\s*(?:小时|小時|hr|hrs|hour|hours|h)\s*(?:(\d+)\s*(?:分钟|分鐘|分|min|mins|m))?"#, in: line, with: "")
        stripped = replaceMatches(#"(\d+)\s*(?:分钟|分鐘|分|min|mins|m)"#, in: stripped, with: "")
        stripped = replaceMatches(#"\b\d{1,2}:[0-5]\d\b"#, in: stripped, with: "")
        stripped = stripped
            .replacingOccurrences(of: "：", with: "")
            .replacingOccurrences(of: ":", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard (2...28).contains(stripped.count) else {
            return nil
        }
        return stripped
    }

    private static func nearbyName(lines: [String], before index: Int) -> String? {
        guard index > 0 else {
            return nil
        }

        for candidateIndex in stride(from: index - 1, through: max(0, index - 2), by: -1) {
            if let title = candidateTitle(from: lines[candidateIndex]), !isSectionOrMetricName(title) {
                return title
            }
        }
        return nil
    }

    private static func durationMinutes(in text: String) -> Int? {
        let normalized = clean(text).lowercased()

        if let match = firstMatch(#"(\d+(?:[.,]\d+)?)\s*(?:小时|小時|hr|hrs|hour|hours|h)\s*(?:(\d+)\s*(?:分钟|分鐘|分|min|mins|m))?"#, in: normalized),
           let hourText = stringGroup(match, 1, in: normalized) {
            let hours = Double(hourText.replacingOccurrences(of: ",", with: ".")) ?? 0
            let minutes = intGroup(match, 2, in: normalized) ?? 0
            return Int((hours * 60).rounded()) + minutes
        }

        if let match = firstMatch(#"(\d+)\s*(?:分钟|分鐘|分|min|mins|m)"#, in: normalized),
           let minutes = intGroup(match, 1, in: normalized) {
            return minutes
        }

        if let match = firstMatch(#"\b(\d{1,2}):([0-5]\d)\b"#, in: normalized),
           let hours = intGroup(match, 1, in: normalized),
           let minutes = intGroup(match, 2, in: normalized) {
            return hours * 60 + minutes
        }

        return nil
    }

    private static func englishMonthDate(in text: String) -> DayStamp? {
        let pattern = #"(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\s+(\d{1,2})(?:,\s*(\d{4}))?"#
        guard let match = firstMatch(pattern, in: text, options: [.caseInsensitive]),
              let monthName = stringGroup(match, 1, in: text)?.prefix(3).lowercased(),
              let day = intGroup(match, 2, in: text) else {
            return nil
        }

        let months = [
            "jan": 1,
            "feb": 2,
            "mar": 3,
            "apr": 4,
            "may": 5,
            "jun": 6,
            "jul": 7,
            "aug": 8,
            "sep": 9,
            "oct": 10,
            "nov": 11,
            "dec": 12
        ]
        let year = intGroup(match, 3, in: text) ?? Calendar.current.component(.year, from: .now)
        guard let month = months[String(monthName)] else {
            return nil
        }
        return DayStamp(year: year, month: month, day: day)
    }

    private static func appNameFromFileName(_ fileName: String) -> String? {
        let ignored = Set(["app", "detail", "overview", "screen", "time", "import", "screenshot", "img", "image", "png", "jpg", "jpeg"])
        let parts = fileName
            .replacingOccurrences(of: "_", with: "-")
            .replacingOccurrences(of: " ", with: "-")
            .split(separator: "-")
            .map(String.init)
            .filter { part in
                let lower = part.lowercased()
                return !ignored.contains(lower) && firstInteger(in: lower) == nil
            }

        guard !parts.isEmpty else {
            return nil
        }
        return parts.joined(separator: " ")
    }

    private static func isSectionOrMetricName(_ text: String) -> Bool {
        let lower = text.lowercased()
        let blocked = [
            "屏幕使用时间",
            "最常使用",
            "总计",
            "类别",
            "通知",
            "日均",
            "每日平均",
            "拿起次数",
            "screen time",
            "most used",
            "categories",
            "notifications",
            "daily average",
            "average",
            "pickups",
            "total"
        ]
        return blocked.contains { lower.contains($0) }
    }

    private static func nearbyText(lines: [String], index: Int) -> String {
        let lower = max(0, index - 1)
        let upper = min(lines.count - 1, index + 1)
        return lines[lower...upper].joined(separator: " ")
    }

    private static func clean(_ text: String) -> String {
        let widthNormalized = text.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? text
        return widthNormalized
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func firstInteger(in text: String) -> Int? {
        guard let match = firstMatch(#"\d+"#, in: text),
              let number = stringGroup(match, 0, in: text) else {
            return nil
        }
        return Int(number)
    }

    private static func firstMatch(
        _ pattern: String,
        in text: String,
        options: NSRegularExpression.Options = []
    ) -> NSTextCheckingResult? {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: options) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return expression.firstMatch(in: text, options: [], range: range)
    }

    private static func replaceMatches(_ pattern: String, in text: String, with replacement: String) -> String {
        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return text
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return expression.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: replacement)
    }

    private static func intGroup(_ match: NSTextCheckingResult, _ index: Int, in text: String) -> Int? {
        guard let group = stringGroup(match, index, in: text) else {
            return nil
        }
        return Int(group)
    }

    private static func stringGroup(_ match: NSTextCheckingResult, _ index: Int, in text: String) -> String? {
        guard index < match.numberOfRanges else {
            return nil
        }

        let range = match.range(at: index)
        guard range.location != NSNotFound, let stringRange = Range(range, in: text) else {
            return nil
        }
        return String(text[stringRange])
    }
}
