import Foundation

// The extension can't read the app's LocalizationManager, so the Live
// Activity carries the resolved language code and strings are looked up in
// this extension's own Localizable.xcstrings, falling back to Turkish.
struct WidgetStrings {
    private let bundle: Bundle

    init(languageCode: String) {
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
