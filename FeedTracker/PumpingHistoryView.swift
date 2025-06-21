import SwiftUI
import Foundation

struct PumpingHistoryView: View {
    @ObservedObject var sheetsService: GoogleSheetsService
    let refreshTrigger: Int
    @State private var todayPumpingSessions: [PumpingEntry] = []
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
                            Text("Pump Overview")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            
                            Text(Date(), style: .date)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(totalVolume) mL")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.purple)
                            
                            Text("\(todayPumpingSessions.count) sessions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Quick Stats
                    if !todayPumpingSessions.isEmpty {
                        HStack(spacing: 20) {
                            VStack {
                                Text(averageVolume)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.purple)
                                Text("Avg Volume")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text(timeSinceLastSession)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.purple)
                                Text("Since Last")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text(totalSessions)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.purple)
                                Text("Sessions")
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
                            color: .purple
                        )
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 1)
                            .padding(.top, 8)
                    }
                }
                
                // Pumping Sessions List
                if isLoading {
                    Spacer()
                    ProgressView("Loading today's sessions...")
                        .foregroundColor(.purple)
                    Spacer()
                } else if todayPumpingSessions.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "drop.triangle.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.purple.opacity(0.6))
                        Text("No pumping sessions today")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Swipe left to log your first session")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List(todayPumpingSessions) { session in
                        PumpingRowView(session: session)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            print("PumpingHistoryView: onAppear called")
            loadTodaySessions()
        }
        .onChange(of: refreshTrigger) { _, _ in
            print("PumpingHistoryView: refreshTrigger changed, loading data")
            loadTodaySessions()
        }
        .refreshable {
            await loadTodaySessionsAsync()
        }
    }
    
    // MARK: - Computed Properties
    
    private var averageVolume: String {
        guard !todayPumpingSessions.isEmpty else { return "0 mL" }
        let avg = totalVolume / todayPumpingSessions.count
        return "\(avg) mL"
    }
    
    private var timeSinceLastSession: String {
        guard let lastSession = todayPumpingSessions.first else { return "—" }
        let sessionDate = lastSession.fullDate
        // If date parsing failed (Date.distantPast), show "—"
        if sessionDate == Date.distantPast {
            return "—"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: sessionDate, relativeTo: Date())
    }
    
    private var totalSessions: String {
        return "\(todayPumpingSessions.count)"
    }
    
    // MARK: - Data Loading
    
    private func loadTodaySessions() {
        isLoading = true
        isLoadingWeekly = true
        Task {
            await loadTodaySessionsAsync()
            await loadWeeklyTotalsAsync()
        }
    }
    
    private func loadTodaySessionsAsync() async {
        print("PumpingHistoryView: loadTodaySessionsAsync called, isSignedIn: \(sheetsService.isSignedIn)")
        guard sheetsService.isSignedIn else {
            print("PumpingHistoryView: Not signed in, skipping load")
            await MainActor.run {
                isLoading = false
            }
            return
        }
        
        do {
            print("PumpingHistoryView: Calling fetchTodayPumpingSessions...")
            let sessions = try await sheetsService.fetchTodayPumpingSessions()
            print("PumpingHistoryView: Received \(sessions.count) sessions")
            await MainActor.run {
                self.todayPumpingSessions = sessions.sorted { $0.fullDate > $1.fullDate } // Most recent first
                self.totalVolume = sessions.reduce(0) { $0 + $1.volume }
                self.isLoading = false
                print("PumpingHistoryView: Updated UI with \(self.todayPumpingSessions.count) sessions, total: \(self.totalVolume)mL")
            }
        } catch {
            await MainActor.run {
                print("Error loading today's pumping sessions: \(error)")
                self.isLoading = false
            }
        }
    }
    
    private func loadWeeklyTotalsAsync() async {
        print("PumpingHistoryView: loadWeeklyTotalsAsync called")
        guard sheetsService.isSignedIn else {
            print("PumpingHistoryView: Not signed in, skipping weekly load")
            await MainActor.run {
                isLoadingWeekly = false
            }
            return
        }
        
        do {
            print("PumpingHistoryView: Calling fetchPast7DaysPumpingTotals...")
            let totals = try await sheetsService.fetchPast7DaysPumpingTotals()
            print("PumpingHistoryView: Received \(totals.count) daily totals")
            await MainActor.run {
                self.weeklyTotals = totals
                self.isLoadingWeekly = false
                print("PumpingHistoryView: Updated UI with weekly totals")
            }
        } catch {
            await MainActor.run {
                print("Error loading weekly pumping totals: \(error)")
                self.isLoadingWeekly = false
            }
        }
    }
}

struct PumpingRowView: View {
    let session: PumpingEntry
    
    var body: some View {
        HStack {
            // Time
            VStack(alignment: .leading, spacing: 2) {
                Text(session.time)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(timeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60, alignment: .leading)
            
            // Volume
            VStack(spacing: 2) {
                Text("\(session.volume)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.purple)
                
                Text("mL")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
            
            Spacer()
            
            // Pumping icon
            Image(systemName: "drop.triangle.fill")
                .font(.title2)
                .foregroundColor(.purple.opacity(0.6))
        }
        .padding(.vertical, 4)
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: session.fullDate, relativeTo: Date())
    }
}

#Preview {
    PumpingHistoryView(sheetsService: GoogleSheetsService(), refreshTrigger: 0)
}