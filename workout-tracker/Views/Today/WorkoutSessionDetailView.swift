import SwiftUI
import SwiftData

struct WorkoutSessionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var lm
    @Bindable var session: WorkoutSession
    @AppStorage("healthKitEnabled") private var healthKitEnabled = false
    /// Finish turns the bar itself into the confirmation instead of opening
    /// a dialog, like the tab bar turning into a search field.
    @State private var isConfirmingFinish = false

    var sortedExercises: [ExerciseSession] {
        session.exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    var completedSets: Int {
        session.exercises.flatMap(\.sets).filter(\.isCompleted).count
    }

    var totalSets: Int {
        session.exercises.flatMap(\.sets).count
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if sortedExercises.isEmpty {
                    ContentUnavailableView(
                        lm["session_no_exercises_title"],
                        systemImage: "dumbbell",
                        description: Text(lm["session_no_exercises_message"])
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(sortedExercises) { exercise in
                        ExerciseSessionCardView(exercise: exercise)
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteExercise(exercise)
                                } label: {
                                    Label(lm["exercise_delete_title"], systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle(session.templateNameSnapshot)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Text(session.templateNameSnapshot)
                        .font(.headline)
                    Text(session.createdAt.timeFormatted)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            workoutBar
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Timer & Finish

    private var workoutBar: some View {
        Group {
            if isConfirmingFinish {
                finishConfirmation
                    .transition(.blurReplace)
            } else {
                timerRow
                    .transition(.blurReplace)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .animation(.bouncy(duration: 0.35), value: isConfirmingFinish)
        .onChange(of: session.endedAt) {
            isConfirmingFinish = false
        }
    }

    private var timerRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: session.endedAt == nil ? "timer" : "checkmark.circle.fill")
                        .foregroundStyle(session.endedAt == nil ? AnyShapeStyle(.tint) : AnyShapeStyle(.green))
                    if session.isRunning {
                        Text(timerInterval: session.timerStart...Date.distantFuture, countsDown: false)
                    } else {
                        Text(lm.duration(session.duration))
                    }
                }
                .font(.title3.monospacedDigit().weight(.semibold))

                Text(setProgressText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if session.endedAt == nil {
                Button {
                    isConfirmingFinish = true
                } label: {
                    Label(lm["session_finish"], systemImage: "flag.checkered")
                }
                .buttonStyle(.glassProminent)
                .tint(.green)
            } else {
                Button {
                    resumeWorkout()
                } label: {
                    Label(lm["session_resume"], systemImage: "play.fill")
                }
                .buttonStyle(.glass)
            }
        }
    }

    private var finishConfirmation: some View {
        VStack(spacing: 10) {
            Text(lm[healthKitEnabled ? "session_finish_message_health" : "session_finish_message"])
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            HStack(spacing: 10) {
                Button {
                    isConfirmingFinish = false
                } label: {
                    Label(lm["common_cancel"], systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)

                Button {
                    finishWorkout()
                } label: {
                    Label(lm["session_finish_confirm"], systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(.green)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .controlSize(.large)
        }
    }

    private var setProgressText: String {
        let text = lm.format("today_sets_completed", completedSets, totalSets)
        let skipped = session.skippedSetCount
        return skipped > 0 ? text + " · " + lm.format("session_sets_skipped", skipped) : text
    }

    private func finishWorkout() {
        // A workout left open on an earlier day ends at its last completed set.
        session.endedAt = session.isRunning ? Date() : session.effectiveEnd
        session.isCompleted = true
        guard healthKitEnabled else { return }
        Task {
            await HealthKitService.shared.save(session)
        }
    }

    private func resumeWorkout() {
        // Only today's workouts are timed, so only they collect paused time.
        if let endedAt = session.endedAt, session.createdAt.isToday {
            let now = Date()
            session.pausedDuration += max(0, now.timeIntervalSince(endedAt))
            session.resumedAt = now
        }
        session.endedAt = nil
        session.isCompleted = false
        guard session.healthKitWorkoutUUID != nil else { return }
        Task {
            await HealthKitService.shared.delete(session)
        }
    }

    private func deleteExercise(_ exercise: ExerciseSession) {
        session.exercises.removeAll { $0 === exercise }
        modelContext.delete(exercise)
        reindexExercises()
    }

    private func reindexExercises() {
        let sorted = session.exercises.sorted { $0.orderIndex < $1.orderIndex }
        for (i, ex) in sorted.enumerated() {
            ex.orderIndex = i
        }
    }
}
