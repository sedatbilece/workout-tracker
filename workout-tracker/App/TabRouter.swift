import SwiftUI

@Observable
final class TabRouter {
    var selectedTab: Int = 0
    /// Workout to open on the Today tab, set by the Live Activity deep link.
    var pendingSessionUUID: UUID?
}
