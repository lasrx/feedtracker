import Foundation
@testable import FeedTracker

/// Provides real test data from actual spreadsheets for more realistic unit testing
/// This helps catch edge cases that synthetic test data might miss
struct RealDataTestProvider {
    
    // MARK: - Real Feed Data Samples
    
    /// Sample data based on actual Google Sheets feed log entries
    /// This represents real-world usage patterns and formatting variations
    static let realFeedEntries: [FeedEntry] = [
        // Morning feeds - typical volumes and timing
        FeedEntry(date: "6/29/2025", time: "6:30 AM", volume: 120, formulaType: "Breast milk", wasteAmount: 0),
        FeedEntry(date: "6/29/2025", time: "9:15 AM", volume: 140, formulaType: "Similac 360", wasteAmount: 0),
        
        // Waste entry - real scenario where milk was prepared but baby didn't finish
        FeedEntry(date: "6/29/2025", time: "11:45 AM", volume: -30, formulaType: "Breast milk", wasteAmount: 30),
        
        // Afternoon feeds
        FeedEntry(date: "6/29/2025", time: "1:20 PM", volume: 160, formulaType: "Emfamil Neuropro", wasteAmount: 0),
        FeedEntry(date: "6/29/2025", time: "3:45 PM", volume: 130, formulaType: "Breast milk", wasteAmount: 0),
        
        // Another waste entry - overestimated hunger
        FeedEntry(date: "6/29/2025", time: "5:10 PM", volume: -20, formulaType: "Similac 360", wasteAmount: 20),
        
        // Evening feeds
        FeedEntry(date: "6/29/2025", time: "7:30 PM", volume: 150, formulaType: "Breast milk", wasteAmount: 0),
        FeedEntry(date: "6/29/2025", time: "10:45 PM", volume: 180, formulaType: "Emfamil Neuropro", wasteAmount: 0),
        
        // Late night feed
        FeedEntry(date: "6/30/2025", time: "2:15 AM", volume: 100, formulaType: "Breast milk", wasteAmount: 0),
        
        // Previous day data for 7-day calculations
        FeedEntry(date: "6/28/2025", time: "8:00 AM", volume: 110, formulaType: "Similac 360", wasteAmount: 0),
        FeedEntry(date: "6/28/2025", time: "12:30 PM", volume: 145, formulaType: "Breast milk", wasteAmount: 0),
        FeedEntry(date: "6/28/2025", time: "4:15 PM", volume: -25, formulaType: "Breast milk", wasteAmount: 25), // Waste
        FeedEntry(date: "6/28/2025", time: "8:45 PM", volume: 165, formulaType: "Emfamil Neuropro", wasteAmount: 0),
        
        // Week-old data
        FeedEntry(date: "6/22/2025", time: "9:30 AM", volume: 95, formulaType: "Breast milk", wasteAmount: 0),
        FeedEntry(date: "6/22/2025", time: "1:45 PM", volume: 125, formulaType: "Similac 360", wasteAmount: 0),
        FeedEntry(date: "6/22/2025", time: "6:20 PM", volume: 140, formulaType: "Breast milk", wasteAmount: 0),
    ]
    
    // MARK: - Real Pumping Data Samples
    
    static let realPumpingEntries: [PumpingEntry] = [
        PumpingEntry(date: "6/29/2025", time: "7:00 AM", volume: 140),
        PumpingEntry(date: "6/29/2025", time: "11:30 AM", volume: 160),
        PumpingEntry(date: "6/29/2025", time: "3:00 PM", volume: 145),
        PumpingEntry(date: "6/29/2025", time: "7:45 PM", volume: 155),
        PumpingEntry(date: "6/29/2025", time: "11:15 PM", volume: 130),
        
        PumpingEntry(date: "6/28/2025", time: "6:45 AM", volume: 135),
        PumpingEntry(date: "6/28/2025", time: "10:20 AM", volume: 150),
        PumpingEntry(date: "6/28/2025", time: "2:30 PM", volume: 165),
        PumpingEntry(date: "6/28/2025", time: "6:15 PM", volume: 140),
    ]
    
    // MARK: - Legacy 4-Column Data (Backward Compatibility)
    
    /// Represents data from older spreadsheets before waste tracking was implemented
    static let legacy4ColumnData: [[String]] = [
        ["6/25/2025", "8:00 AM", "120", "Breast milk"],
        ["6/25/2025", "12:30 PM", "150", "Similac 360"],
        ["6/25/2025", "4:45 PM", "135", "Breast milk"],
        ["6/25/2025", "8:15 PM", "160", "Emfamil Neuropro"],
    ]
    
    // MARK: - New 5-Column Data (With Waste Tracking)
    
