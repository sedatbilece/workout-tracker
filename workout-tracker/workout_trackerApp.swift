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
