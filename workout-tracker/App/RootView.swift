import SwiftUI

struct RootView: View {
    @AppStorage("appTheme") private var themeRaw: String = AppTheme.system.rawValue
    @Environment(LocalizationManager.self) private var lm
    @Environment(TabRouter.self) private var tabRouter

    private var colorScheme: ColorScheme? {
        (AppTheme(rawValue: themeRaw) ?? .system).colorScheme
    }

    var body: some View {
        TabView(selection: Bindable(tabRouter).selectedTab) {
            TodayView()
                .tabItem {
                    Label(lm["tab_today"], systemImage: "calendar")
                }
                .tag(0)

            TemplatesView()
                .tabItem {
                    Label(lm["tab_templates"], systemImage: "list.bullet.clipboard")
                }
                .tag(1)

            StatsView()
                .tabItem {
                    Label(lm["tab_stats"], systemImage: "chart.bar.xaxis")
                }
                .tag(2)

            CalculationsView()
                .tabItem {
                    Label(lm["tab_calculations"], systemImage: "function")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label(lm["tab_profile"], systemImage: "person.crop.circle")
                }
                .tag(4)
        }
        .preferredColorScheme(colorScheme)
    }
}

#Preview {
    RootView()
        .environment(LocalizationManager())
}
