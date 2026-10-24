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
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            DataMigrator.run(context: container.mainContext)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
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
