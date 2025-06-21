import SwiftUI
import Foundation

struct FeedHistoryView: View {
    @ObservedObject var sheetsService: GoogleSheetsService
    let refreshTrigger: Int
    @State private var todayFeeds: [FeedEntry] = []
    @State private var isLoading = false
    @State private var totalVolume: Int = 0
    @State private var weeklyTotals: [DailyTotal] = []
    @State private var isLoadingWeekly = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Today's Summary Header
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Feed Overview")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text(Date(), style: .date)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(totalVolume) mL")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.accentColor)
                            
                            Text("\(todayFeeds.count) feeds")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Quick Stats
                    if !todayFeeds.isEmpty {
                        HStack(spacing: 20) {
                            VStack {
                                Text(averageVolume)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                Text("Avg Volume")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text(timeSinceLastFeed)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                Text("Since Last")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text(mostCommonFormula)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                Text("Most Used")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.bottom)
                    }
                }
                .background(Color(.systemGroupedBackground))
                
                // Weekly Summary
                if !weeklyTotals.isEmpty {
                    VStack(spacing: 0) {
                        WeeklySummaryView(
                            dailyTotals: weeklyTotals,
                            todayVolume: totalVolume,
                            title: "Past Week Summary",
                            color: .accentColor
                        )
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 1)
                            .padding(.top, 8)
                    }
                }
                
                // Feed List
                if isLoading {
                    Spacer()
                    ProgressView("Loading today's feeds...")
                    Spacer()
                } else if todayFeeds.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "drop.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No feeds logged today")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Swipe right to log your first feed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List(todayFeeds) { feed in
                        FeedRowView(feed: feed)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            print("FeedHistoryView: onAppear called")
            loadTodayFeeds()
        }
        .onChange(of: refreshTrigger) { _, _ in
            print("FeedHistoryView: refreshTrigger changed, loading data")
            loadTodayFeeds()
        }
        .refreshable {
            await loadTodayFeedsAsync()
        }
    }
    
    // MARK: - Computed Properties
    
    private var averageVolume: String {
        guard !todayFeeds.isEmpty else { return "0 mL" }
        let avg = totalVolume / todayFeeds.count
        return "\(avg) mL"
    }
    
    private var timeSinceLastFeed: String {
        guard let lastFeed = todayFeeds.first else { return "—" }
        let feedDate = lastFeed.fullDate
        // If date parsing failed (Date.distantPast), show "—"
        if feedDate == Date.distantPast {
            return "—"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: feedDate, relativeTo: Date())
    }
    
    private var mostCommonFormula: String {
        guard !todayFeeds.isEmpty else { return "—" }
        let formulas = todayFeeds.map { $0.formulaType }
        let counts = Dictionary(grouping: formulas, by: { $0 }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key ?? "—"
    }
    
    // MARK: - Data Loading
    
    private func loadTodayFeeds() {
        isLoading = true
        isLoadingWeekly = true
        Task {
            await loadTodayFeedsAsync()
            await loadWeeklyTotalsAsync()
        }
    }
    
    private func loadTodayFeedsAsync() async {
        print("FeedHistoryView: loadTodayFeedsAsync called, isSignedIn: \(sheetsService.isSignedIn)")
        guard sheetsService.isSignedIn else {
            print("FeedHistoryView: Not signed in, skipping load")
            await MainActor.run {
                isLoading = false
            }
            return
        }
        
        do {
            print("FeedHistoryView: Calling fetchTodayFeeds...")
            let feeds = try await sheetsService.fetchTodayFeeds()
            print("FeedHistoryView: Received \(feeds.count) feeds")
            await MainActor.run {
                self.todayFeeds = feeds.sorted { $0.fullDate > $1.fullDate } // Most recent first
                self.totalVolume = feeds.reduce(0) { $0 + $1.volume }
                self.isLoading = false
                print("FeedHistoryView: Updated UI with \(self.todayFeeds.count) feeds, total: \(self.totalVolume)mL")
            }
        } catch {
            await MainActor.run {
                print("Error loading today's feeds: \(error)")
                self.isLoading = false
            }
        }
    }
    
    private func loadWeeklyTotalsAsync() async {
        print("FeedHistoryView: loadWeeklyTotalsAsync called")
        guard sheetsService.isSignedIn else {
            print("FeedHistoryView: Not signed in, skipping weekly load")
            await MainActor.run {
                isLoadingWeekly = false
            }
            return
        }
        
        do {
            print("FeedHistoryView: Calling fetchPast7DaysFeedTotals...")
            let totals = try await sheetsService.fetchPast7DaysFeedTotals()
            print("FeedHistoryView: Received \(totals.count) daily totals")
            await MainActor.run {
                self.weeklyTotals = totals
                self.isLoadingWeekly = false
                print("FeedHistoryView: Updated UI with weekly totals")
            }
        } catch {
            await MainActor.run {
                print("Error loading weekly feed totals: \(error)")
                self.isLoadingWeekly = false
            }
        }
    }
}

struct FeedRowView: View {
    let feed: FeedEntry
    
    var body: some View {
        HStack {
            // Time
            VStack(alignment: .leading, spacing: 2) {
                Text(feed.time)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(timeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60, alignment: .leading)
            
            // Volume
            VStack(spacing: 2) {
                Text("\(feed.volume)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
                
                Text("mL")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
            
            Spacer()
            
            // Formula Type
            Text(feed.formulaType)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: feed.fullDate, relativeTo: Date())
    }
}


#Preview {
    FeedHistoryView(sheetsService: GoogleSheetsService(), refreshTrigger: 0)
}