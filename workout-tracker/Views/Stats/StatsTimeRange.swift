import Foundation

/// Time window used to filter progression charts in the Statistics tab.
enum StatsTimeRange: String, CaseIterable, Identifiable {
    case month1
    case month3
    case month6
    case all

    var id: String { rawValue }

    var labelKey: String {
        switch self {
        case .month1: return "stats_range_1m"
        case .month3: return "stats_range_3m"
        case .month6: return "stats_range_6m"
        case .all: return "stats_range_all"
        }
    }

    /// Earliest date included in this range, or nil for `.all`.
    func startDate(from reference: Date = Date()) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .month1: return calendar.date(byAdding: .month, value: -1, to: reference)
        case .month3: return calendar.date(byAdding: .month, value: -3, to: reference)
        case .month6: return calendar.date(byAdding: .month, value: -6, to: reference)
        case .all: return nil
        }
    }

    func contains(_ date: Date, reference: Date = Date()) -> Bool {
        guard let start = startDate(from: reference) else { return true }
        return date >= start
    }
}
