# Handoff

## Goal

Build an iPhone app skeleton for offline analysis of iOS Screen Time screenshots.

Primary stack:

- `SwiftUI`
- `Vision` for local OCR
- `SwiftData` later, currently replaced by in-memory repositories for scaffold speed
- `Share Extension`
- `XcodeGen` via `project.yml` because this workspace is being prepared from Windows

## Current State

Already created:

- `project.yml`
- `Config/*.plist`
- `Config/*.entitlements`
- `TimeShareExtension/ShareViewController.swift`
- Domain models in `TimeApp/Models`
- Repository protocols and in-memory implementations in `TimeApp/Persistence`
- Recognition protocol layer and placeholder implementations in `TimeApp/Recognition`
- Service layer skeleton in `TimeApp/Services`
- App shell in `TimeApp/App`
- SwiftUI pages in `TimeApp/Features`
- Shared components in `TimeApp/SharedUI`
- Root docs: `README.md`, `DEVELOPMENT.md`, `PROJECT_PROGRESS.md`
- CI workflow: `.github/workflows/ios-unsigned-ipa.yml`
- Progress file: `PROJECT_PROGRESS.md`

Still placeholder / not production-ready:

- real `Vision` OCR
- real hourly chart parser
- `SwiftData` persistence
- true app group handoff inside the share extension
- first compile verification on macOS / Xcode

## Recommended Work Order

1. Run `xcodegen generate` on macOS.
2. Build once in Xcode or with `xcodebuild` and fix compile issues.
3. Replace placeholder OCR and chart parsing implementations.
4. Replace in-memory repositories with `SwiftData`.
5. Wire the share extension payload into the app group container.

## Suggested Next Parallel Split

Worker 1:

- replace `PlaceholderOCRService`
- implement screenshot text extraction with `Vision`

Worker 2:

- replace `PlaceholderHourlyChartParser`
- build chart-region detection and hour bar extraction

Worker 3:

- swap in-memory repositories for `SwiftData`
- keep repository protocols stable

Worker 4:

- finish share extension file persistence
- add import review flow for low-confidence recognition

## Architecture Notes

### Domain

Key types already present:

- `DayRecord`
- `ImportedScreenshot`
- `ImportBatch`
- `AppUsageDaily`
- `AppUsageHourly`
- `ManualActivityBlock`
- `ReportSnapshot`

### Persistence

Current scaffold uses in-memory repositories:

- `InMemoryDayRecordRepository`
- `InMemoryAppUsageRepository`
- `InMemoryManualActivityRepository`
- `InMemoryImportBatchRepository`

Later migration path:

- Keep repository protocols
- Replace implementations with SwiftData-backed repositories

### Recognition

Current placeholder pipeline:

- `PlaceholderOCRService`
- `RuleBasedScreenshotClassifier`
- `PlaceholderOverviewParser`
- `PlaceholderAppDetailParser`
- `PlaceholderHourlyChartParser`
- `DefaultReconciliationEngine`

Real implementation later should replace the placeholder pieces with:

- `Vision` OCR
- rule-based screenshot anchoring
- custom chart image parsing
- confidence-driven reconciliation

## Build Strategy

From macOS:

1. Install XcodeGen.
2. Run `xcodegen generate`.
3. Open generated `TimeApp.xcodeproj`.
4. Fix signing bundle identifiers and app group IDs.
5. Build with `xcodebuild` or Xcode UI.

From GitHub Actions:

1. Run `.github/workflows/ios-unsigned-ipa.yml`.
2. Let the runner archive with signing disabled.
3. Download `TimeApp-unsigned-ipa` from workflow artifacts.

## Known Caveats

- Current repository is a scaffold, not yet a full compile-verified app.
- The CI artifact is an unsigned `ipa`; it is useful for build verification, not direct normal-device installation.
- `TimelineService` currently lays out imported app usage sequentially for visualization only.
- `ChartParser` is placeholder logic.
- Share extension currently accepts images but does not persist payloads to the app group yet.
- App models are plain Swift structs; no SwiftData models are wired yet.

## Immediate Next Files To Focus On

- `TimeApp/Recognition/RecognitionTypes.swift`
- `TimeApp/Services/RecognitionPipeline.swift`
- `TimeApp/Services/DaySnapshotService.swift`
- `TimeShareExtension/ShareViewController.swift`
- `project.yml`

## Tracking

Use these files for status:

- `PROJECT_PROGRESS.md`
- `HANDOFF.md`
