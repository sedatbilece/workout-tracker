import SwiftUI

/// Shown after finishing the workout from the watch.
struct FinishedView: View {
    @Environment(WatchStore.self) private var store
    let summary: WatchStore.FinishedSummary

    var body: some View {
        let strings = store.strings
        ScrollView {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.green)
                Text(strings["watch_finished_title"])
                    .font(.headline)
                Text(summary.templateName)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                VStack(spacing: 4) {
                    SummaryRow(icon: "timer", text: Duration.seconds(summary.duration).formatted(.time(pattern: .hourMinuteSecond)))
                    SummaryRow(icon: "checkmark.circle", text: strings.format("watch_sets_done", summary.completedSets, summary.totalSets))
                    if let kcal = summary.activeEnergyKcal, kcal >= 1 {
                        SummaryRow(icon: "flame.fill", text: strings.format("watch_kcal", Int(kcal.rounded())))
                    }
                    if let heartRate = summary.averageHeartRate {
                        SummaryRow(icon: "heart.fill", text: strings.format("watch_avg_bpm", Int(heartRate.rounded())))
                    }
                }
                .padding(.vertical, 4)

                Button(strings["watch_done"]) {
                    store.dismissSummary()
                }
            }
        }
    }
}

private struct SummaryRow: View {
    let icon: String
    let text: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.body.monospacedDigit())
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
