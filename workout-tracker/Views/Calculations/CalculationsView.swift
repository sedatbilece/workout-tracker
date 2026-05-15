import SwiftUI

struct CalculationsView: View {
    @Environment(LocalizationManager.self) private var lm

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                lm["calculations_coming_soon_title"],
                systemImage: "function",
                description: Text(lm["calculations_coming_soon_message"])
            )
            .navigationTitle(lm["tab_calculations"])
        }
    }
}

#Preview {
    CalculationsView()
        .environment(LocalizationManager())
}
