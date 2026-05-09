import SwiftUI

struct SetSessionRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var set: SetSession
    let index: Int

    @FocusState private var kgFocused: Bool
    @FocusState private var repsFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text("Set \(index + 1)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)
                .strikethrough(set.isCompleted, color: .secondary)

            Spacer()

            HStack(spacing: 4) {
                TextField("0", value: $set.kg, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused($kgFocused)
                    .frame(width: 60)
                    .disabled(set.isCompleted)
                Text("kg")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 4) {
                TextField("0", value: $set.reps, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .focused($repsFocused)
                    .frame(width: 48)
                    .disabled(set.isCompleted)
                Text("tekrar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                completeSet()
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(set.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
        .opacity(set.isCompleted ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: set.isCompleted)
    }

    private func completeSet() {
        kgFocused = false
        repsFocused = false
        set.isCompleted = true
        set.completedAt = Date()
        TemplateDefaultUpdater.syncIfNeeded(setSession: set, context: modelContext)
    }
}
