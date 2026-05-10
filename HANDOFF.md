# Handoff

## Goal

Build an iPhone app for offline analysis of iOS Screen Time screenshots.

Primary stack:

- `SwiftUI`
- `Vision` for local OCR
- local image analysis for hourly chart bars
- repository protocols with JSON file-backed stores for the live app
- `Share Extension`
- `XcodeGen` via `project.yml` because this workspace is being prepared from Windows

## Current State

Already created:

- `project.yml`
- `Config/*.plist`
- `Config/*.entitlements`
- `TimeShareExtension/ShareViewController.swift`
- domain models in `TimeApp/Models`
- repository protocols, JSON file-backed stores, and preview in-memory stores in `TimeApp/Persistence`
- recognition protocol layer in `TimeApp/Recognition`
- Vision OCR service in `TimeApp/Recognition/VisionOCRService.swift`
- OCR text parsers in `TimeApp/Recognition/TextScreenTimeParsers.swift`
- hourly chart parser in `TimeApp/Recognition/ImageHourlyChartParser.swift`
- app-group inbox reader in `TimeApp/Services/AppGroupImportInbox.swift`
- service layer in `TimeApp/Services`
- app shell in `TimeApp/App`
- SwiftUI pages in `TimeApp/Features`
- shared components in `TimeApp/SharedUI`
- root docs: `README.md`, `DEVELOPMENT.md`, `PROJECT_PROGRESS.md`
- CI workflow: `.github/workflows/ios-unsigned-ipa.yml`

Still not production-ready:

- first compile verification on macOS / Xcode
- OCR and chart parsing accuracy on a broad real screenshot set
- `SwiftData` persistence
- import review UI for low-confidence recognition
- cleanup policy for consumed app-group share batches

## Recommended Work Order

1. Run `xcodegen generate` on macOS.
2. Build once in Xcode or with `xcodebuild` and fix compiler issues.
3. Test recognition with real Chinese and English Screen Time screenshots.
4. Add review UI for low-confidence OCR/classification/chart results.
5. Migrate the JSON file-backed repositories to `SwiftData`.
6. Add signing and TestFlight packaging.

## Architecture Notes

### Domain

Key types:

- `DayRecord`
- `ImportedScreenshot`
- `ImportBatch`
- `AppUsageDaily`
- `AppUsageHourly`
- `ManualActivityBlock`
- `ReportSnapshot`

### Persistence

Current live repositories:

- `FileBackedDayRecordRepository`
- `FileBackedAppUsageRepository`
- `FileBackedManualActivityRepository`
- `FileBackedImportBatchRepository`

Preview repositories:

- `InMemoryDayRecordRepository`
- `InMemoryAppUsageRepository`
- `InMemoryManualActivityRepository`
- `InMemoryImportBatchRepository`

Migration path:

- Keep repository protocols stable.
- Replace implementations with SwiftData-backed repositories.
- Preserve import and reconciliation call sites.

### Recognition

Current pipeline:

- `VisionOCRService`
- `RuleBasedScreenshotClassifier`
- `TextOverviewParser`
- `TextAppDetailParser`
- `ImageHourlyChartParser`
- `DefaultReconciliationEngine`

The pipeline extracts OCR blocks, classifies screenshots as overview or app detail, parses dates and durations from text, estimates hourly chart bars from image pixels, and reconciles the result into day/app/hourly records.

### Share Extension

The share extension now:

- receives image attachments from the iOS share sheet
- copies them into `group.com.example.TimeApp/IncomingShares/<batch-id>/`
- writes `manifest.json`

The main app now:

- reads pending manifests via `AppGroupImportInbox`
- imports shared batches during bootstrap
- checks again when the app returns to the foreground
- marks consumed manifests as `manifest.processed.json` while leaving image files available to imported records

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

- This Windows environment does not include `swift`, Xcode, or `xcodegen`, so local compile verification was not possible here.
- The CI artifact is an unsigned `ipa`; it is useful for build verification, not direct normal-device installation.
- `TimelineService` currently lays out imported app usage sequentially for visualization.
- The chart parser is heuristic and should be tuned against real screenshots.
- App models are plain Swift structs persisted through JSON repositories; no SwiftData models are wired yet.

## Immediate Next Files To Focus On

- `TimeApp/Recognition/VisionOCRService.swift`
- `TimeApp/Recognition/TextScreenTimeParsers.swift`
- `TimeApp/Recognition/ImageHourlyChartParser.swift`
- `TimeApp/Services/AppGroupImportInbox.swift`
- `TimeShareExtension/ShareViewController.swift`
- `project.yml`

## Tracking

Use these files for status:

- `PROJECT_PROGRESS.md`
- `DEVELOPMENT.md`
