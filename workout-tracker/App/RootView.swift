import SwiftUI

struct RootView: View {
    @AppStorage("appTheme") private var themeRaw: String = AppTheme.system.rawValue

    private var colorScheme: ColorScheme? {
        (AppTheme(rawValue: themeRaw) ?? .system).colorScheme
    }

    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Bugün", systemImage: "calendar")
                }

            TemplatesView()
                .tabItem {
                    Label("Şablonlar", systemImage: "list.bullet.clipboard")
                }

            StatsView()
                .tabItem {
                    Label("İstatistikler", systemImage: "chart.bar.xaxis")
                }

            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.crop.circle")
                }
        }
        .preferredColorScheme(colorScheme)
    }
}

#Preview {
    RootView()
}
