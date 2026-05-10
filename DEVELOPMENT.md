# Development Handoff

## Current State

This repository is a functional SwiftUI scaffold. The source tree, navigation shell, app state wiring, Vision OCR, text parsing, chart image analysis, JSON-backed repositories, and share-extension app-group handoff are wired, while first Xcode compile verification is still pending.

## Working Assumptions

- product type: native iPhone app
- UI framework: `SwiftUI`
- persistence direction: JSON file-backed repositories now, `SwiftData` later
- OCR direction: `Vision`
- chart parsing direction: custom local image analysis
- import methods: in-app image picker and iOS share extension

## Directory Ownership

- `TimeApp/App`
  app entry, dependency container, shared app state
- `TimeApp/Models`
  domain entities
- `TimeApp/Persistence`
  repository protocols, JSON file-backed stores, and preview in-memory stores
- `TimeApp/Services`
  import, reporting, timeline, and orchestration services
- `TimeApp/Recognition`
  OCR and parser protocol boundaries
- `TimeApp/Features`
  SwiftUI screens
- `TimeApp/SharedUI`
  reusable UI building blocks
- `TimeShareExtension`
  share sheet entry point

## How To Continue On Another Computer

1. clone or copy this repository to a Mac
2. install `XcodeGen`
3. run `xcodegen generate`
4. open `TimeApp.xcodeproj`
5. validate the existing SwiftUI shell under `TimeApp/App` and `TimeApp/Features`
6. validate and tune the OCR and chart parsing behavior with real screenshots

## CI Strategy

The included workflow at `.github/workflows/ios-unsigned-ipa.yml` is intended for:

- checking out source
- installing `XcodeGen`
- generating the Xcode project
- archiving for `generic/platform=iOS` with signing disabled
- packaging the archived `.app` into an unsigned `ipa`
- uploading the `ipa` and build logs as workflow artifacts

The workflow assumes the Swift source tree and the generated Xcode project spec stay aligned.

## Known Gaps

- SwiftUI shell exists but has not been compiled in Xcode yet
- the test target is initial and should grow with real screenshot fixtures
- JSON-backed persistence exists, but there is no `SwiftData` schema yet
- chart parsing is heuristic and should be tuned with real screenshots

## Recommended Next Steps

1. run a first Xcode compile and fix compiler issues
2. validate `project.yml` on macOS with `xcodegen`
3. test recognition accuracy on real Chinese and English Screen Time screenshots
4. keep JSON persistence for MVP or migrate it to `SwiftData` when richer querying is needed
5. add signing and TestFlight packaging
