import SwiftUI

struct CalculationsView: View {
    @Environment(LocalizationManager.self) private var lm
    @AppStorage(CalculationInputs.weightKey) private var weightKg = 0.0
    @AppStorage(CalculationInputs.heightKey) private var heightCm = 0.0
    @AppStorage(CalculationInputs.proteinGoalKey) private var proteinGoal = ProteinGoal.active
    @AppStorage(CalculationInputs.exerciseMinutesKey) private var exerciseMinutes = 0

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: BMICalculatorView()) {
                        row(lm["calc_bmi_title"], icon: "figure.stand", color: .green, detail: bmiSummary ?? lm["calc_bmi_subtitle"])
                    }
                    NavigationLink(destination: ProteinCalculatorView()) {
                        row(lm["calc_protein_title"], icon: "fork.knife", color: .orange, detail: proteinSummary ?? lm["calc_protein_subtitle"])
                    }
                    NavigationLink(destination: WaterCalculatorView()) {
                        row(lm["calc_water_title"], icon: "drop.fill", color: .blue, detail: waterSummary ?? lm["calc_water_subtitle"])
                    }
                } footer: {
                    Text(lm["calc_disclaimer"])
                }
            }
            .navigationTitle(lm["tab_calculations"])
        }
    }

    private var bmiSummary: String? {
        guard let bmi = BodyCalculations.bmi(weightKg: weightKg, heightCm: heightCm) else { return nil }
        return lm.format("calc_bmi_value", bmi.oneDecimal) + " · " + lm[BMICategory(bmi: bmi).labelKey]
    }

    private var proteinSummary: String? {
        guard let grams = BodyCalculations.proteinGrams(weightKg: weightKg, goal: proteinGoal) else { return nil }
        return lm.format("calc_protein_per_day", "\(Int(grams.lowerBound.rounded()))", "\(Int(grams.upperBound.rounded()))")
    }

    private var waterSummary: String? {
        guard let ml = BodyCalculations.waterMl(weightKg: weightKg, exerciseMinutes: exerciseMinutes) else { return nil }
        return lm.format("calc_water_liters", (ml / 1000).oneDecimal)
    }

    private func row(_ title: String, icon: String, color: Color, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(color.gradient, in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CalculationsView()
        .environment(LocalizationManager())
}
