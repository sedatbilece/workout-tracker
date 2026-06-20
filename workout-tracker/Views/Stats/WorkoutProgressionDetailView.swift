import SwiftUI
import SwiftData
import Charts

struct WorkoutProgressionDetailView: View {
    let workoutName: String
    @Query private var sessionsForName: [WorkoutSession]
    @Environment(LocalizationManager.self) private var lm
    @State private var range: StatsTimeRange = .month3

    init(workoutName: String) {
        self.workoutName = workoutName
        let name = workoutName
        _sessionsForName = Query(
            filter: #Predicate<WorkoutSession> { $0.templateNameSnapshot == name },
            sort: \.date,
            order: .forward
        )
    }

    // Sessions in range that actually have completed work, oldest → newest.
    private var stats: [SessionStat] {
        sessionsForName
            .filter { $0.completedSetCount > 0 && range.contains($0.date) }
            .map { SessionStat(id: $0.persistentModelID, date: $0.date, setCount: $0.completedSetCount, reps: $0.completedReps) }
    }

    private var breakdown: [ExerciseBreakdown] {
        var map: [String: ExerciseBreakdown] = [:]
        for session in sessionsForName where session.completedSetCount > 0 && range.contains(session.date) {
            for exercise in session.exercises {
                let done = exercise.completedSets
                guard !done.isEmpty else { continue }
                var entry = map[exercise.nameSnapshot]
                    ?? ExerciseBreakdown(name: exercise.nameSnapshot, icon: exercise.iconNameSnapshot, setCount: 0, reps: 0)
                entry.setCount += done.count
                entry.reps += done.reduce(0) { $0 + $1.reps }
                map[exercise.nameSnapshot] = entry
            }
        }
        return map.values.sorted { $0.setCount > $1.setCount }
    }

    private var avgSets: Int {
        guard !stats.isEmpty else { return 0 }
        return Int((Double(stats.reduce(0) { $0 + $1.setCount }) / Double(stats.count)).rounded())
    }

    private var avgReps: Int {
        guard !stats.isEmpty else { return 0 }
        return Int((Double(stats.reduce(0) { $0 + $1.reps }) / Double(stats.count)).rounded())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                rangePicker
                kpiRow
                fluctuationCard
                if !breakdown.isEmpty { breakdownCard }
                if !stats.isEmpty { historyCard }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(workoutName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var rangePicker: some View {
        HStack(spacing: 8) {
            ForEach(StatsTimeRange.allCases) { item in
                RangePill(
                    title: lm[item.labelKey],
                    isSelected: range == item
                ) {
                    range = item
                }
            }
        }
    }

    private var kpiRow: some View {
        HStack(spacing: 8) {
            kpiTile(value: "\(stats.count)", label: lm["stats_kpi_times"])
            kpiTile(value: "\(avgSets)", label: lm["stats_kpi_avg_sets"])
            kpiTile(value: "\(avgReps)", label: lm["stats_kpi_avg_reps"])
        }
    }

    private func kpiTile(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var fluctuationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(lm["stats_set_rep_fluctuation"])
                .font(.headline)

            if stats.isEmpty {
                Text(lm["stats_no_data_in_range"])
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                Text(lm["stats_chart_reps"])
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Chart(stats) { stat in
                    BarMark(
                        x: .value("date", stat.date, unit: .day),
                        y: .value("reps", stat.reps)
                    )
                    .foregroundStyle(Color.purple.opacity(0.55))
                }
                .frame(height: 110)
                .chartXAxis(.hidden)

                Text(lm["stats_chart_sets"])
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Chart(stats) { stat in
                    LineMark(
                        x: .value("date", stat.date, unit: .day),
                        y: .value("sets", stat.setCount)
                    )
                    .foregroundStyle(Color.orange)
                    PointMark(
                        x: .value("date", stat.date, unit: .day),
                        y: .value("sets", stat.setCount)
                    )
                    .foregroundStyle(Color.orange)
                }
                .frame(height: 80)
                .chartXAxis(.hidden)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var breakdownCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(lm["stats_exercise_breakdown"])
                .font(.headline)
                .padding(.bottom, 8)
            ForEach(Array(breakdown.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: 10) {
                    Image(systemName: item.icon)
                        .font(.callout)
                        .foregroundStyle(.tint)
                        .frame(width: 24)
                    Text(item.name)
                        .font(.subheadline)
                    Spacer()
                    Text(lm.format("stats_sets_reps_format", item.setCount, item.reps))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                if index < breakdown.count - 1 {
                    Divider()
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(lm["stats_session_history"])
                .font(.headline)
                .padding(.bottom, 8)
            ForEach(Array(stats.reversed().enumerated()), id: \.element.id) { index, stat in
                HStack {
                    Text(stat.date.shortFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(lm.format("stats_sets_reps_format", stat.setCount, stat.reps))
                        .font(.caption)
                }
                .padding(.vertical, 8)
                if index < stats.count - 1 {
                    Divider()
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct RangePill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(background)
                .foregroundStyle(foreground)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var background: Color {
        isSelected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground)
    }

    private var foreground: Color {
        isSelected ? Color.accentColor : Color.secondary
    }
}

private struct SessionStat: Identifiable {
    let id: PersistentIdentifier
    let date: Date
    let setCount: Int
    let reps: Int
}

private struct ExerciseBreakdown: Identifiable {
    let name: String
    let icon: String
    var setCount: Int
    var reps: Int
    var id: String { name }
}
