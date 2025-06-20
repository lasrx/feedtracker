import SwiftUI
import Foundation

struct WeeklySummaryView: View {
    let dailyTotals: [DailyTotal]
    let todayVolume: Int
    let title: String
    let color: Color
    
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
            
            // Daily bars
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(dailyTotals) { daily in
                    VStack(spacing: 4) {
                        // Volume bar
                        RoundedRectangle(cornerRadius: 2)
                            .fill(barColor(for: daily))
                            .frame(width: 24, height: barHeight(for: daily))
                        
                        // Day label
                        Text(daily.dayName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        // Volume label (only show if > 0)
                        if daily.volume > 0 {
                            Text("\(daily.volume)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(color)
                        }
                    }
                }
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
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    
    private var maxVolume: Int {
        let allVolumes = dailyTotals.map { $0.volume } + [todayVolume]
        return allVolumes.max() ?? 1
    }
    
    private var weeklyAverage: Int {
        let totalVolume = dailyTotals.reduce(0) { $0 + $1.volume }
        return dailyTotals.isEmpty ? 0 : totalVolume / dailyTotals.count
    }
    
    private var bestDay: DailyTotal? {
        dailyTotals.max { $0.volume < $1.volume }
    }
    
    private var bestDayText: String {
        guard let best = bestDay, best.volume > 0 else { return "—" }
        return "\(best.dayName) (\(best.volume))"
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
    
    private func barHeight(for daily: DailyTotal) -> CGFloat {
        guard maxVolume > 0 else { return 2 }
        let ratio = Double(daily.volume) / Double(maxVolume)
        return max(2, CGFloat(ratio * 40)) // Max height 40, min height 2
    }
    
    private func barColor(for daily: DailyTotal) -> Color {
        if daily.volume == 0 {
            return Color.gray.opacity(0.3)
        } else if daily.volume >= weeklyAverage {
            return color
        } else {
            return color.opacity(0.6)
        }
    }
}

#Preview {
    let sampleData = [
        DailyTotal(date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, volume: 150),
        DailyTotal(date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, volume: 180),
        DailyTotal(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, volume: 120),
        DailyTotal(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, volume: 200),
        DailyTotal(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, volume: 0),
        DailyTotal(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, volume: 160),
        DailyTotal(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, volume: 140)
    ]
    
    WeeklySummaryView(
        dailyTotals: sampleData,
        todayVolume: 170,
        title: "Past Week Summary",
        color: .blue
    )
    .padding()
}