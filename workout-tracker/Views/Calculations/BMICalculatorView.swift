import SwiftUI

struct BMICalculatorView: View {
    @Environment(LocalizationManager.self) private var lm
    @AppStorage(CalculationInputs.weightKey) private var weightKg = 0.0
    @AppStorage(CalculationInputs.heightKey) private var heightCm = 0.0

    private var bmi: Double? {
        BodyCalculations.bmi(weightKg: weightKg, heightCm: heightCm)
    }

    var body: some View {
        Form {
            Section {
                MeasurementField(title: lm["calc_weight"], unit: lm["set_weight_unit"], value: $weightKg)
                MeasurementField(title: lm["calc_height"], unit: lm["calc_unit_cm"], value: $heightCm)
            } header: {
                Text(lm["calc_section_inputs"])
            } footer: {
                Text(lm["calc_inputs_footer"])
            }

            Section {
                if let bmi {
                    let category = BMICategory(bmi: bmi)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(bmi.oneDecimal)
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .contentTransition(.numericText())
                            Text(lm[category.labelKey])
                                .font(.headline)
                                .foregroundStyle(category.color)
                        }
                        BMIScale(bmi: bmi)
                        if let range = BodyCalculations.healthyWeightRange(heightCm: heightCm) {
                            Text(lm.format("calc_bmi_healthy_range", range.lowerBound.oneDecimal, range.upperBound.oneDecimal))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                    .animation(.snappy, value: bmi)
                } else {
                    Text(lm["calc_enter_values"])
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(lm["calc_section_result"])
            } footer: {
                Text(lm["calc_bmi_footer"])
            }
        }
        .navigationTitle(lm["calc_bmi_title"])
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneButton(lm["common_done"])
    }
}

/// Colored bands from BMI 15 to 40 with a marker at the current value.
private struct BMIScale: View {
    let bmi: Double

    private static let lower = 15.0
    private static let upper = 40.0

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                HStack(spacing: 2) {
                    ForEach(BMICategory.allCases, id: \.self) { category in
                        Capsule()
                            .fill(category.color.opacity(0.75))
                            .frame(width: max(0, width * share(of: category) - 2))
                    }
                }
                .frame(height: 8)

                Circle()
                    .fill(.background)
                    .stroke(BMICategory(bmi: bmi).color, lineWidth: 3)
                    .frame(width: 16, height: 16)
                    .offset(x: width * position(of: bmi) - 8)
            }
            .frame(height: 16)
        }
        .frame(height: 16)
        .accessibilityHidden(true)
    }

    private func position(of value: Double) -> Double {
        (min(max(value, Self.lower), Self.upper) - Self.lower) / (Self.upper - Self.lower)
    }

    private func share(of category: BMICategory) -> Double {
        position(of: category.range.upperBound) - position(of: category.range.lowerBound)
    }
}

#Preview {
    NavigationStack {
        BMICalculatorView()
            .environment(LocalizationManager())
    }
}
