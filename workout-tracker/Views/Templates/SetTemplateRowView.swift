import SwiftUI

struct SetTemplateRowView: View {
    @Bindable var set: SetTemplate
    let index: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("Set \(index + 1)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)

            Spacer()

            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    StepperButton(icon: "minus") {
                        set.defaultKg = max(0, set.defaultKg - 2.5)
                    }
                    Text(formatKg(set.defaultKg))
                        .font(.subheadline.monospacedDigit())
                        .frame(width: 44, alignment: .center)
                    StepperButton(icon: "plus") {
                        set.defaultKg += 2.5
                    }
                }
                Text("kg")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    StepperButton(icon: "minus") {
                        set.defaultReps = max(1, set.defaultReps - 1)
                    }
                    Text("\(set.defaultReps)")
                        .font(.subheadline.monospacedDigit())
                        .frame(width: 28, alignment: .center)
                    StepperButton(icon: "plus") {
                        set.defaultReps = min(20, set.defaultReps + 1)
                    }
                }
                Text("tekrar")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func formatKg(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(value))"
            : String(format: "%.1f", value)
    }
}

private struct StepperButton: View {
    let icon: String
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
    }
}
