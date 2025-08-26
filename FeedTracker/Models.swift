import Foundation

// MARK: - Data Models

struct FeedEntry: Identifiable {
    let id = UUID()
    let date: String
    let time: String
    let volume: Int           // Positive for feeds, negative for waste
    let formulaType: String
    let wasteAmount: Int      // Positive value for actual waste amount (column E)
    let rowIndex: Int?        // Google Sheets row index for editing/deletion
    
    var isWaste: Bool {
        return volume < 0
    }
    
    var actualVolume: Int {
        // For waste entries, return the absolute value of volume
        // For feed entries, return the volume as-is
        return abs(volume)
    }
    
    var effectiveVolume: Int {
        // For calculations: feeds are positive, waste is negative
        return volume
    }
    
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
    let rowIndex: Int?        // Google Sheets row index for editing/deletion
    
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

