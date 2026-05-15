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
