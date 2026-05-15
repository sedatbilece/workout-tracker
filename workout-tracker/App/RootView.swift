import SwiftUI

struct RootView: View {
    @AppStorage("appTheme") private var themeRaw: String = AppTheme.system.rawValue
    @Environment(LocalizationManager.self) private var lm

    private var colorScheme: ColorScheme? {
        (AppTheme(rawValue: themeRaw) ?? .system).colorScheme
    }

    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label(lm["tab_today"], systemImage: "calendar")
                }

            TemplatesView()
                .tabItem {
                    Label(lm["tab_templates"], systemImage: "list.bullet.clipboard")
                }

            StatsView()
                .tabItem {
                    Label(lm["tab_stats"], systemImage: "chart.bar.xaxis")
                }

            CalculationsView()
                .tabItem {
                    Label(lm["tab_calculations"], systemImage: "function")
                }

            ProfileView()
                .tabItem {
                    Label(lm["tab_profile"], systemImage: "person.crop.circle")
                }
        }
        .preferredColorScheme(colorScheme)
    }
}

#Preview {
    RootView()
        .environment(LocalizationManager())
}
