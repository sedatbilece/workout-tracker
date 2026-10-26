import SwiftUI
import SwiftData

struct WorkoutSessionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var lm
    @Bindable var session: WorkoutSession
    @AppStorage("healthKitEnabled") private var healthKitEnabled = false
    @State private var showFinishConfirm = false

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
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: session.endedAt == nil ? "timer" : "checkmark.circle.fill")
                        .foregroundStyle(session.endedAt == nil ? Color.accentColor : Color.green)
                    if session.isRunning {
                        Text(timerInterval: session.createdAt...Date.distantFuture, countsDown: false)
                    } else {
                        Text(lm.duration(session.duration))
                    }
                }
                .font(.title3.monospacedDigit().weight(.semibold))

                Text(lm.format("today_sets_completed", completedSets, totalSets))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if session.endedAt == nil {
                Button {
                    showFinishConfirm = true
                } label: {
                    Label(lm["session_finish"], systemImage: "flag.checkered")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .confirmationDialog(lm["session_finish_title"], isPresented: $showFinishConfirm, titleVisibility: .visible) {
                    Button(lm["session_finish"]) {
                        finishWorkout()
                    }
                    Button(lm["common_cancel"], role: .cancel) {}
                } message: {
                    Text(lm[healthKitEnabled ? "session_finish_message_health" : "session_finish_message"])
                }
            } else {
                Button {
                    resumeWorkout()
                } label: {
                    Label(lm["session_resume"], systemImage: "play.fill")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
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
