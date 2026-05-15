# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is an Xcode project (no Swift Package Manager). Build and run via Xcode or `xcodebuild`:

```bash
# Build for simulator
xcodebuild -project workout-tracker.xcodeproj -scheme workout-tracker -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild -project workout-tracker.xcodeproj -scheme workout-tracker -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run a single test class
xcodebuild -project workout-tracker.xcodeproj -scheme workout-tracker -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:workout-trackerTests/ClassName
```

There is no linter configured. The project has no SwiftLint, SwiftFormat, or similar tooling.

## Architecture

**SwiftData + SwiftUI** app with a clear Template → Session separation:

- **Templates** are blueprints the user creates once: `WorkoutTemplate` → `ExerciseTemplate` → `SetTemplate` (with `defaultKg`/`defaultReps`)
- **Sessions** are runtime instances created from templates when starting a workout: `WorkoutSession` → `ExerciseSession` → `SetSession`

When the user starts a workout, `TemplateSessionBuilder.build(from:)` snapshots the template into a new session. When the user completes a set, `TemplateDefaultUpdater.syncIfNeeded(setSession:context:)` writes the actual kg/reps back to the originating `SetTemplate`, so defaults stay current.

**Foreign key encoding:** SwiftData doesn't support direct cross-graph relationships between Template and Session models. `ExerciseSession.exerciseTemplateId` and `SetSession.setTemplateId` store `PersistentIdentifier` values encoded as `Data` to work around this limitation.

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

## Current State

- **Today tab:** Fully functional — start workouts from templates, log sets, auto-sync back to template defaults.
- **Templates tab:** Fully functional — create/edit/delete templates, exercises, sets; drag-to-reorder.
- **Stats tab:** Placeholder only (`StatsView` shows "İstatistikler Yakında"). No analytics implemented yet.
