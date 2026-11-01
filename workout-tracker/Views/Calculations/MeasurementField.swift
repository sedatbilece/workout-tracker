import SwiftUI

/// UserDefaults keys for the calculator inputs. Weight and height are the
/// profile's own (Profile → edit), so every calculator starts from them and
/// a change in either place shows up in both.
enum CalculationInputs {
    static let weightKey = "profileWeightKg"
    static let heightKey = "profileHeightCm"
    static let proteinGoalKey = "calcProteinGoal"
    static let exerciseMinutesKey = "calcExerciseMinutes"
}

/// A numeric form row ("Kilo ... 72,5 kg") that writes to `value` on every
/// keystroke, so results update while typing. Empty or invalid text is 0.
struct MeasurementField: View {
    let title: String
    let unit: String
    @Binding var value: Double

    @State private var text = ""

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(maxWidth: 100)
                .onChange(of: text) { _, newText in
                    value = Double(newText.replacingOccurrences(of: ",", with: ".")) ?? 0
                }
            Text(unit)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            guard value > 0 else { return }
            text = NumberFormatter.workoutWeight.string(from: value as NSNumber) ?? ""
        }
    }
}

extension View {
    /// Decimal pads have no return key; this adds a Done button above the keyboard.
    func keyboardDoneButton(_ title: String) -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(title) {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .bold()
            }
        }
    }
}

extension Double {
    /// One decimal place, in the device's number style.
    var oneDecimal: String {
        NumberFormatter.workoutWeight.string(from: self as NSNumber) ?? String(format: "%.1f", self)
    }
}
