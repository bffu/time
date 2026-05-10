# Project Progress

## Current Status

- Project: `TimeApp` SwiftUI iPhone app skeleton
- Mode: functional scaffold
- Owner: main agent + subagents
- Tracking doc for handoff: `HANDOFF.md`

## Active Workstreams

| Workstream | Owner | Scope | Status |
| --- | --- | --- | --- |
| Core domain and services | Main | `TimeApp/Models`, `TimeApp/Persistence`, `TimeApp/Services`, `TimeApp/Recognition` | Done |
| App shell and import/settings pages | Main | `TimeApp/App`, `TimeApp/Features/Import`, `TimeApp/Features/Settings` | Done |
| Day view, manual blocks, shared UI | Main | `TimeApp/Features/DayView`, `TimeApp/Features/ManualBlocks`, `TimeApp/SharedUI` | Done |
| Reports page | Main | `TimeApp/Features/Reports` | Done |
| Docs, CI, config, share extension | Main | `.github/workflows`, root docs, `Config`, `project.yml`, `TimeShareExtension` | Done |

## Milestones

- [x] Define project structure
- [x] Create core models
- [x] Create service protocols and default implementations
- [x] Create SwiftUI screens and navigation shell
- [x] Add import flow and sample data
- [x] Add unsigned IPA CI and setup docs
- [x] Add Vision OCR, text parsers, and hourly chart image parsing
- [x] Add share extension app-group manifest handoff
- [x] Add JSON-backed repositories for app data
- [x] Add initial unit test target
- [ ] Validate first Xcode build on macOS
- [ ] Decide whether MVP needs SwiftData beyond JSON-backed repositories

## Notes

- This repository contains Swift source and an `XcodeGen` spec, not a generated `.xcodeproj`.
- The first tracking file to watch is this one: `PROJECT_PROGRESS.md`.
- If switching machines, read `HANDOFF.md` before continuing.
- Multiple subagent attempts were made, but remote execution was unstable, so the scaffold was completed locally.
