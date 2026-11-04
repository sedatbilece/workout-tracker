import SwiftUI

struct WatchRootView: View {
    @Environment(WatchStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    private struct MeasureKey: Equatable {
        var sessionUUID: UUID?
        var isActive: Bool
    }

    var body: some View {
        @Bindable var store = store
        NavigationStack(path: $store.path) {
            content
                .navigationDestination(for: UUID.self) { uuid in
                    ExerciseDetailView(exerciseUUID: uuid)
                }
        }
        .tint(store.snapshot?.accent.color ?? AppAccent.defaultValue.color)
        // A workout session can only start in the foreground; once running
        // it keeps going until the workout ends (WatchStore stops it).
        .task(id: MeasureKey(sessionUUID: store.snapshot?.sessionUUID, isActive: scenePhase == .active)) {
            guard scenePhase == .active, let uuid = store.snapshot?.sessionUUID else { return }
            await store.metrics.start(for: uuid)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot = store.snapshot {
            ExerciseListView(snapshot: snapshot)
        } else if let summary = store.finishedSummary {
            FinishedView(summary: summary)
        } else if !store.hasLoaded {
            ProgressView()
        } else {
            IdleView()
        }
    }
}

private struct IdleView: View {
    @Environment(WatchStore.self) private var store

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 36))
                .foregroundStyle(.tint)
            Text(store.strings["watch_no_workout_title"])
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(store.strings["watch_no_workout_message"])
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 8)
    }
}
