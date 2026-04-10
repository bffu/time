import Foundation

final class AppContainer {
    let dayRepository: DayRecordRepository
    let usageRepository: AppUsageRepository
    let manualRepository: ManualActivityRepository
    let batchRepository: ImportBatchRepository

    let importService: Importing
    let recognitionPipeline: RecognitionProcessing
    let reconciliationEngine: UsageReconciling
    let timelineService: TimelineBuilding
    let manualActivityService: ManualActivityManaging
    let reportService: ReportProviding
    let bootstrapCoordinator: AppBootstrapping
    let daySnapshotService: DaySnapshotProviding

    init(
        dayRepository: DayRecordRepository = InMemoryDayRecordRepository(),
        usageRepository: AppUsageRepository = InMemoryAppUsageRepository(),
        manualRepository: ManualActivityRepository = InMemoryManualActivityRepository(),
        batchRepository: ImportBatchRepository = InMemoryImportBatchRepository(),
        importService: Importing = ImportService(),
        recognitionPipeline: RecognitionProcessing? = nil,
        reconciliationEngine: UsageReconciling = DefaultReconciliationEngine(),
        timelineService: TimelineBuilding? = nil,
        manualActivityService: ManualActivityManaging? = nil,
        reportService: ReportProviding? = nil,
        bootstrapCoordinator: AppBootstrapping? = nil,
        daySnapshotService: DaySnapshotProviding? = nil
    ) {
        self.dayRepository = dayRepository
        self.usageRepository = usageRepository
        self.manualRepository = manualRepository
        self.batchRepository = batchRepository
        self.importService = importService
        self.reconciliationEngine = reconciliationEngine

        let pipeline = recognitionPipeline ?? RecognitionPipeline(
            ocrService: PlaceholderOCRService(),
            classifier: RuleBasedScreenshotClassifier(),
            overviewParser: PlaceholderOverviewParser(),
            appDetailParser: PlaceholderAppDetailParser(),
            chartParser: PlaceholderHourlyChartParser()
        )
        self.recognitionPipeline = pipeline

        let timeline = timelineService ?? TimelineService()
        self.timelineService = timeline

        let manualService = manualActivityService ?? ManualActivityService(repository: manualRepository)
        self.manualActivityService = manualService

        let reports = reportService ?? ReportService(dayRepository: dayRepository, usageRepository: usageRepository)
        self.reportService = reports

        let bootstrap = bootstrapCoordinator ?? AppBootstrapCoordinator(
            dayRepository: dayRepository,
            usageRepository: usageRepository,
            manualRepository: manualRepository
        )
        self.bootstrapCoordinator = bootstrap

        let snapshotService = daySnapshotService ?? DaySnapshotService(
            dayRepository: dayRepository,
            usageRepository: usageRepository,
            manualRepository: manualRepository
        )
        self.daySnapshotService = snapshotService
    }

    static let preview = AppContainer()
}

