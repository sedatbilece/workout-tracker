import Foundation

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = .current
        return formatter.string(from: self)
    }
}
