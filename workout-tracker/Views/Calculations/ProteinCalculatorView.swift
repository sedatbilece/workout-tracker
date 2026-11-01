import SwiftUI

struct ProteinCalculatorView: View {
    @Environment(LocalizationManager.self) private var lm
    @AppStorage(CalculationInputs.weightKey) private var weightKg = 0.0
    @AppStorage(CalculationInputs.proteinGoalKey) private var goal = ProteinGoal.active

    var body: some View {
        Form {
            Section {
                MeasurementField(title: lm["calc_weight"], unit: lm["set_weight_unit"], value: $weightKg)
                Picker(lm["calc_protein_goal"], selection: $goal) {
                    ForEach(ProteinGoal.allCases, id: \.self) { goal in
                        Text(lm[goal.labelKey]).tag(goal)
                    }
                }
            } header: {
                Text(lm["calc_section_inputs"])
            } footer: {
                Text(lm["calc_inputs_footer"])
            }

            Section {
                if let grams = BodyCalculations.proteinGrams(weightKg: weightKg, goal: goal) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(lm.format("calc_protein_per_day", rounded(grams.lowerBound), rounded(grams.upperBound)))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text(lm.format("calc_protein_per_kg", goal.gramsPerKg.lowerBound.oneDecimal, goal.gramsPerKg.upperBound.oneDecimal))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(lm.format("calc_protein_per_meal", rounded((grams.lowerBound + grams.upperBound) / 2 / 4)))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                    .animation(.snappy, value: grams.lowerBound)
                } else {
                    Text(lm["calc_enter_values"])
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(lm["calc_section_result"])
            } footer: {
                Text(lm["calc_protein_footer"])
            }
        }
        .navigationTitle(lm["calc_protein_title"])
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneButton(lm["common_done"])
    }

    private func rounded(_ grams: Double) -> String {
        "\(Int(grams.rounded()))"
    }
}

#Preview {
    NavigationStack {
        ProteinCalculatorView()
            .environment(LocalizationManager())
    }
}
