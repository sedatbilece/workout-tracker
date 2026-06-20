import SwiftUI
import SwiftData
import Charts

struct WorkoutProgressionListView: View {
    @Query private var allSessions: [WorkoutSession]
    @Environment(LocalizationManager.self) private var lm

    private var groups: [WorkoutGroup] {
        let withWork = allSessions.filter { $0.completedSetCount > 0 }
        let grouped = Dictionary(grouping: withWork, by: { $0.templateNameSnapshot })
        let mapped: [WorkoutGroup] = grouped.map { name, sessions in
            let sorted = sessions.sorted { $0.date < $1.date }
            return WorkoutGroup(name: name, sessions: sorted)
        }
        return mapped.sorted { lhs, rhs in
            let l = lhs.sessions.last?.date ?? .distantPast
            let r = rhs.sessions.last?.date ?? .distantPast
            return l > r
        }
    }

    var body: some View {
        Group {
            if groups.isEmpty {
                ContentUnavailableView(
                    lm["stats_workouts_empty_title"],
                    systemImage: "chart.bar",
                    description: Text(lm["stats_workouts_empty_message"])
                )
            } else {
                List(groups) { group in
                    NavigationLink {
                        WorkoutProgressionDetailView(workoutName: group.name)
                    } label: {
                        WorkoutGroupRow(group: group)
                    }
                }
            }
        }
    }
}

private struct WorkoutGroup: Identifiable {
    let name: String
    let sessions: [WorkoutSession]
    var id: String { name }
}

private struct WorkoutGroupRow: View {
    @Environment(LocalizationManager.self) private var lm
    let group: WorkoutGroup

    private var sparkData: [Int] {
        Array(group.sessions.suffix(12).map(\.completedReps))
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(group.name)
                    .font(.headline)
                Text(lm.format("stats_times_count", group.sessions.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Sparkline(values: sparkData)
                .frame(width: 64, height: 28)
        }
        .padding(.vertical, 2)
    }
}

private struct Sparkline: View {
    let values: [Int]

    var body: some View {
        if values.count >= 2 {
            Chart(Array(values.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("i", index),
                    y: .value("reps", value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(.tint)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
        } else {
            Color.clear
        }
    }
}
