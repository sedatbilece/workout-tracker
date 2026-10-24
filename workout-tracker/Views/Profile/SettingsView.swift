import SwiftUI

// Profile → Settings: one row per group, each opening its own page.
struct SettingsView: View {
    @Environment(LocalizationManager.self) private var lm
    @AppStorage(LiveActivityService.enabledKey) private var liveActivityEnabled = true

    var body: some View {
        let lang = AppLanguage(rawValue: lm.languageCode) ?? .system
        List {
            Section {
                NavigationLink(destination: DataSettingsView()) {
                    Label(lm["settings_data_sync"], systemImage: "icloud")
                }
            }
            Section {
                NavigationLink(destination: LiveActivitySettingsView()) {
                    LabeledContent {
                        Text(lm[liveActivityEnabled ? "common_on" : "common_off"])
                    } label: {
                        Label(lm["settings_live_activity"], systemImage: "platter.filled.top.iphone")
                    }
                }
            }
            Section {
                NavigationLink(destination: LanguageSettingsView()) {
                    LabeledContent {
                        Text("\(lang.flag) \(lang == .system ? lm["language_system"] : lang.displayName)")
                    } label: {
                        Label(lm["profile_section_language"], systemImage: "globe")
                    }
                }
            }
        }
        .navigationTitle(lm["profile_section_settings"])
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(LocalizationManager())
    }
}
