import SwiftUI

struct StatisticsView: View {
    @Environment(LocalizationManager.self) private var lm

    var body: some View {
        ContentUnavailableView(
            lm["stats_coming_soon_title"],
            systemImage: "chart.bar.xaxis",
            description: Text(lm["stats_coming_soon_message"])
        )
    }
}

#Preview {
    StatisticsView()
        .environment(LocalizationManager())
}
