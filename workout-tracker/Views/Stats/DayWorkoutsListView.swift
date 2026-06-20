import SwiftUI

struct DayWorkoutsListView: View {
    let title: String
    let sessions: [WorkoutSession]

    var body: some View {
        List {
            ForEach(sessions) { session in
                NavigationLink {
                    WorkoutSessionDetailView(session: session)
                } label: {
                    SessionSummaryRow(session: session)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
