import Foundation

// MARK: - Data Models

struct FeedEntry: Identifiable {
    let id = UUID()
    let date: String
    let time: String
    let volume: Int
    let formulaType: String
    
    var fullDate: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy HH:mm"
        return formatter.date(from: "\(date) \(time)") ?? Date()
    }
}

struct PumpingEntry: Identifiable {
    let id = UUID()
    let date: String
    let time: String
    let volume: Int
    
    var fullDate: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy HH:mm"
        return formatter.date(from: "\(date) \(time)") ?? Date()
    }
}

struct DailyTotal: Identifiable {
    let id = UUID()
    let date: Date
    let volume: Int
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // Mon, Tue, Wed, etc.
        return formatter.string(from: date)
    }
    
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(date)
    }
}