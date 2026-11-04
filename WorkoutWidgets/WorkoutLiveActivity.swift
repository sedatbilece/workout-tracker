import SwiftUI
import WidgetKit
import ActivityKit

// Lock Screen and Dynamic Island presentation of the running workout. The
// app keeps the content in sync (LiveActivityService); the elapsed time is
// drawn by the system from `startedAt`, so it ticks without updates.
struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            ActivityContentView(attributes: context.attributes, state: context.state)
                .widgetURL(WorkoutActivityAttributes.url(for: context.attributes.sessionUUID))
        } dynamicIsland: { context in
            let state = context.state
            let strings = LocalizedStrings(languageCode: state.languageCode)
            let accent = state.accent.color
            return DynamicIsland {
                // Higher priority so the exercise name gets the width the timer doesn't need.
                DynamicIslandExpandedRegion(.leading, priority: 1) {
                    HStack(spacing: 8) {
                        Image(systemName: state.exerciseIcon)
                            .font(.title2)
                            .foregroundStyle(accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(state.exerciseName.isEmpty ? context.attributes.templateName : state.exerciseName)
                                .font(.headline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Text(subtitle(state, strings: strings))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        ElapsedTime(startedAt: context.attributes.startedAt)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(accent)
                        Text(strings["live_duration"])
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 10) {
                        SetProgressBar(statuses: state.setStatuses, accent: state.accent.color)
                        NextSetRow(state: state, strings: strings)
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: state.allSetsDone ? "checkmark.circle.fill" : state.exerciseIcon)
                    if !state.allSetsDone && state.exerciseSetCount > 0 {
                        Text("\(state.setNumber)/\(state.exerciseSetCount)")
                            .monospacedDigit()
                    }
                }
                .foregroundStyle(accent)
            } compactTrailing: {
                ElapsedTime(startedAt: context.attributes.startedAt)
                    .frame(maxWidth: 56)
                    .foregroundStyle(accent)
            } minimal: {
                ProgressRing(
                    fraction: state.totalSets > 0 ? Double(state.completedSets) / Double(state.totalSets) : 0,
                    icon: state.exerciseIcon,
                    accent: accent
                )
            }
            .widgetURL(WorkoutActivityAttributes.url(for: context.attributes.sessionUUID))
            .keylineTint(accent)
        }
        // Apple Watch Smart Stack; tapping it opens the watch app.
        .supplementalActivityFamilies([.small])
    }
}

/// "Bench Press · Set 3/4", or "All sets done" once nothing is left.
private func subtitle(_ state: WorkoutActivityAttributes.ContentState, strings: LocalizedStrings) -> String {
    if state.allSetsDone { return strings["live_all_sets_done"] }
    guard state.exerciseSetCount > 0 else { return "" }
    return strings.format("live_set_progress", state.setNumber, state.exerciseSetCount)
}

/// The Lock Screen layout, or the compact one for the Apple Watch Smart Stack.
private struct ActivityContentView: View {
    @Environment(\.activityFamily) private var family
    let attributes: WorkoutActivityAttributes
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        switch family {
        case .small:
            SmartStackView(attributes: attributes, state: state)
        default:
            LockScreenView(attributes: attributes, state: state)
        }
    }
}

private struct SmartStackView: View {
    let attributes: WorkoutActivityAttributes
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        let strings = LocalizedStrings(languageCode: state.languageCode)
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: state.allSetsDone ? "checkmark.circle.fill" : state.exerciseIcon)
                    .foregroundStyle(state.allSetsDone ? .green : state.accent.color)
                Text(state.exerciseName.isEmpty ? attributes.templateName : state.exerciseName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer(minLength: 4)
            }
            HStack {
                Text(subtitle(state, strings: strings))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 4)
                ElapsedTime(startedAt: attributes.startedAt)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(state.accent.color)
            }
            if state.totalSets > 0 {
                SetProgressBar(statuses: state.setStatuses, accent: state.accent.color, height: 4)
            }
        }
        .padding(10)
    }
}

