import SwiftUI
import WidgetKit
import ActivityKit

// Lock Screen and Dynamic Island presentation of the running workout. The
// app keeps the content in sync (LiveActivityService); the elapsed time is
// drawn by the system from `startedAt`, so it ticks without updates.
struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            LockScreenView(attributes: context.attributes, state: context.state)
                .widgetURL(WorkoutActivityAttributes.url(for: context.attributes.sessionUUID))
        } dynamicIsland: { context in
            let state = context.state
            let strings = WidgetStrings(languageCode: state.languageCode)
            return DynamicIsland {
                // Higher priority so the exercise name gets the width the timer doesn't need.
                DynamicIslandExpandedRegion(.leading, priority: 1) {
                    HStack(spacing: 8) {
                        Image(systemName: state.exerciseIcon)
                            .font(.title2)
                            .foregroundStyle(.orange)
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
                            .foregroundStyle(.orange)
                        Text(strings["live_duration"])
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 10) {
                        SetProgressBar(completed: state.completedSets, total: state.totalSets)
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
                .foregroundStyle(.orange)
            } compactTrailing: {
                ElapsedTime(startedAt: context.attributes.startedAt)
                    .frame(maxWidth: 56)
                    .foregroundStyle(.orange)
            } minimal: {
                ProgressRing(
                    fraction: state.totalSets > 0 ? Double(state.completedSets) / Double(state.totalSets) : 0,
                    icon: state.exerciseIcon
                )
            }
            .widgetURL(WorkoutActivityAttributes.url(for: context.attributes.sessionUUID))
            .keylineTint(.orange)
        }
    }
}

/// "Bench Press · Set 3/4", or "All sets done" once nothing is left.
private func subtitle(_ state: WorkoutActivityAttributes.ContentState, strings: WidgetStrings) -> String {
    if state.allSetsDone { return strings["live_all_sets_done"] }
    guard state.exerciseSetCount > 0 else { return "" }
    return strings.format("live_set_progress", state.setNumber, state.exerciseSetCount)
}

private struct LockScreenView: View {
    let attributes: WorkoutActivityAttributes
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        let strings = WidgetStrings(languageCode: state.languageCode)
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: state.exerciseIcon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.black)
                    .frame(width: 32, height: 32)
                    .background(.orange, in: RoundedRectangle(cornerRadius: 8))
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
                    .foregroundStyle(.orange)
                    .frame(maxWidth: 110, alignment: .trailing)
            }
            if state.totalSets > 0 {
                SetProgressBar(completed: state.completedSets, total: state.totalSets)
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

/// One segment per set (completed ones green, the next one orange); a plain
/// bar when there are too many sets for segments to stay readable.
private struct SetProgressBar: View {
    let completed: Int
    let total: Int

    var body: some View {
        if total > 20 {
            ProgressView(value: Double(completed), total: Double(max(total, 1)))
                .tint(.green)
        } else {
            HStack(spacing: 3) {
                ForEach(0..<total, id: \.self) { i in
                    Capsule()
                        .fill(i < completed ? Color.green : i == completed ? Color.orange : Color.secondary.opacity(0.3))
                        .frame(height: 5)
                }
            }
        }
    }
}

private struct NextSetRow: View {
    let state: WorkoutActivityAttributes.ContentState
    let strings: WidgetStrings

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
            Text(strings.format("live_sets_done", state.completedSets, state.totalSets))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ProgressRing: View {
    let fraction: Double
    let icon: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.orange)
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
        exerciseName: "Bench Press",
        exerciseIcon: "dumbbell",
        setNumber: 3,
        exerciseSetCount: 4,
        nextKg: 82.5,
        nextReps: 8,
        completedSets: 5,
        totalSets: 12,
        allSetsDone: false
    )

    fileprivate static let finished = WorkoutActivityAttributes.ContentState(
        languageCode: "en",
        exerciseName: "Triceps Pushdown",
        exerciseIcon: "figure.strengthtraining.traditional",
        setNumber: 3,
        exerciseSetCount: 3,
        nextKg: 25,
        nextReps: 12,
        completedSets: 12,
        totalSets: 12,
        allSetsDone: true
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
