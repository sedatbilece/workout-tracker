import SwiftUI
import SwiftData

struct TodayView: View {
    @Query private var allSessions: [WorkoutSession]
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var lm
    @State private var showingTemplatePicker = false
    @State private var sessionToDelete: WorkoutSession?

    private var todaySessions: [WorkoutSession] {
        let calendar = Calendar.current
        return allSessions.filter {
            calendar.isDateInToday($0.date)
        }.sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            Group {
                if todaySessions.isEmpty {
                    ContentUnavailableView(
                        lm["today_no_workouts_title"],
                        systemImage: "calendar.badge.plus",
                        description: Text(lm["today_no_workouts_message"])
                    )
                } else {
                    List {
                        ForEach(todaySessions) { session in
                            NavigationLink(destination: WorkoutSessionDetailView(session: session)) {
                                SessionRowView(session: session)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    sessionToDelete = session
                                } label: {
                                    Label(lm["common_delete"], systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(lm["today_title"])
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingTemplatePicker = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingTemplatePicker) {
                TemplatePicker()
            }
            .confirmationDialog(
                lm["today_delete_workout_title"],
                isPresented: Binding(
                    get: { sessionToDelete != nil },
                    set: { if !$0 { sessionToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button(lm["common_delete"], role: .destructive) {
                    if let session = sessionToDelete {
                        modelContext.delete(session)
                    }
                    sessionToDelete = nil
                }
                Button(lm["common_cancel"], role: .cancel) {
                    sessionToDelete = nil
                }
            } message: {
                if let name = sessionToDelete?.templateNameSnapshot {
                    Text(lm.format("today_delete_workout_message", name))
                }
            }
        }
    }
}

private struct SessionRowView: View {
    let session: WorkoutSession
    @Environment(LocalizationManager.self) private var lm

    private var completedSets: Int {
        session.exercises.flatMap(\.sets).filter(\.isCompleted).count
    }

    private var totalSets: Int {
        session.exercises.flatMap(\.sets).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.templateNameSnapshot)
                .font(.headline)
            HStack {
                Text(lm.format("today_exercises_count", session.exercises.count))
                Text("·")
                Text(lm.format("today_sets_completed", completedSets, totalSets))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TodayView()
        .modelContainer(for: WorkoutSession.self, inMemory: true)
        .environment(LocalizationManager())
}
