import SwiftUI
import SwiftData

struct TodayView: View {
    @Query private var allSessions: [WorkoutSession]
    @Environment(\.modelContext) private var modelContext
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
                            .contextMenu {
                                Button(role: .destructive) {
                                    sessionToDelete = session
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
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
            .confirmationDialog(
                "Antrenmanı sil",
                isPresented: Binding(
                    get: { sessionToDelete != nil },
                    set: { if !$0 { sessionToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Sil", role: .destructive) {
                    if let session = sessionToDelete {
                        modelContext.delete(session)
                    }
                    sessionToDelete = nil
                }
                Button("İptal", role: .cancel) {
                    sessionToDelete = nil
                }
            } message: {
                if let name = sessionToDelete?.templateNameSnapshot {
                    Text("\"\(name)\" antrenmanı kalıcı olarak silinecek.")
                }
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
