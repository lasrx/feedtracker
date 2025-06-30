import SwiftUI

/// Debug view for capturing real API data for unit testing
/// Only shown in debug builds to capture real Google Sheets responses
struct DataCaptureView: View {
    @StateObject private var captureService = DataCaptureService()
    @ObservedObject var storageService: GoogleSheetsStorageService
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "externaldrive.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Test Data Capture")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Capture real API responses for unit testing")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Status
                VStack(spacing: 8) {
                    HStack {
                        Circle()
                            .fill(captureService.isCapturing ? Color.green : Color.gray)
                            .frame(width: 12, height: 12)
                        
                        Text(captureService.isCapturing ? "Capturing..." : "Ready to capture")
                            .font(.headline)
                            .foregroundColor(captureService.isCapturing ? .green : .primary)
                    }
                    
                    if captureService.capturedDataCount > 0 {
                        Text("\(captureService.capturedDataCount) data sets captured")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let lastCapture = captureService.lastCaptureDate {
                        Text("Last export: \(lastCapture, style: .relative) ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Controls
                VStack(spacing: 12) {
                    // Start/Stop Capture
                    if captureService.isCapturing {
                        Button(action: captureService.stopCapture) {
                            HStack {
                                Image(systemName: "stop.circle.fill")
                                Text("Stop Capturing")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                    } else {
                        Button(action: captureService.startCapture) {
                            HStack {
                                Image(systemName: "record.circle")
                                Text("Start Capturing")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                    }
                    
                    // Trigger Data Load
                    Button(action: loadSampleData) {
                        HStack {
                            Image(systemName: "arrow.down.circle")
                            Text("Load Sample Data")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(!storageService.isSignedIn)
                    
                    // Export Data
                    Button(action: captureService.shareCapturedData) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export & Share Data")
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .disabled(captureService.capturedDataCount == 0)
                }
                
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Instructions:")
                        .font(.headline)
                    
                    Text("1. Start capturing")
                    Text("2. Load sample data or use the app normally")
                    Text("3. Export & share the captured data")
                    Text("4. Save the file to add to unit tests")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                // Sign-in status
                if !storageService.isSignedIn {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Sign in to Google Sheets to capture real data")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Debug")
            .navigationBarTitleDisplayMode(.inline)
        }
        .environmentObject(captureService)
    }
    
    // MARK: - Data Loading
    
    private func loadSampleData() {
        guard storageService.isSignedIn else { return }
        
        Task {
            do {
                // Load today's feeds
                let todayFeeds = try await storageService.fetchTodayFeeds(forceRefresh: true)
                captureService.captureFeedData(feeds: todayFeeds, source: "today_feeds")
                
                // Load today's feed total
                let feedTotal = try await storageService.fetchTodayFeedTotal(forceRefresh: true)
                captureService.captureFeedTotal(total: feedTotal, source: "today_total")
                
                // Load weekly feed totals
                let weeklyTotals = try await storageService.fetchPast7DaysFeedTotals(forceRefresh: true)
                captureService.captureWeeklyTotals(totals: weeklyTotals, source: "weekly_feeds")
                
                // Load today's pumping sessions
                let pumpingSessions = try await storageService.fetchTodayPumpingSessions(forceRefresh: true)
                captureService.capturePumpingData(sessions: pumpingSessions, source: "today_pumping")
                
                // Load today's pumping total
                let pumpingTotal = try await storageService.fetchTodayPumpingTotal(forceRefresh: true)
                captureService.capturePumpingTotal(total: pumpingTotal, source: "today_pumping_total")
                
                // Load weekly pumping totals
                let weeklyPumpingTotals = try await storageService.fetchPast7DaysPumpingTotals(forceRefresh: true)
                captureService.captureWeeklyTotals(totals: weeklyPumpingTotals, source: "weekly_pumping")
                
                print("📊 Successfully loaded and captured sample data")
                
            } catch {
                print("📊 Error loading sample data: \(error)")
            }
        }
    }
}

#Preview {
    DataCaptureView(storageService: GoogleSheetsStorageService())
}