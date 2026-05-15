import SwiftUI

enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var labelKey: String {
        switch self {
        case .system: return "theme_auto"
        case .light:  return "theme_light"
        case .dark:   return "theme_dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
