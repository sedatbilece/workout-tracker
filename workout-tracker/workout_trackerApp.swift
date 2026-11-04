import SwiftUI
import SwiftData

@main
struct workout_trackerApp: App {
    @State private var lm = LocalizationManager()
    @State private var tabRouter = TabRouter()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutTemplate.self,
            ExerciseTemplate.self,
            SetTemplate.self,
            WorkoutSession.self,
            ExerciseSession.self,
            SetSession.self,
        ])
        let container = CloudSync.makeContainer(schema: schema)
        DataMigrator.run(context: container.mainContext)
        DuplicateCleaner.run(context: container.mainContext)
        // Early, so a command from the watch that woke the app is received.
        WatchSyncService.shared.activate(container: container)
        return container
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(lm)
                .environment(tabRouter)
        }
        .modelContainer(sharedModelContainer)
    }
}
