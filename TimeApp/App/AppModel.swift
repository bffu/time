import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedDay = DayStamp(date: .now)
    @Published var dayRecord: DayRecord?
    @Published var dailyUsages: [AppUsageDaily] = []
    @Published var hourlyUsages: [AppUsageHourly] = []
    @Published var manualBlocks: [ManualActivityBlock] = []
    @Published var timeline: DayTimeline?
    @Published var importBatches: [ImportBatch] = []
    @Published var reportRange: ReportRange = .week
    @Published var reportSnapshot = ReportSnapshot(range: .week, daySummaries: [], appTrends: [:])
    @Published var isBootstrapping = false

    private let container: AppContainer
    private var hasBootstrapped = false

    init(container: AppContainer) {
        self.container = container
    }

    func bootstrapIfNeeded() async {
        guard !hasBootstrapped else { return }
        hasBootstrapped = true
        isBootstrapping = true

        await container.bootstrapCoordinator.seedPreviewDataIfNeeded()
        await refreshImportBatches()
        await refreshSelectedDay()
        await refreshReports()

        isBootstrapping = false
    }

    func refreshSelectedDay() async {
        if let snapshot = await container.daySnapshotService.snapshot(for: selectedDay) {
            dayRecord = snapshot.dayRecord
            dailyUsages = snapshot.dailyUsages.sorted { $0.totalMinutes > $1.totalMinutes }
            hourlyUsages = snapshot.hourlyUsages.sorted {
                if $0.hour == $1.hour {
                    return $0.appName < $1.appName
                }
                return $0.hour < $1.hour
            }
            manualBlocks = snapshot.manualBlocks.sorted { $0.startMinuteOfDay < $1.startMinuteOfDay }
            timeline = await container.timelineService.buildTimeline(
                dayRecord: snapshot.dayRecord,
                appUsages: dailyUsages,
                manualBlocks: manualBlocks
            )
        } else {
            dayRecord = nil
            dailyUsages = []
            hourlyUsages = []
            manualBlocks = []
            timeline = nil
        }
    }

    func refreshReports() async {
        reportSnapshot = await container.reportService.snapshot(range: reportRange, endingOn: selectedDay)
    }

    func refreshImportBatches() async {
        importBatches = await container.batchRepository.fetchAll()
    }

    func createSampleImportBatch() async {
        let imageURLs = [
            URL(fileURLWithPath: "/tmp/screen-time-overview-2026-04-09.png"),
            URL(fileURLWithPath: "/tmp/app-detail-douyin-2026-04-09.png"),
            URL(fileURLWithPath: "/tmp/app-detail-wechat-2026-04-09.png")
        ]

        await saveImportBatch(
            from: imageURLs,
            status: .readyForReview,
            candidateDay: selectedDay,
            warningMessages: [
                "样例批次仅用于 UI 骨架预览。",
                "真实版本会在这里接入 Share Extension 和识别流程。"
            ]
        )
    }

    func importPickedImages(from imageURLs: [URL], failedItemCount: Int = 0) async {
        var warnings = ["当前仅完成原图入批，日期和 App 信息尚未识别。"]
        if failedItemCount > 0 {
            warnings.insert("\(failedItemCount) 张图片读取失败，已跳过。", at: 0)
        }

        await saveImportBatch(
            from: imageURLs,
            status: .draft,
            candidateDay: nil,
            warningMessages: warnings
        )
    }

    func addManualBlock(title: String, startHour: Int, endHour: Int) async {
        guard startHour < endHour, let dayRecord else { return }
        let block = ManualActivityBlock(
            day: dayRecord.day,
            title: title,
            startMinuteOfDay: startHour * 60,
            endMinuteOfDay: endHour * 60,
            color: .green
        )
        await container.manualActivityService.save(block: block)
        await refreshSelectedDay()
        await refreshReports()
    }

    func deleteManualBlock(id: UUID) async {
        await container.manualActivityService.delete(blockID: id)
        await refreshSelectedDay()
        await refreshReports()
    }

    func moveDay(by offset: Int) async {
        let calendar = Calendar.current
        let currentDate = calendar.date(from: DateComponents(year: selectedDay.year, month: selectedDay.month, day: selectedDay.day)) ?? .now
        let nextDate = calendar.date(byAdding: .day, value: offset, to: currentDate) ?? currentDate
        selectedDay = DayStamp(date: nextDate)
        await refreshSelectedDay()
        await refreshReports()
    }

    private func saveImportBatch(
        from imageURLs: [URL],
        status: ImportBatchStatus,
        candidateDay: DayStamp?,
        warningMessages: [String]
    ) async {
        guard !imageURLs.isEmpty else { return }

        var batch = await container.importService.createBatch(from: imageURLs)
        batch.status = status
        batch.candidateDay = candidateDay
        batch.warningMessages = warningMessages

        await container.batchRepository.save(batch)
        await refreshImportBatches()
    }
}
