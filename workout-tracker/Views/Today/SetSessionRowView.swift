import SwiftUI
import SwiftData

struct SetSessionRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var lm
    @Bindable var set: SetSession
    let index: Int
    var onDuplicate: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    var body: some View {
        SwipeRow(leading: leadingActions, trailing: trailingActions) {
            HStack(spacing: 12) {
                Text(lm.format("set_label", index + 1))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 50, alignment: .leading)
                    .strikethrough(isDone, color: .secondary)

                Spacer()

                VStack(spacing: 2) {
                    HStack(spacing: 6) {
                        StepperButton(icon: "minus", disabled: isDone) {
                            set.kg = max(0, set.kg - 2.5)
                        }
                        Text(formatKg(set.kg))
                            .font(.subheadline.monospacedDigit())
                            .frame(width: 44, alignment: .center)
                        StepperButton(icon: "plus", disabled: isDone) {
                            set.kg += 2.5
                        }
                    }
                    Text(lm["set_weight_unit"])
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 2) {
                    HStack(spacing: 6) {
                        StepperButton(icon: "minus", disabled: isDone) {
                            set.reps = max(1, set.reps - 1)
                        }
                        Text("\(set.reps)")
                            .font(.subheadline.monospacedDigit())
                            .frame(width: 28, alignment: .center)
                        StepperButton(icon: "plus", disabled: isDone) {
                            set.reps = min(20, set.reps + 1)
                        }
                    }
                    Text(lm["set_reps_unit"])
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Button {
                    completeSet()
                } label: {
                    statusIcon
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(lm[set.isSkipped ? "set_skipped" : "set_complete"])
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .opacity(set.isSkipped ? 0.45 : set.isCompleted ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isDone)
        }
    }

    private var isDone: Bool { self.set.isCompleted || self.set.isSkipped }

    @ViewBuilder
    private var statusIcon: some View {
        if set.isCompleted {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        } else if set.isSkipped {
            Image(systemName: "forward.end.circle.fill").foregroundStyle(.secondary)
        } else {
            Image(systemName: "circle").foregroundStyle(.secondary)
        }
    }

    // Full swipe left completes the set, full swipe right skips it; a done
    // set only offers Undo (plus Duplicate, and Delete if it was skipped).
    private var leadingActions: [SwipeAction] {
        guard !isDone else { return [] }
        return [SwipeAction(title: lm["set_skip"], icon: "forward.end.fill", color: .gray, fullSwipe: true) { skipSet() }]
    }

    private var trailingActions: [SwipeAction] {
        var actions: [SwipeAction] = []
        if let onDuplicate {
            actions.append(SwipeAction(title: lm["common_duplicate"], icon: "plus.rectangle.on.rectangle", color: .blue, perform: onDuplicate))
        }
        if isDone {
            actions.append(SwipeAction(title: lm["common_undo"], icon: "arrow.uturn.backward", color: .orange) { undo() })
        }
        if let onDelete, !set.isCompleted {
            actions.append(SwipeAction(title: lm["common_delete"], icon: "trash", color: .red, perform: onDelete))
        }
        if !isDone {
            actions.append(SwipeAction(title: lm["set_complete"], icon: "checkmark", color: .green, fullSwipe: true) { completeSet() })
        }
        return actions
    }

    private func formatKg(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(value))"
            : String(format: "%.1f", value)
    }

    private func completeSet() {
        SessionActions.complete(set, context: modelContext)
    }

    private func skipSet() {
        SessionActions.skip(set)
    }

    private func undo() {
        SessionActions.undo(set, context: modelContext)
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
