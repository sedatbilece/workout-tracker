import SwiftUI

/// Formulas behind the Calculations tab. Inputs are metric (kg, cm, minutes);
/// a zero input means "not entered yet" and yields no result.
enum BodyCalculations {
    static let glassMl = 250.0

    static func bmi(weightKg: Double, heightCm: Double) -> Double? {
        guard weightKg > 0, heightCm > 0 else { return nil }
        let meters = heightCm / 100
        return weightKg / (meters * meters)
    }

    /// Weight range that puts the BMI in the normal band for this height.
    static func healthyWeightRange(heightCm: Double) -> ClosedRange<Double>? {
        guard heightCm > 0 else { return nil }
        let squared = pow(heightCm / 100, 2)
        return (BMICategory.normal.range.lowerBound * squared)...(BMICategory.normal.range.upperBound * squared)
    }

    static func proteinGrams(weightKg: Double, goal: ProteinGoal) -> ClosedRange<Double>? {
        guard weightKg > 0 else { return nil }
        return (goal.gramsPerKg.lowerBound * weightKg)...(goal.gramsPerKg.upperBound * weightKg)
    }

    /// 35 ml per kg of body weight, plus 350 ml for every 30 minutes of exercise.
    static func waterMl(weightKg: Double, exerciseMinutes: Int) -> Double? {
        guard weightKg > 0 else { return nil }
        return weightKg * 35 + Double(exerciseMinutes) / 30 * 350
    }

    static func glasses(waterMl: Double) -> Int {
        Int((waterMl / glassMl).rounded(.up))
    }
}

/// WHO adult BMI bands.
enum BMICategory: CaseIterable {
    case underweight, normal, overweight, obese

    init(bmi: Double) {
        self = Self.allCases.first { bmi < $0.range.upperBound } ?? .obese
    }

    var range: Range<Double> {
        switch self {
        case .underweight: 0..<18.5
        case .normal: 18.5..<25
        case .overweight: 25..<30
        case .obese: 30..<Double.greatestFiniteMagnitude
        }
    }

    var labelKey: String {
        switch self {
        case .underweight: "calc_bmi_underweight"
        case .normal: "calc_bmi_normal"
        case .overweight: "calc_bmi_overweight"
        case .obese: "calc_bmi_obese"
        }
    }

    var color: Color {
        switch self {
        case .underweight: .blue
        case .normal: .green
        case .overweight: .orange
        case .obese: .red
        }
    }
}

/// Daily protein per kg of body weight, following sports nutrition ranges.
enum ProteinGoal: String, CaseIterable {
    case sedentary, active, muscle, cut

    var gramsPerKg: ClosedRange<Double> {
        switch self {
        case .sedentary: 0.8...1.0
        case .active: 1.2...1.6
        case .muscle: 1.6...2.2
        case .cut: 1.8...2.4
        }
    }

    var labelKey: String { "calc_protein_goal_\(rawValue)" }
}
