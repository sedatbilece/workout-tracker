import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system  = "system"
    case turkish = "tr"
    case english = "en"
    case spanish = "es"
    case russian = "ru"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:  return "Sistem Dili"
        case .turkish: return "Türkçe"
        case .english: return "English"
        case .spanish: return "Español"
        case .russian: return "Русский"
        }
    }

    var flag: String {
        switch self {
        case .system:  return "🌐"
        case .turkish: return "🇹🇷"
        case .english: return "🇺🇸"
        case .spanish: return "🇪🇸"
        case .russian: return "🇷🇺"
        }
    }
}