private struct LockScreenView: View {
    let attributes: WorkoutActivityAttributes
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        let strings = LocalizedStrings(languageCode: state.languageCode)
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: state.exerciseIcon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(state.accent.color, in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text(attributes.templateName)
                        .font(.headline)
                        .lineLimit(1)
                    Text([state.exerciseName, subtitle(state, strings: strings)]
                        .filter { !$0.isEmpty }
                        .joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                ElapsedTime(startedAt: attributes.startedAt)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(state.accent.color)
                    .frame(maxWidth: 110, alignment: .trailing)
            }
            if state.totalSets > 0 {
                SetProgressBar(statuses: state.setStatuses, accent: state.accent.color)
                NextSetRow(state: state, strings: strings)
            }
        }
        .padding(16)
    }
}

/// Counts up from the workout start, like `SessionDurationLabel` in the app.
private struct ElapsedTime: View {
    let startedAt: Date

    var body: some View {
        Text(timerInterval: startedAt...Date.distantFuture, countsDown: false)
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
    }
}

private struct NextSetRow: View {
    let state: WorkoutActivityAttributes.ContentState
    let strings: LocalizedStrings

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            if state.allSetsDone {
                Label(strings["live_all_sets_done"], systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    Text(strings["live_next_set"])
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(strings.weightReps(kg: state.nextKg, reps: state.nextReps))
                        .font(.subheadline.weight(.semibold))
                }
            }
            Spacer()
            Text(state.skippedSets > 0
                ? strings.format("live_sets_done_skipped", state.completedSets, state.totalSets, state.skippedSets)
                : strings.format("live_sets_done", state.completedSets, state.totalSets))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ProgressRing: View {
    let fraction: Double
    let icon: String
    let accent: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(accent)
        }
    }
}

// MARK: - Previews

extension WorkoutActivityAttributes {
    fileprivate static let preview = WorkoutActivityAttributes(
        sessionUUID: UUID(),
        templateName: "Push Day",
        startedAt: .now.addingTimeInterval(-32 * 60)
    )
}

extension WorkoutActivityAttributes.ContentState {
    fileprivate static let inProgress = WorkoutActivityAttributes.ContentState(
        languageCode: "tr",
        accent: .orange,
        exerciseName: "Bench Press",
        exerciseIcon: "dumbbell",
        setNumber: 3,
        exerciseSetCount: 4,
        nextKg: 82.5,
        nextReps: 8,
        completedSets: 5,
        skippedSets: 1,
        totalSets: 12,
        allSetsDone: false,
        setStatuses: [.completed, .completed, .completed, .skipped, .completed, .completed]
            + Array(repeating: .pending, count: 6)
    )

    fileprivate static let finished = WorkoutActivityAttributes.ContentState(
        languageCode: "en",
        accent: .blue,
        exerciseName: "Triceps Pushdown",
        exerciseIcon: "figure.strengthtraining.traditional",
        setNumber: 3,
        exerciseSetCount: 3,
        nextKg: 25,
        nextReps: 12,
        completedSets: 12,
        skippedSets: 0,
        totalSets: 12,
        allSetsDone: true,
        setStatuses: Array(repeating: .completed, count: 12)
    )
}

#Preview("Lock Screen", as: .content, using: WorkoutActivityAttributes.preview) {
    WorkoutLiveActivity()
} contentStates: {
    WorkoutActivityAttributes.ContentState.inProgress
    WorkoutActivityAttributes.ContentState.finished
}

#Preview("Expanded", as: .dynamicIsland(.expanded), using: WorkoutActivityAttributes.preview) {
    WorkoutLiveActivity()
} contentStates: {
    WorkoutActivityAttributes.ContentState.inProgress
}

#Preview("Compact", as: .dynamicIsland(.compact), using: WorkoutActivityAttributes.preview) {
    WorkoutLiveActivity()
} contentStates: {
    WorkoutActivityAttributes.ContentState.inProgress
}