    /// Represents data from newer spreadsheets with waste tracking capability
    static let new5ColumnData: [[String]] = [
        ["6/29/2025", "6:30 AM", "120", "Breast milk", "0"],
        ["6/29/2025", "9:15 AM", "140", "Similac 360", "0"],
        ["6/29/2025", "11:45 AM", "-30", "Breast milk", "30"], // Waste entry
        ["6/29/2025", "1:20 PM", "160", "Emfamil Neuropro", "0"],
        ["6/29/2025", "5:10 PM", "-20", "Similac 360", "20"], // Waste entry
        ["6/29/2025", "7:30 PM", "150", "Breast milk", "0"],
    ]
    
    // MARK: - Edge Cases from Real Data
    
    /// Real edge cases that have occurred in actual usage
    static let edgeCaseData: [[String]] = [
        // Time format variations that might appear in real data
        ["6/29/2025", "9:05 AM", "120", "Breast milk", "0"],    // Single digit minutes
        ["6/29/2025", "12:00 PM", "150", "Similac 360", "0"],   // Noon exactly
        ["6/29/2025", "12:00 AM", "100", "Breast milk", "0"],   // Midnight exactly
        
        // Formula name variations from real user input
        ["6/29/2025", "2:30 PM", "140", "breast milk", "0"],    // Lowercase
        ["6/29/2025", "4:15 PM", "130", "Similac Pro", "0"],    // Shortened name
        ["6/29/2025", "6:45 PM", "160", "Enfamil", "0"],        // Common misspelling
        
        // Volume edge cases
        ["6/29/2025", "8:00 PM", "200", "Breast milk", "0"],    // High volume
        ["6/29/2025", "9:30 PM", "30", "Similac 360", "0"],     // Low volume
        ["6/29/2025", "10:15 PM", "-5", "Breast milk", "5"],    // Small waste amount
        ["6/29/2025", "11:45 PM", "-90", "Emfamil Neuropro", "90"], // Large waste amount
    ]
    
    // MARK: - Calculation Test Data
    
    /// Data specifically designed to test calculation accuracy
    static let calculationTestData: [FeedEntry] = [
        // Today's data (6/29/2025) for today's total calculation
        FeedEntry(date: "6/29/2025", time: "8:00 AM", volume: 120, formulaType: "Breast milk", wasteAmount: 0),
        FeedEntry(date: "6/29/2025", time: "12:00 PM", volume: 150, formulaType: "Similac 360", wasteAmount: 0),
        FeedEntry(date: "6/29/2025", time: "3:00 PM", volume: -30, formulaType: "Breast milk", wasteAmount: 30), // Waste
        FeedEntry(date: "6/29/2025", time: "6:00 PM", volume: 140, formulaType: "Emfamil Neuropro", wasteAmount: 0),
        
        // Expected calculations:
        // Total effective volume: 120 + 150 + (-30) + 140 = 380 mL
        // Total waste: 30 mL
        // Total fed: 120 + 150 + 140 = 410 mL
        // Feed count: 3
        // Waste count: 1
        // Average feed: 410 / 3 = 136.67 ≈ 137 mL
    ]
    
    // MARK: - Helper Methods
    
    /// Convert raw string data to FeedEntry objects (simulating GoogleSheetsService parsing)
    static func parseFeedEntriesFromRows(_ rows: [[String]]) -> [FeedEntry] {
        return rows.compactMap { row in
            guard row.count >= 4,
                  let volume = Int(row[2]) else {
                return nil
            }
            
            let wasteAmount = row.count >= 5 ? Int(row[4]) ?? 0 : 0
            
            return FeedEntry(
                date: row[0],
                time: row[1],
                volume: volume,
                formulaType: row[3],
                wasteAmount: wasteAmount
            )
        }
    }
    
    /// Get entries for a specific date (simulating today's data filtering)
    static func getEntriesForDate(_ date: String, from entries: [FeedEntry]) -> [FeedEntry] {
        return entries.filter { $0.date == date }
    }
    
    /// Calculate daily totals for the past 7 days (simulating FeedHistoryView calculations)
    static func calculatePast7DayTotals(from entries: [FeedEntry], today: Date = Date()) -> [DailyTotal] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        
        var dailyTotals: [DailyTotal] = []
        
        for i in 1...7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dateString = dateFormatter.string(from: date)
            
            let dayEntries = getEntriesForDate(dateString, from: entries)
            let dayTotal = dayEntries.reduce(0) { $0 + $1.effectiveVolume }
            
            dailyTotals.append(DailyTotal(date: date, volume: dayTotal))
        }
        
        return dailyTotals.sorted { $0.date < $1.date }
    }
    
    /// Get most common formula type (simulating FeedHistoryView calculation)
    static func getMostCommonFormulaType(from entries: [FeedEntry]) -> String {
        let feedEntries = entries.filter { !$0.isWaste }
        let formulaCounts = Dictionary(grouping: feedEntries, by: { $0.formulaType })
            .mapValues { $0.count }
        
        return formulaCounts.max(by: { $0.value < $1.value })?.key ?? "—"
    }
}