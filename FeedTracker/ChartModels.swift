import Foundation
import SwiftUI

// MARK: - Chart-Specific Models

struct FormulaBreakdown {
    let formulaType: String
    let volume: Int
    let color: Color
    
    static func getColor(for formulaType: String, from allTypes: [String]) -> Color {
        // Use a muted, formula-appropriate color palette
        let availableColors: [Color] = [
            Color(.systemBlue),           // Classic blue
            Color(.systemGreen),          // Soft green  
            Color(.systemOrange),         // Warm orange
            Color(.systemPurple),         // Gentle purple
            Color(.systemTeal),           // Calming teal
            Color(.systemBrown),          // Natural brown
            Color(.systemIndigo),         // Deep indigo
            Color(.systemPink),           // Soft pink
            Color(.systemGray),           // Neutral gray
            Color(.systemGray2),          // Light gray
            Color(.systemGray4),          // Medium gray
            Color(.systemGray6)           // Very light gray
        ]
        
        // Get a consistent index for this formula type
        let sortedTypes = allTypes.sorted()
        if let index = sortedTypes.firstIndex(of: formulaType) {
            return availableColors[index % availableColors.count]
        }
        
        // Fallback for unknown types
        return .gray
    }
}

struct DailyTotalWithBreakdown: Identifiable {
    let id = UUID()
    let date: Date
    let totalVolume: Int
    let formulaBreakdown: [FormulaBreakdown]
    
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
    
    // For backwards compatibility with existing WeeklySummaryView
    var volume: Int {
        return totalVolume
    }
}

// MARK: - Chart Data Processing

struct ChartDataProcessor {
    static func processRawFeedData(_ feedEntries: [FeedEntry]) -> [DailyTotalWithBreakdown] {
        // Group feed entries by date
        let groupedByDate = Dictionary(grouping: feedEntries) { entry in
            entry.fullDate.startOfDay()
        }
        
        // Collect all unique formula types for consistent color assignment
        let allFormulaTypes = Set(feedEntries.map { $0.formulaType })
        let sortedFormulaTypes = Array(allFormulaTypes).sorted()
        
        // Process each day's data
        var dailyTotals: [DailyTotalWithBreakdown] = []
        
        for (date, entries) in groupedByDate {
            // Group by formula type for this day
            let formulaVolumes = Dictionary(grouping: entries) { $0.formulaType }
                .mapValues { entriesForFormula in
                    entriesForFormula.reduce(0) { $0 + $1.actualVolume }
                }
            
            // Create breakdown with consistent colors
            let breakdown = formulaVolumes.map { formulaType, volume in
                FormulaBreakdown(
                    formulaType: formulaType,
                    volume: volume,
                    color: FormulaBreakdown.getColor(for: formulaType, from: sortedFormulaTypes)
                )
            }.sorted { $0.volume > $1.volume } // Sort by volume descending
            
            let totalVolume = formulaVolumes.values.reduce(0, +)
            
            let dailyTotal = DailyTotalWithBreakdown(
                date: date,
                totalVolume: totalVolume,
                formulaBreakdown: breakdown
            )
            
            dailyTotals.append(dailyTotal)
        }
        
        return dailyTotals.sorted { $0.date < $1.date }
    }
    
    static func processPast7DaysData(_ rawDailyTotals: [DailyTotal], from feedEntries: [FeedEntry]) -> [DailyTotalWithBreakdown] {
        // Get the dates we need
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var past7Days: [Date] = []
        for i in 1...7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                past7Days.append(date)
            }
        }
        
        // Collect all unique formula types for consistent color assignment
        let allFormulaTypes = Set(feedEntries.map { $0.formulaType })
        let sortedFormulaTypes = Array(allFormulaTypes).sorted()
        
        var dailyTotals: [DailyTotalWithBreakdown] = []
        
        for date in past7Days.reversed() { // Process in chronological order
            // Filter feed entries for this specific date
            let dateEntries = feedEntries.filter { entry in
                calendar.isDate(entry.fullDate, inSameDayAs: date)
            }
            
            if dateEntries.isEmpty {
                // No entries for this day
                let dailyTotal = DailyTotalWithBreakdown(
                    date: date,
                    totalVolume: 0,
                    formulaBreakdown: []
                )
                dailyTotals.append(dailyTotal)
            } else {
                // Process entries for this day
                let formulaVolumes = Dictionary(grouping: dateEntries) { $0.formulaType }
                    .mapValues { entriesForFormula in
                        entriesForFormula.reduce(0) { $0 + $1.actualVolume }
                    }
                
                let breakdown = formulaVolumes.map { formulaType, volume in
                    FormulaBreakdown(
                        formulaType: formulaType,
                        volume: volume,
                        color: FormulaBreakdown.getColor(for: formulaType, from: sortedFormulaTypes)
                    )
                }.sorted { $0.volume > $1.volume }
                
                let totalVolume = formulaVolumes.values.reduce(0, +)
                
                let dailyTotal = DailyTotalWithBreakdown(
                    date: date,
                    totalVolume: totalVolume,
                    formulaBreakdown: breakdown
                )
                dailyTotals.append(dailyTotal)
            }
        }
        
        return dailyTotals
    }
}

// MARK: - Date Extension

extension Date {
    func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }
}