import SwiftUI

struct RootView: View {
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
        }
    }
}

#Preview {
    RootView()
}
