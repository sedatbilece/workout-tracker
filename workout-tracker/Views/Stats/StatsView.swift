import SwiftUI

struct StatsView: View {
    @Environment(LocalizationManager.self) private var lm

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                lm["stats_coming_soon_title"],
                systemImage: "chart.bar.xaxis",
                description: Text(lm["stats_coming_soon_message"])
            )
            .navigationTitle(lm["tab_stats"])
        }
    }
}

#Preview {
    StatsView()
        .environment(LocalizationManager())
}
