import Foundation

// The widget extension and the watch app can't read the app's
// LocalizationManager, so the Live Activity / watch snapshot carries the
// resolved language code and strings are looked up in the target's own
// Localizable.xcstrings, falling back to Turkish.
struct LocalizedStrings {
    let languageCode: String
    private let bundle: Bundle

    init(languageCode: String) {
        self.languageCode = languageCode
        bundle = Self.loadBundle(for: languageCode)
    }

    subscript(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: nil)
    }

    func format(_ key: String, _ args: CVarArg...) -> String {
        String(format: self[key], arguments: args)
    }

    /// "80 kg × 8", weight formatted like the rest of the app.
    func weightReps(kg: Double, reps: Int) -> String {
        let weight = NumberFormatter.workoutWeight.string(from: NSNumber(value: kg)) ?? "\(kg)"
        return format("live_weight_reps", weight, reps)
    }

    private static func loadBundle(for code: String) -> Bundle {
        for candidate in [code, "tr"] {
            if let path = Bundle.main.path(forResource: candidate, ofType: "lproj"),
               let b = Bundle(path: path) {
                return b
            }
        }
        return .main
    }
}
