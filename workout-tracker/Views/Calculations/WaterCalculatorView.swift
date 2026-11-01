import SwiftUI

struct WaterCalculatorView: View {
    @Environment(LocalizationManager.self) private var lm
    @AppStorage(CalculationInputs.weightKey) private var weightKg = 0.0
    @AppStorage(CalculationInputs.exerciseMinutesKey) private var exerciseMinutes = 0

    var body: some View {
        Form {
            Section {
                MeasurementField(title: lm["calc_weight"], unit: lm["set_weight_unit"], value: $weightKg)
                Stepper(value: $exerciseMinutes, in: 0...240, step: 15) {
                    HStack {
                        Text(lm["calc_water_exercise"])
                        Spacer()
                        Text(lm.format("calc_water_minutes", exerciseMinutes))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text(lm["calc_section_inputs"])
            } footer: {
                Text(lm["calc_inputs_footer"])
            }

            Section {
                if let ml = BodyCalculations.waterMl(weightKg: weightKg, exerciseMinutes: exerciseMinutes) {
                    let glasses = BodyCalculations.glasses(waterMl: ml)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(lm.format("calc_water_liters", (ml / 1000).oneDecimal))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text(lm.format("calc_water_glasses", glasses))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        GlassRow(count: glasses)
                    }
                    .padding(.vertical, 6)
                    .animation(.snappy, value: ml)
                } else {
                    Text(lm["calc_enter_values"])
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(lm["calc_section_result"])
            } footer: {
                Text(lm["calc_water_footer"])
            }
        }
        .navigationTitle(lm["calc_water_title"])
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneButton(lm["common_done"])
    }
}

/// One glass icon per 250 ml, wrapping onto as many lines as needed.
private struct GlassRow: View {
    let count: Int

    private let columns = [GridItem(.adaptive(minimum: 22), spacing: 6)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
            ForEach(0..<min(count, 40), id: \.self) { _ in
                Image(systemName: "waterbottle.fill")
                    .font(.title3)
                    .foregroundStyle(.blue.gradient)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    NavigationStack {
        WaterCalculatorView()
            .environment(LocalizationManager())
    }
}
