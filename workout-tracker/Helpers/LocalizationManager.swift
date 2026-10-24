import Foundation
import Observation

@Observable
final class LocalizationManager {
    var languageCode: String {
        didSet {
            UserDefaults.standard.set(languageCode, forKey: "appLanguage")
            refreshBundle()
        }
    }

    private(set) var bundle: Bundle = .main

    init() {
        let code = UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
        languageCode = code
        bundle = Self.loadBundle(for: code)
    }

    subscript(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: nil)
    }

    func format(_ key: String, _ args: CVarArg...) -> String {
        String(format: self[key], arguments: args)
    }

    /// Workout duration as "45 sn" / "23 dk 15 sn" / "1 sa 5 dk 12 sn" in the app language.
    func duration(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let hours = total / 3600
        let minutes = total % 3600 / 60
        let seconds = total % 60
        if hours > 0 {
            return format("duration_hours_minutes_seconds", hours, minutes, seconds)
        }
        if minutes > 0 {
            return format("duration_minutes_seconds", minutes, seconds)
        }
        return format("duration_seconds", seconds)
    }

    private func refreshBundle() {
        bundle = Self.loadBundle(for: languageCode)
    }

    private static func loadBundle(for code: String) -> Bundle {
        let resolved = resolve(code)
        if let path = Bundle.main.path(forResource: resolved, ofType: "lproj"),
           let b = Bundle(path: path) {
            return b
        }
        if let path = Bundle.main.path(forResource: "tr", ofType: "lproj"),
           let b = Bundle(path: path) {
            return b
        }
        return .main
    }

    static func resolve(_ code: String) -> String {
        if code == "system" {
            let lang = Locale.preferredLanguages.first ?? "tr"
            let prefix = String(lang.prefix(2))
            return ["tr", "en", "es", "ru"].contains(prefix) ? prefix : "tr"
        }
        return code
    }
}
