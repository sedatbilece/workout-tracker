import SwiftUI

// Theme color picked in Settings → Appearance. The app tints itself with it,
// and the Live Activity receives the raw value in its content state since
// the extension can't read the app's settings.
nonisolated enum AppAccent: String, CaseIterable, Codable, Hashable {
    case blue, indigo, purple, pink, red, orange, green, teal

    static let storageKey = "appAccent"
    static let defaultValue: AppAccent = .blue

    var color: Color {
        switch self {
        case .blue:   .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink:   .pink
        case .red:    .red
        case .orange: .orange
        case .green:  .green
        case .teal:   .teal
        }
    }

    var labelKey: String { "accent_\(rawValue)" }
}
