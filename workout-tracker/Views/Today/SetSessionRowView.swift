import SwiftUI
import SwiftData

struct SetSessionRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var set: SetSession
    let index: Int
    var onDuplicate: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    var body: some View {
        SwipeRow(
            onDuplicate: set.isCompleted ? nil : onDuplicate,
            onDelete: set.isCompleted ? nil : onDelete
        ) {
            HStack(spacing: 12) {
                Text("Set \(index + 1)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 50, alignment: .leading)
                    .strikethrough(set.isCompleted, color: .secondary)

                Spacer()

                VStack(spacing: 2) {
                    HStack(spacing: 6) {
                        StepperButton(icon: "minus", disabled: set.isCompleted) {
                            set.kg = max(0, set.kg - 2.5)
                        }
                        Text(formatKg(set.kg))
                            .font(.subheadline.monospacedDigit())
                            .frame(width: 44, alignment: .center)
                        StepperButton(icon: "plus", disabled: set.isCompleted) {
                            set.kg += 2.5
                        }
                    }
                    Text("kg")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 2) {
                    HStack(spacing: 6) {
                        StepperButton(icon: "minus", disabled: set.isCompleted) {
                            set.reps = max(1, set.reps - 1)
                        }
                        Text("\(set.reps)")
                            .font(.subheadline.monospacedDigit())
                            .frame(width: 28, alignment: .center)
                        StepperButton(icon: "plus", disabled: set.isCompleted) {
                            set.reps = min(20, set.reps + 1)
                        }
                    }
                    Text("tekrar")
                        .font(.caption2)
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
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .opacity(set.isCompleted ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: set.isCompleted)
        }
    }

    private func formatKg(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(value))"
            : String(format: "%.1f", value)
    }

    private func completeSet() {
        set.isCompleted = true
        set.completedAt = Date()
        TemplateDefaultUpdater.syncIfNeeded(setSession: set, context: modelContext)
    }
}

private struct StepperButton: View {
    let icon: String
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .frame(width: 26, height: 26)
                .background(Color(.tertiarySystemFill))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}
