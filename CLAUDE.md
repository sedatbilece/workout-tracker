# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

**IMPORTANT — ask who verifies:** In every session, right after a plan is approved, ask the user whether **Claude** or **the user** will build and check the work between phases. Don't assume either way.
- **Claude verifies:** build with `xcodebuild`, run the app in the iOS Simulator, and check each phase before starting the next. Don't overwrite an app's existing data on a simulator; use a simulator without the app or ask first.
- **The user verifies:** make the code changes, stop at the end of each phase, and wait for the user's build feedback (they paste any errors here).

This is an Xcode project (no Swift Package Manager). Build and run via Xcode or `xcodebuild`:

```bash
# Build for simulator
xcodebuild -project workout-tracker.xcodeproj -scheme workout-tracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run tests
xcodebuild -project workout-tracker.xcodeproj -scheme workout-tracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# Run a single test class
xcodebuild -project workout-tracker.xcodeproj -scheme workout-tracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:workout-trackerTests/ClassName
```

There is no linter configured. The project has no SwiftLint, SwiftFormat, or similar tooling.

## Git Workflow

**All commits go to the `dev` branch — never commit directly to `main`.** `main` only receives `dev` merges when the user does a build/release: bump the build number on `dev`, merge `dev` → `main`, then tag (steps in `docs/VERSIONING.md`). Don't merge to `main` or push unless the user asks.

**Release notes on every `dev` → `main` merge:** before merging, add an entry for the new build at the top of `workout-tracker/ReleaseNotes.json` (shown in Profile → version → Release Notes). Write it from the diff since the previous merge (`git log build-<prev>..dev`, or `origin/main..dev` while no `build-*` tag exists): short, user-facing bullets in all four languages (`tr`, `en`, `es`, `ru`), no internal/refactor-only items. Also move CHANGELOG's `[Yayınlanmadı]` section under the new version/build heading.

## Architecture

**SwiftData + SwiftUI** app with a clear Template → Session separation:

- **Templates** are blueprints the user creates once: `WorkoutTemplate` → `ExerciseTemplate` → `SetTemplate` (with `defaultKg`/`defaultReps`)
- **Sessions** are runtime instances created from templates when starting a workout: `WorkoutSession` → `ExerciseSession` → `SetSession`

When the user starts a workout, `TemplateSessionBuilder.build(from:)` snapshots the template into a new session. When the user completes a set, `TemplateDefaultUpdater.syncIfNeeded(setSession:context:)` writes the actual kg/reps back to the originating `SetTemplate`, so defaults stay current.

**Cross-graph links via UUID:** SwiftData doesn't support direct relationships between the Template and Session graphs. Every model has a stable `uuid: UUID?`; `ExerciseSession.exerciseTemplateUUID` and `SetSession.setTemplateUUID` point at the originating template's `uuid`. Never store `persistentModelID` for this — it is local to one store and breaks on backup/restore and iCloud sync. `DataMigrator.run(context:)` (called at launch) backfills missing UUIDs and converts the legacy `...IdData` fields.

**CloudKit-ready models:** every stored property has a default or is optional, and relationships are optional with an inverse. The stored relationship is named `exerciseItems` / `setItems`; use the non-optional computed `exercises` / `sets` in code.

**Data flow pattern:**
- `@Query` fetches data directly in views
- `@Bindable` is used for editing `@Model` objects in forms
- `@Environment(\.modelContext)` is used for insert/delete operations
- No ViewModels — business logic lives in `Services/`

## Key Conventions

**UI language is Turkish throughout.** All user-facing strings, tab labels, button titles, and error messages are in Turkish (e.g., "Bugün", "Şablonlar", "İstatistikler", "Hareket Ekle").

**All static strings must be localized.** Never write a bare string literal for any user-facing text. Always:
1. Add the key to `Localizable.xcstrings` with translations for all supported locales (`tr`, `en`, `es`, `ru`).
2. Display it via `lm["key"]` where `lm` is `@Environment(LocalizationManager.self)`, or `lm.format("key", arg)` for strings with arguments.

