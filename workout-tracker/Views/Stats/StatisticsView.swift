import SwiftUI

struct StatisticsView: View {
    @Environment(LocalizationManager.self) private var lm
    @State private var section: Section = .workouts

    enum Section: Hashable {
        case exercises
        case workouts
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $section) {
                Text(lm["stats_segment_exercises"]).tag(Section.exercises)
                Text(lm["stats_segment_workouts"]).tag(Section.workouts)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            switch section {
            case .exercises:
                ContentUnavailableView(
                    lm["stats_coming_soon_title"],
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text(lm["stats_coming_soon_message"])
                )
            case .workouts:
                WorkoutProgressionListView()
            }
        }
    }
}

#Preview {
    StatisticsView()
        .environment(LocalizationManager())
}
