import Foundation

// Helper for relative time formatting
struct RelativeTimeFormatter {
    static let shared = RelativeTimeFormatter()
    
    func string(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}