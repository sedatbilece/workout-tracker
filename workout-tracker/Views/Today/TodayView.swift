import SwiftUI
import SwiftData

struct TodayView: View {
    @Query private var allSessions: [WorkoutSession]
    @State private var showingTemplatePicker = false

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
                        "Antrenman Yok",
                        systemImage: "calendar.badge.plus",
                        description: Text("Bugün için bir antrenman şablonu eklemek için + butonuna dokun.")
                    )
                } else {
                    List {
                        ForEach(todaySessions) { session in
                            NavigationLink(destination: WorkoutSessionDetailView(session: session)) {
                                SessionRowView(session: session)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Bugün")
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
        }
    }
}

private struct SessionRowView: View {
    let session: WorkoutSession

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
                Text("\(session.exercises.count) hareket")
                Text("·")
                Text("\(completedSets)/\(totalSets) set tamamlandı")
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
}
