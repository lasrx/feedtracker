import SwiftUI
import Foundation

struct FeedHistoryView: View {
    @ObservedObject var storageService: GoogleSheetsStorageService
    let refreshTrigger: Int
    @State private var todayFeeds: [FeedEntry] = []
    @State private var isLoading = false
    @State private var totalVolume: Int = 0
    @State private var weeklyTotals: [DailyTotal] = []
    @State private var past7DaysFeedEntries: [FeedEntry] = []
    @State private var isLoadingWeekly = false
    @State private var feedToEdit: FeedEntry?
    @State private var feedToDelete: FeedEntry?
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationStack {
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
                        HStack(spacing: 15) {
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
                            
                            VStack {
                                Text(totalWastedVolume)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                                Text("Wasted")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.bottom)
                    }
                }
                .background(Color(.systemGroupedBackground))
                
                // Weekly Summary
                if !weeklyTotals.isEmpty && !past7DaysFeedEntries.isEmpty {
                    VStack(spacing: 0) {
                        StackedWeeklySummaryView(
                            feedEntries: past7DaysFeedEntries,
                            dailyTotals: weeklyTotals,
                            todayVolume: totalVolume,
                            title: "Weekly Summary",
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
                            .symbolRenderingMode(.hierarchical)
                            .symbolEffect(.pulse.byLayer, options: .repeating)
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
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    editFeed(feed)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                                
                                Button {
                                    deleteFeed(feed)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                            .contextMenu {
                                Button {
                                    editFeed(feed)
                                } label: {
                                    Label("Edit Entry", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    deleteFeed(feed)
                                } label: {
                                    Label("Delete Entry", systemImage: "trash")
                                }
                            }
                    }
                    .listStyle(PlainListStyle())
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { _ in
                                // This gesture will compete with navigation for List area
                            }
                    )
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadTodayFeeds()
        }
        .onChange(of: refreshTrigger) { _, _ in
            loadTodayFeeds()
        }
        .refreshable {
            await loadAllDataOptimized(forceRefresh: true)
        }
        .deleteAlert(
            isPresented: $showDeleteAlert,
            item: $feedToDelete,
            itemType: "Feed Entry",
            itemDescription: { feed in
                "the \(feed.actualVolume)mL feed from \(feed.time)"
            },
            onConfirm: {
                if let feed = feedToDelete {
                    Task {
                        await performDelete(feed)
                    }
                }
            }
        )
        .sheet(item: $feedToEdit) { feed in
            FeedEditSheet(
                feed: feed,
                storageService: storageService,
                onSave: { updatedFeed in
                    Task {
                        await performEdit(updatedFeed)
                    }
                },
                onCancel: {
                    feedToEdit = nil
                }
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var averageVolume: String {
        let feedEntries = todayFeeds.filter { !$0.isWaste }
        guard !feedEntries.isEmpty else { return "0 mL" }
        let totalFeedVolume = feedEntries.reduce(0) { $0 + $1.actualVolume }
        let avg = totalFeedVolume / feedEntries.count
        return "\(avg) mL"
    }
    
    private var totalWastedVolume: String {
        let wasteEntries = todayFeeds.filter { $0.isWaste }
        let totalWaste = wasteEntries.reduce(0) { $0 + $1.actualVolume }
        return "\(totalWaste) mL"
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
            await loadAllDataOptimized(forceRefresh: false)
        }
    }
    
    // MARK: - Optimized Data Loading
    
    private func loadAllDataOptimized(forceRefresh: Bool) async {
        guard storageService.isSignedIn else {
            await MainActor.run {
                isLoading = false
                isLoadingWeekly = false
            }
            return
        }
        
        do {
            // Single API call gets all data we need (7 days including today)
            let recentEntries = try await storageService.fetchRecentFeedEntries(days: 7, forceRefresh: forceRefresh)
            
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            // Separate today's entries from historical entries
            let todaysEntries = recentEntries.filter { entry in
                calendar.isDate(entry.fullDate, inSameDayAs: Date())
            }
            
            // Calculate daily totals from all entries (past 6 days + today = 7 total days)
            let chartEntries = recentEntries.filter { entry in
                let daysDiff = calendar.dateComponents([.day], from: entry.fullDate, to: today).day ?? 0
                return daysDiff >= 0 && daysDiff <= 6  // Include today (0) through 6 days ago
            }
            
            let calculatedDailyTotals = calculateDailyTotals(from: chartEntries)
            
            await MainActor.run {
                self.todayFeeds = todaysEntries.sorted { $0.fullDate > $1.fullDate }
                self.totalVolume = todaysEntries.reduce(0) { $0 + $1.volume }
                self.weeklyTotals = calculatedDailyTotals
                self.past7DaysFeedEntries = chartEntries
                self.isLoading = false
                self.isLoadingWeekly = false
            }
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.isLoadingWeekly = false
            }
        }
    }
    
    private func calculateDailyTotals(from entries: [FeedEntry]) -> [DailyTotal] {
        let calendar = Calendar.current
        let groupedByDate = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.fullDate)
        }
        
        return groupedByDate.map { date, dateEntries in
            let totalVolume = dateEntries.reduce(0) { $0 + $1.volume }
            return DailyTotal(date: date, volume: totalVolume)
        }.sorted { $0.date < $1.date }
    }
    
