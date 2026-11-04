import SwiftUI

/// One segment per set (completed ones green, skipped ones gray, the next
/// one in the theme color); a plain bar when there are too many sets for
/// segments to stay readable. Drawn by the Live Activity and the watch app.
struct SetProgressBar: View {
    let statuses: [WorkoutSetStatus]
    let accent: Color
    var height: CGFloat = 5

    var body: some View {
        if statuses.count > 20 {
            ProgressView(value: Double(statuses.filter { $0 != .pending }.count), total: Double(max(statuses.count, 1)))
                .tint(.green)
        } else {
            let next = statuses.firstIndex(of: .pending)
            HStack(spacing: 3) {
                ForEach(statuses.indices, id: \.self) { i in
                    Capsule()
                        .fill(color(statuses[i], isNext: i == next))
                        .frame(height: height)
                }
            }
        }
    }

    private func color(_ status: WorkoutSetStatus, isNext: Bool) -> Color {
        switch status {
        case .completed: .green
        case .skipped: .gray
        case .pending: isNext ? accent : Color.secondary.opacity(0.3)
        }
    }
}
