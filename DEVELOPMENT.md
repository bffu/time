# Development Handoff

## Current State

This repository is in scaffold mode. The source tree, SwiftUI navigation shell, app state wiring, and placeholder services already exist, but real iOS framework integration is still pending.

## Working Assumptions

- product type: native iPhone app
- UI framework: `SwiftUI`
- persistence direction: `SwiftData` later, in-memory placeholders now
- OCR direction: `Vision`
- chart parsing direction: custom local image analysis
- import methods: in-app image picker and iOS share extension

## Directory Ownership

- `TimeApp/App`
  app entry, dependency container, shared app state
- `TimeApp/Models`
  domain entities
- `TimeApp/Persistence`
  repository protocols and temporary in-memory stores
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
6. wire real OCR and image parsing into `TimeApp/Recognition`

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
- no test target
- no real OCR implementation
- no real image parsing implementation
- no persistent storage layer
- no working app group manifest handoff in the share extension

## Recommended Next Steps

1. run a first Xcode compile and fix compiler issues
2. validate `project.yml` on macOS with `xcodegen`
3. replace placeholder OCR and chart parsing implementations
4. swap the in-memory repositories for `SwiftData`
5. only then add signing and TestFlight packaging
