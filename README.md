# time

`TimeApp` is a SwiftUI-first iPhone app scaffold for analyzing iOS Screen Time screenshots offline.

The current repository is a starter skeleton, not a finished or signed iOS app. The main goals of this scaffold are:

- establish a clean project structure for a native iPhone app
- define the domain model for screenshot imports, hourly app usage, manual time blocks, and reports
- process screenshots with Vision OCR, text parsing, local chart analysis, and repository-backed app state
- make it possible to generate an Xcode project from Windows-authored files with `XcodeGen`

## What Exists Today

- `TimeApp/`
  Swift source tree for the app, organized by app shell, models, persistence, services, recognition, features, and shared UI.
- `TimeShareExtension/`
  Share extension entry point that copies shared screenshots into the app group container and writes an import manifest.
- `Config/`
  App and extension `Info.plist` files plus app group entitlements.
- `project.yml`
  `XcodeGen` project specification. Generate the `.xcodeproj` on a Mac instead of hand-editing Xcode project files on Windows.
- `PROJECT_PROGRESS.md`
  High-level progress tracker for the scaffold.
- `HANDOFF.md`
  machine-to-machine continuation notes.
- `DEVELOPMENT.md`
  implementation notes and next tasks.

## Local Development Flow

This repository is designed for a hybrid workflow:

1. Write Swift source files from Windows or any editor.
2. Open the repo on macOS.
3. Install `XcodeGen`.
4. Generate `TimeApp.xcodeproj` from `project.yml`.
5. Build and debug with Xcode.

## Generate the Xcode Project

On macOS:

```bash
brew install xcodegen
xcodegen generate
open TimeApp.xcodeproj
```

## Build Notes

- The app target is intended to host SwiftUI screens and app logic.
- The share extension target writes shared image batches into the configured app group for the main app to consume.
- Code signing is still required for real device installation.
- GitHub Actions can do unsigned CI builds on macOS runners, but device installs still need Apple signing assets.

## GitHub Actions Unsigned IPA

The repository now includes a single workflow at `.github/workflows/ios-unsigned-ipa.yml`.

What it does on GitHub-hosted macOS:

1. installs `XcodeGen`
2. generates `TimeApp.xcodeproj` from `project.yml`
3. archives the app for `generic/platform=iOS` with signing disabled
4. packages `TimeApp.app` into `build/export/TimeApp-unsigned.ipa`
5. uploads the unsigned `ipa` and its SHA-256 file as workflow artifacts

Important limitation:

- the artifact is an unsigned `ipa` for CI output and inspection
- it will still need Apple signing before a normal iPhone can install it

## Next Implementation Priorities

1. make the SwiftUI shell compile cleanly in Xcode
2. tune `Vision` OCR, screenshot classification, and chart parsing with real screenshots
3. add review UI for low-confidence recognition results
4. keep JSON-backed persistence for MVP or migrate to `SwiftData` if richer querying is needed
5. finish signing and device-install packaging

## Useful Root Files

- `README.md`
  project overview and setup
- `PROJECT_PROGRESS.md`
  short progress tracker
- `HANDOFF.md`
  current task split and continuation notes
- `DEVELOPMENT.md`
  deeper implementation notes
