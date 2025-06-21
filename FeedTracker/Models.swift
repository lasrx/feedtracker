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
        formatter.dateFormat = "M/d/yyyy h:mm a"  // 12-hour format with AM/PM
        let combinedString = "\(date) \(time)"
        if let parsedDate = formatter.date(from: combinedString) {
            return parsedDate
        } else {
            print("FeedEntry: Failed to parse date '\(combinedString)' with format 'M/d/yyyy h:mm a'")
            // Return a very old date instead of current date to avoid "0s" issue
            return Date.distantPast
        }
    }
}

struct PumpingEntry: Identifiable {
    let id = UUID()
    let date: String
    let time: String
    let volume: Int
    
    var fullDate: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy h:mm a"  // 12-hour format with AM/PM
        let combinedString = "\(date) \(time)"
        if let parsedDate = formatter.date(from: combinedString) {
            return parsedDate
        } else {
            print("PumpingEntry: Failed to parse date '\(combinedString)' with format 'M/d/yyyy h:mm a'")
            // Return a very old date instead of current date to avoid "0s" issue
            return Date.distantPast
        }
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