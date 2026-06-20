import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query private var allSessions: [WorkoutSession]
    @Environment(LocalizationManager.self) private var lm

    private var dayGroups: [(day: Date, sessions: [WorkoutSession])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: allSessions) { session in
            calendar.startOfDay(for: session.date)
        }
        return grouped
            .map { (day: $0.key, sessions: $0.value.sorted { $0.createdAt > $1.createdAt }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        Group {
            if dayGroups.isEmpty {
                ContentUnavailableView(
                    lm["history_empty_title"],
                    systemImage: "clock.arrow.circlepath",
                    description: Text(lm["history_empty_message"])
                )
            } else {
                List {
                    ForEach(dayGroups, id: \.day) { group in
                        let label = dayLabel(for: group.day)
                        if group.sessions.count == 1, let session = group.sessions.first {
                            NavigationLink {
                                WorkoutSessionDetailView(session: session)
                            } label: {
                                SingleDayRow(label: label, session: session)
                            }
                        } else {
                            NavigationLink {
                                DayWorkoutsListView(title: label, sessions: group.sessions)
                            } label: {
                                MultiDayRow(label: label, count: group.sessions.count)
                            }
                        }
                    }
                }
            }
        }
    }

    private func dayLabel(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return lm["history_today"] }
        if calendar.isDateInYesterday(day) { return lm["history_yesterday"] }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.resolve(lm.languageCode))
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        return formatter.string(from: day)
    }
}

private struct SingleDayRow: View {
    let label: String
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.headline)
            SessionSummaryRow(session: session)
        }
        .padding(.vertical, 4)
    }
}

private struct MultiDayRow: View {
    @Environment(LocalizationManager.self) private var lm
    let label: String
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.headline)
            Text(lm.format("history_workouts_count", count))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct SessionSummaryRow: View {
    @Environment(LocalizationManager.self) private var lm
    let session: WorkoutSession

    private var completedSets: Int {
        session.exercises.flatMap(\.sets).filter(\.isCompleted).count
    }

    private var totalSets: Int {
        session.exercises.flatMap(\.sets).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(session.templateNameSnapshot)
                    .font(.subheadline.weight(.medium))
                Text(session.createdAt.timeFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            HStack(spacing: 4) {
                Text(lm.format("today_exercises_count", session.exercises.count))
                Text("·")
                Text(lm.format("today_sets_completed", completedSets, totalSets))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
