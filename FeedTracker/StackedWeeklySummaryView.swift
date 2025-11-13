import SwiftUI
import Foundation

struct StackedWeeklySummaryView: View {
    let feedEntries: [FeedEntry]
    let dailyTotals: [DailyTotal]
    let todayVolume: Int
    let title: String
    let color: Color
    
    // Cached processed chart data
    @State private var cachedDailyTotals: [DailyTotalWithBreakdown] = []
    @State private var lastProcessedHash: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(trendText)
                    .font(.caption)
                    .foregroundColor(trendColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(trendColor.opacity(0.1))
                    .cornerRadius(4)
            }
            
            // Daily stacked bars
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(cachedDailyTotals) { daily in
                    VStack(spacing: 4) {
                        // Stacked volume bars
                        stackedBar(for: daily)
                        
                        // Day label
                        Text(daily.dayName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        // Volume label (only show if > 0)
                        if daily.totalVolume > 0 {
                            Text("\(daily.totalVolume)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(color)
                        }
                    }
                }
            }
            
            // Formula type legend
            if !allFormulaTypes.isEmpty {
                legendView
            }
            
            // Statistics
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly Avg")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(weeklyAverage) mL")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Best Day")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(bestDayText)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("vs Today")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(comparisonText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(comparisonColor)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
        .onAppear {
            updateCachedData()
        }
        .onChange(of: feedEntries.count) { _, _ in
            updateCachedData()
        }
        .onChange(of: dailyTotals.count) { _, _ in
            updateCachedData()
        }
    }
    
    // MARK: - Stacked Bar Component
    
    @ViewBuilder
    private func stackedBar(for daily: DailyTotalWithBreakdown) -> some View {
        if daily.formulaBreakdown.isEmpty {
            // Empty day - show gray placeholder with glass effect
            RoundedRectangle(cornerRadius: 2)
                .fill(.regularMaterial)
                .frame(width: 24, height: 2)
                .overlay {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                }
        } else {
            // Stacked segments with gradient and depth
            VStack(spacing: 0) {
                ForEach(Array(daily.formulaBreakdown.enumerated()), id: \.offset) { index, formula in
                    let segmentHeight = calculateSegmentHeight(formula: formula, totalVolume: daily.totalVolume)

                    RoundedRectangle(cornerRadius: index == 0 ? 3 : 0) // Only round the top segment
                        .fill(
                            LinearGradient(
                                colors: [formula.color, formula.color.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 24, height: segmentHeight)
                        .overlay {
                            if index == 0 {
                                // Subtle highlight on top segment
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.3), Color.clear],
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                    )
                            }
                        }
                }
            }
            .frame(height: totalBarHeight(for: daily))
            .shadow(color: color.opacity(0.2), radius: 2, y: 1)
        }
    }
    
    // MARK: - Legend
    
    private var legendView: some View {
        HStack(spacing: 8) {
            ForEach(Array(allFormulaTypes.enumerated()), id: \.offset) { index, formulaType in
                HStack(spacing: 4) {
                    Circle()
                        .fill(getFormulaColor(formulaType))
                        .frame(width: 8, height: 8)
                    
                    Text(formulaType)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var allFormulaTypes: [String] {
        let allTypes = Set(cachedDailyTotals.flatMap { $0.formulaBreakdown.map { $0.formulaType } })
        return Array(allTypes).sorted()
    }
    
    private var maxVolume: Int {
        let allVolumes = cachedDailyTotals.map { $0.totalVolume } + [todayVolume]
        return allVolumes.max() ?? 1
    }
    
    private var weeklyAverage: Int {
        let totalVolume = cachedDailyTotals.reduce(0) { $0 + $1.totalVolume }
        return cachedDailyTotals.isEmpty ? 0 : totalVolume / cachedDailyTotals.count
    }
    
    private var bestDay: DailyTotalWithBreakdown? {
        cachedDailyTotals.max { $0.totalVolume < $1.totalVolume }
    }
    
    private var bestDayText: String {
        guard let best = bestDay, best.totalVolume > 0 else { return "—" }
        return "\(best.dayName) (\(best.totalVolume))"
    }
    
    private var trendText: String {
        if todayVolume > weeklyAverage {
            return "Above Average"
        } else if todayVolume < weeklyAverage {
            return "Below Average"
        } else {
            return "On Average"
        }
    }
    
    private var trendColor: Color {
        if todayVolume > weeklyAverage {
            return .green
        } else if todayVolume < weeklyAverage {
            return .orange
        } else {
            return .blue
        }
    }
    
    private var comparisonText: String {
        let difference = todayVolume - weeklyAverage
        if difference > 0 {
            return "+\(difference) mL"
        } else if difference < 0 {
            return "\(difference) mL"
        } else {
            return "±0 mL"
        }
    }
    
    private var comparisonColor: Color {
        let difference = todayVolume - weeklyAverage
        if difference > 0 {
            return .green
        } else if difference < 0 {
            return .red
        } else {
            return .secondary
        }
    }
    
    // MARK: - Caching Functions
    
    private func updateCachedData() {
        // Create a hash from input data to detect changes
        let currentHash = createDataHash()
        
        // Only recompute if data has changed
        guard currentHash != lastProcessedHash else { return }
        
        // Process data in background to avoid blocking UI
        Task {
            let processed = ChartDataProcessor.processPast7DaysData(dailyTotals, from: feedEntries)
            
            await MainActor.run {
                self.cachedDailyTotals = processed
                self.lastProcessedHash = currentHash
            }
        }
    }
    
    private func createDataHash() -> Int {
        var hasher = Hasher()
        hasher.combine(feedEntries.count)
        hasher.combine(dailyTotals.count)
        // Hash key properties to detect content changes
        for entry in feedEntries.prefix(10) { // Sample first 10 entries for performance
            hasher.combine(entry.date)
            hasher.combine(entry.volume)
            hasher.combine(entry.formulaType)
        }
        return hasher.finalize()
    }
    
    // MARK: - Helper Functions
    
    private func totalBarHeight(for daily: DailyTotalWithBreakdown) -> CGFloat {
        guard maxVolume > 0, daily.totalVolume > 0 else { return 2 }
        let ratio = Double(daily.totalVolume) / Double(maxVolume)
        return max(2, CGFloat(ratio * 40)) // Max height 40, min height 2
    }
    
    private func calculateSegmentHeight(formula: FormulaBreakdown, totalVolume: Int) -> CGFloat {
        guard totalVolume > 0, maxVolume > 0 else { return 2 }
        let totalHeight = totalBarHeight(for: DailyTotalWithBreakdown(date: Date(), totalVolume: totalVolume, formulaBreakdown: []))
        let ratio = Double(formula.volume) / Double(totalVolume)
        return max(1, totalHeight * ratio) // Minimum 1 pixel height per segment
    }
    
    private func getFormulaColor(_ formulaType: String) -> Color {
        // Find the color from the actual breakdown data to ensure consistency
        for daily in cachedDailyTotals {
            if let breakdown = daily.formulaBreakdown.first(where: { $0.formulaType == formulaType }) {
                return breakdown.color
            }
        }
        // Fallback to calculated color if not found in data
        return FormulaBreakdown.getColor(for: formulaType, from: allFormulaTypes)
    }
}

#Preview {
    let sampleFeedEntries = [
        FeedEntry(date: "8/26/2025", time: "10:00 AM", volume: 100, formulaType: "Breast milk", wasteAmount: 0, rowIndex: 1),
        FeedEntry(date: "8/26/2025", time: "2:00 PM", volume: 50, formulaType: "Similac", wasteAmount: 0, rowIndex: 2),
        FeedEntry(date: "8/25/2025", time: "9:00 AM", volume: 120, formulaType: "Breast milk", wasteAmount: 0, rowIndex: 3)
    ]
    
    let sampleDailyTotals = [
        DailyTotal(date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, volume: 150),
        DailyTotal(date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, volume: 180),
        DailyTotal(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, volume: 120),
        DailyTotal(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, volume: 200),
        DailyTotal(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, volume: 0),
        DailyTotal(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, volume: 160),
        DailyTotal(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, volume: 140)
    ]
    
    StackedWeeklySummaryView(
        feedEntries: sampleFeedEntries,
        dailyTotals: sampleDailyTotals,
        todayVolume: 170,
        title: "Weekly Summary",
        color: .blue
    )
    .padding()
}