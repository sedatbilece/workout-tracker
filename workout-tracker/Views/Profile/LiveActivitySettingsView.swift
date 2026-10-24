import SwiftUI
import ActivityKit

// Settings → Lock Screen & Dynamic Island. `LiveActivitySync` reads the same
// setting and ends the running workout's card as soon as it is turned off.
struct LiveActivitySettingsView: View {
    @AppStorage(LiveActivityService.enabledKey) private var liveActivityEnabled = true
    @Environment(LocalizationManager.self) private var lm
    @Environment(\.scenePhase) private var scenePhase
    @State private var systemAllowsActivities = ActivityAuthorizationInfo().areActivitiesEnabled

    var body: some View {
        List {
            Section {
                Toggle(isOn: $liveActivityEnabled) {
                    Label(lm["settings_live_activity_toggle"], systemImage: "platter.filled.top.iphone")
                }
                if liveActivityEnabled && !systemAllowsActivities {
                    Label(lm["settings_live_activity_system_off"], systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            } footer: {
                Text(lm["settings_live_activity_footer"])
            }
        }
        .navigationTitle(lm["settings_live_activity"])
        .navigationBarTitleDisplayMode(.inline)
        // The system switch lives in iPhone Settings; re-check on return.
        .onChange(of: scenePhase) {
            systemAllowsActivities = ActivityAuthorizationInfo().areActivitiesEnabled
        }
    }
}

#Preview {
    NavigationStack {
        LiveActivitySettingsView()
            .environment(LocalizationManager())
    }
}
