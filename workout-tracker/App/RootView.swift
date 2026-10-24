import SwiftUI
import SwiftData
import CoreData

struct RootView: View {
    @AppStorage("appTheme") private var themeRaw: String = AppTheme.system.rawValue
    @Environment(LocalizationManager.self) private var lm
    @Environment(TabRouter.self) private var tabRouter
    @Environment(\.modelContext) private var modelContext

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
        .task {
            await cleanUpSyncedChanges()
        }
    }

    // Records arriving from iCloud may come from an older app version or be
    // duplicates of a backup restored on another device.
    private func cleanUpSyncedChanges() async {
        guard CloudSync.isActive else { return }
        let changes = NotificationCenter.default.notifications(named: .NSPersistentStoreRemoteChange)
        var lastRun = Date.distantPast
        for await _ in changes {
            // Imports arrive in bursts; handle them at most every few seconds.
            guard Date().timeIntervalSince(lastRun) > 5 else { continue }
            try? await Task.sleep(for: .seconds(2))
            DataMigrator.run(context: modelContext)
            DuplicateCleaner.run(context: modelContext)
            lastRun = Date()
        }
    }
}

#Preview {
    RootView()
        .environment(LocalizationManager())
}
