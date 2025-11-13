import SwiftUI
import Foundation

struct PumpingHistoryView: View {
    @ObservedObject var storageService: GoogleSheetsStorageService
    let refreshTrigger: Int
    @State private var todayPumpingSessions: [PumpingEntry] = []
    @State private var isLoading = false
    @State private var totalVolume: Int = 0
    @State private var weeklyTotals: [DailyTotal] = []
    @State private var isLoadingWeekly = false
    @State private var sessionToEdit: PumpingEntry?
    @State private var sessionToDelete: PumpingEntry?
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationStack {
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
                            title: "Weekly Summary",
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
                        Image(systemName: "drop.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.purple.opacity(0.6))
                            .symbolRenderingMode(.hierarchical)
                            .symbolEffect(.pulse.byLayer, options: .repeating)
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
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    editSession(session)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.purple)
                                
                                Button {
                                    deleteSession(session)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                            .contextMenu {
                                Button {
                                    editSession(session)
                                } label: {
                                    Label("Edit Session", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    deleteSession(session)
                                } label: {
                                    Label("Delete Session", systemImage: "trash")
                                }
                            }
                    }
                    .listStyle(PlainListStyle())
                    // ⚠️ GESTURE HIERARCHY: This .simultaneousGesture() works with HorizontalNavigationView's .gesture()
                    // DO NOT change HorizontalNavigationView to .simultaneousGesture() or list swipes will break
                    // See HorizontalNavigationView.swift:52 for full explanation
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { _ in
                                // This gesture competes with navigation to prioritize list swipe actions
                            }
                    )
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadTodaySessions()
        }
        .onChange(of: refreshTrigger) { _, _ in
            loadTodaySessions()
        }
        .refreshable {
            await loadAllPumpingDataParallel(forceRefresh: true)
        }
        .deleteAlert(
            isPresented: $showDeleteAlert,
            item: $sessionToDelete,
            itemType: "Pumping Session",
            itemDescription: { session in
                "the \(session.volume)mL pumping session from \(session.time)"
            },
            onConfirm: {
                if let session = sessionToDelete {
                    Task {
                        await performDelete(session)
                    }
                }
            }
        )
        .sheet(item: $sessionToEdit) { session in
            PumpingEditSheet(
                session: session,
                storageService: storageService,
                onSave: { updatedSession in
                    Task {
                        await performEdit(updatedSession)
                    }
                },
                onCancel: {
                    sessionToEdit = nil
                }
            )
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
            await loadAllPumpingDataParallel(forceRefresh: false)
        }
    }
    
    // MARK: - Optimized Data Loading
    
    private func loadAllPumpingDataParallel(forceRefresh: Bool) async {
        guard storageService.isSignedIn else {
            await MainActor.run {
                isLoading = false
                isLoadingWeekly = false
            }
            return
        }
        
        do {
            // Parallel API calls instead of sequential
            async let todaySessions = storageService.fetchTodayPumpingSessions(forceRefresh: forceRefresh)
            async let weeklyTotals = storageService.fetchPast7DaysPumpingTotals(forceRefresh: forceRefresh)
            
            let (sessions, totals) = try await (todaySessions, weeklyTotals)
            
            await MainActor.run {
                self.todayPumpingSessions = sessions.sorted { $0.fullDate > $1.fullDate }
                self.totalVolume = sessions.reduce(0) { $0 + $1.volume }
                self.weeklyTotals = totals
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
    
    private func loadTodaySessionsAsync(forceRefresh: Bool = true) async {
        guard storageService.isSignedIn else {
            await MainActor.run {
                isLoading = false
            }
            return
        }
        
        do {
            let sessions = try await storageService.fetchTodayPumpingSessions(forceRefresh: forceRefresh)
            await MainActor.run {
                self.todayPumpingSessions = sessions.sorted { $0.fullDate > $1.fullDate }
                self.totalVolume = sessions.reduce(0) { $0 + $1.volume }
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
            let totals = try await storageService.fetchPast7DaysPumpingTotals(forceRefresh: forceRefresh)
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
    
    // MARK: - Edit/Delete Actions
    
    private func editSession(_ session: PumpingEntry) {
        sessionToEdit = session
    }
    
    private func deleteSession(_ session: PumpingEntry) {
        sessionToDelete = session
        showDeleteAlert = true
    }
    
    private func performEdit(_ updatedSession: PumpingEntry) async {
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d/yyyy"
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            
            let date = dateFormatter.string(from: updatedSession.fullDate)
            let time = timeFormatter.string(from: updatedSession.fullDate)
            
            try await storageService.updatePumpingEntry(
                updatedSession,
                newDate: date,
                newTime: time,
                newVolume: String(updatedSession.volume)
            )
            
            // Reload data after successful edit
            await loadAllPumpingDataParallel(forceRefresh: true)
            sessionToEdit = nil
            
        } catch {
            await MainActor.run {
                sessionToEdit = nil
            }
        }
    }
    
    private func performDelete(_ session: PumpingEntry) async {
        do {
            try await storageService.deletePumpingEntry(session)
            
            // Reload data after successful delete
            await loadAllPumpingDataParallel(forceRefresh: true)
            
        } catch {
        }
        
        await MainActor.run {
            sessionToDelete = nil
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
                    .fixedSize(horizontal: true, vertical: false)

                Text(timeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(minWidth: 70, alignment: .leading)
            
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
                .symbolRenderingMode(.hierarchical)
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
    PumpingHistoryView(storageService: GoogleSheetsStorageService(), refreshTrigger: 0)
}