import SwiftUI
import SwiftData

struct SetSessionRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var set: SetSession
    let index: Int
    var onDuplicate: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    @FocusState private var kgFocused: Bool
    @FocusState private var repsFocused: Bool
    @State private var kgText = ""
    @State private var repsText = ""

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

                HStack(spacing: 4) {
                    TextField("0", text: $kgText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused($kgFocused)
                        .frame(width: 60)
                        .disabled(set.isCompleted)
                        .onChange(of: kgFocused) { _, focused in
                            if focused {
                                kgText = ""
                            } else {
                                let parsed = Double(kgText.replacingOccurrences(of: ",", with: "."))
                                set.kg = parsed ?? set.kg
                                kgText = formatKg(set.kg)
                            }
                        }
                    Text("kg")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    TextField("0", text: $repsText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .focused($repsFocused)
                        .frame(width: 48)
                        .disabled(set.isCompleted)
                        .onChange(of: repsFocused) { _, focused in
                            if focused {
                                repsText = ""
                            } else {
                                set.reps = Int(repsText) ?? set.reps
                                repsText = "\(set.reps)"
                            }
                        }
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
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .opacity(set.isCompleted ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: set.isCompleted)
        }
        .onAppear {
            kgText = formatKg(set.kg)
            repsText = "\(set.reps)"
        }
    }

    private func formatKg(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(value))"
            : String(format: "%.1f", value)
    }

    private func completeSet() {
        if let v = Double(kgText.replacingOccurrences(of: ",", with: ".")) { set.kg = v }
        if let v = Int(repsText) { set.reps = v }
        kgFocused = false
        repsFocused = false
        set.isCompleted = true
        set.completedAt = Date()
        TemplateDefaultUpdater.syncIfNeeded(setSession: set, context: modelContext)
    }
}