```swift
// Wrong
Text("Antrenman Başlat")

// Correct
@Environment(LocalizationManager.self) private var lm
Text(lm["start_workout"])
```

Key naming convention: `snake_case`, grouped by screen (e.g., `today_start_workout`, `template_add_exercise`, `profile_language_settings`).

**OrderIndex reindexing:** Whenever exercises or sets are reordered or deleted, the full array is iterated and `orderIndex` is reassigned sequentially (0, 1, 2…). This pattern appears in `TemplateDetailView` and `ExerciseTemplateEditView`.

**Snapshot fields:** `ExerciseSession` and `SetSession` carry `nameSnapshot` / `iconNameSnapshot` fields so the session display doesn't break if the originating template is later edited or deleted.

**Number formatting:** Use `NumberFormatter.workoutWeight` (1 decimal place, decimal style) for all weight display/input. It's defined in `Helpers/NumberFormatter+Workout.swift`.

**Date utilities:** `Date.isToday` and `Date.shortFormatted` (Turkish locale `tr_TR`) are in `Helpers/DateHelper.swift`.

**Versioning:** `MARKETING_VERSION` is bumped only for App Store releases; `CURRENT_PROJECT_VERSION` (build) is incremented by 1 on every `dev` → `main` merge and never decreases or resets. Don't change either unless asked. Full scheme in `docs/VERSIONING.md`.

## Current State

- **Today tab:** Fully functional — start workouts from templates, log sets, auto-sync back to template defaults.
- **Templates tab:** Fully functional — create/edit/delete templates, exercises, sets; drag-to-reorder.
- **Stats tab:** History and per-template progression statistics.
- **Workout timer:** A session's timer runs from `createdAt` until the user taps Finish (`endedAt`, `isCompleted`); helpers in `Helpers/SessionStats.swift`, durations formatted with `lm.duration(_:)`.
- **Profile → Settings:** `SettingsView` groups `DataSettingsView` (iCloud, Apple Health, backup), `LiveActivitySettingsView` (the `liveActivityEnabled` toggle that `LiveActivitySync` honors) and `LanguageSettingsView`. Profile itself keeps only the header, theme and version row.
- **Settings → iCloud:** `CloudSync` builds the `ModelContainer` with the private CloudKit database when the `iCloudSyncEnabled` setting is on (read once at launch, falls back to a local store on failure). `DuplicateCleaner` removes copies left by restoring the same backup on two devices.
- **Settings → Data:** `BackupService` exports/restores a JSON backup, merging by `uuid`.
- **Settings → Apple Health:** `HealthKitService` writes finished sessions as strength training (write-only).
- **Live Activity:** `LiveActivitySync` (modifier on `RootView`) builds a `WorkoutActivitySnapshot` from the most recent running workout and calls `LiveActivityService.sync`, which starts/updates/ends the activity — so mutation sites never notify it themselves. The `WorkoutWidgets` extension draws it (Lock Screen + Dynamic Island), with its own `Localizable.xcstrings` and `WidgetStrings` (language code travels in the content state). `Shared/` is synced to both targets (`WorkoutActivityAttributes`, `NumberFormatter+Workout`). Tapping opens `workouttracker://session/<uuid>` → `TabRouter.pendingSessionUUID` → `TodayView`. The extension's Info.plist is `Support/WorkoutWidgets-Info.plist`; version/build numbers live at project level so both targets match.
- **Profile → version row:** opens `ReleaseNotesView`, which reads `ReleaseNotes.json` via `ReleaseNote.loadAll()` and shows each build's notes in the app language.

Entitlements live in `workout-tracker/workout-tracker.entitlements` (iCloud/CloudKit, push, HealthKit); `Support/Info.plist` only adds `UIBackgroundModes` and is merged with the generated Info.plist; it lives outside the `workout-tracker/` folder on purpose, since every file in that synced folder is copied into the app bundle ("Multiple commands produce …Info.plist").