    private func loadTodayFeedsAsync(forceRefresh: Bool = true) async {
        guard storageService.isSignedIn else {
            await MainActor.run {
                isLoading = false
            }
            return
        }
        
        do {
            let feeds = try await storageService.fetchTodayFeeds(forceRefresh: forceRefresh)
            await MainActor.run {
                self.todayFeeds = feeds.sorted { $0.fullDate > $1.fullDate }
                self.totalVolume = feeds.reduce(0) { $0 + $1.volume }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func loadWeeklyTotalsAsync(forceRefresh: Bool = true) async {
        guard storageService.isSignedIn else {
            await MainActor.run {
                isLoadingWeekly = false
            }
            return
        }
        
        do {
            let totals = try await storageService.fetchPast7DaysFeedTotals(forceRefresh: forceRefresh)
            await MainActor.run {
                self.weeklyTotals = totals
                self.isLoadingWeekly = false
            }
        } catch {
            await MainActor.run {
                self.isLoadingWeekly = false
            }
        }
    }
    
    private func loadRecentFeedEntriesAsync(forceRefresh: Bool = true) async {
        guard storageService.isSignedIn else {
            return
        }
        
        do {
            let entries = try await storageService.fetchRecentFeedEntries(days: 7, forceRefresh: forceRefresh)
            await MainActor.run {
                self.past7DaysFeedEntries = entries
            }
        } catch {
        }
    }
    
    // MARK: - Edit/Delete Actions
    
    private func editFeed(_ feed: FeedEntry) {
        feedToEdit = feed
    }
    
    private func deleteFeed(_ feed: FeedEntry) {
        feedToDelete = feed
        showDeleteAlert = true
    }
    
    private func performEdit(_ updatedFeed: FeedEntry) async {
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d/yyyy"
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            
            let date = dateFormatter.string(from: updatedFeed.fullDate)
            let time = timeFormatter.string(from: updatedFeed.fullDate)
            
            try await storageService.updateFeedEntry(
                updatedFeed,
                newDate: date,
                newTime: time,
                newVolume: String(updatedFeed.volume),  // Use volume (with sign) instead of actualVolume
                newFormulaType: updatedFeed.formulaType,
                newWasteAmount: String(updatedFeed.wasteAmount)
            )
            
            // Reload data after successful edit
            await loadAllDataOptimized(forceRefresh: true)
            feedToEdit = nil
            
        } catch {
            await MainActor.run {
                feedToEdit = nil
            }
        }
    }
    
    private func performDelete(_ feed: FeedEntry) async {
        do {
            try await storageService.deleteFeedEntry(feed)
            
            // Reload data after successful delete
            await loadAllDataOptimized(forceRefresh: true)
            
        } catch {
        }
        
        await MainActor.run {
            feedToDelete = nil
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
                Text("\(feed.actualVolume)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(feed.isWaste ? .orange : .accentColor)
                
                Text(feed.isWaste ? "waste" : "mL")
                    .font(.caption2)
                    .foregroundColor(feed.isWaste ? .orange : .secondary)
            }
            .frame(width: 50)
            
            Spacer()
            
            // Formula Type and feed/waste indicator
            HStack {
                Image(systemName: feed.isWaste ? "trash.circle.fill" : "drop.circle.fill")
                    .font(.title3)
                    .foregroundColor(feed.isWaste ? .orange : .accentColor)
                    .symbolRenderingMode(.hierarchical)

                Text(feed.formulaType)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.trailing)
            }
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
    FeedHistoryView(storageService: GoogleSheetsStorageService(), refreshTrigger: 0)
}