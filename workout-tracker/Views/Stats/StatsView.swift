import SwiftUI

struct StatsView: View {
    @Environment(LocalizationManager.self) private var lm
    @State private var selection: Segment = .history

    enum Segment: Hashable {
        case history
        case statistics
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selection) {
                    Text(lm["history_segment"]).tag(Segment.history)
                    Text(lm["statistics_segment"]).tag(Segment.statistics)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                switch selection {
                case .history:
                    HistoryView()
                case .statistics:
                    StatisticsView()
                }
            }
            .navigationTitle(lm["tab_stats"])
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
        }
    }
}

#Preview {
    StatsView()
        .environment(LocalizationManager())
}
