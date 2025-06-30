import Foundation
import UIKit

/// Service for capturing real Google Sheets API responses for unit testing
/// This allows us to test against real data without hitting live APIs during tests
@MainActor
class DataCaptureService: ObservableObject {
    
    @Published var isCapturing = false
    @Published var capturedDataCount = 0
    @Published var lastCaptureDate: Date?
    
    private let fileManager = FileManager.default
    private var capturedData: [String: Any] = [:]
    
    // MARK: - Data Capture Control
    
    func startCapture() {
        isCapturing = true
        capturedData.removeAll()
        capturedDataCount = 0
        print("📊 DataCaptureService: Started capturing API responses")
    }
    
    func stopCapture() {
        isCapturing = false
        print("📊 DataCaptureService: Stopped capturing API responses")
    }
    
    // MARK: - Data Capture Methods
    
    func captureFeedData(feeds: [FeedEntry], source: String) {
        guard isCapturing else { return }
        
        let feedData = feeds.map { feed in
            [
                "date": feed.date,
                "time": feed.time,
                "volume": feed.volume,
                "formulaType": feed.formulaType,
                "wasteAmount": feed.wasteAmount
            ]
        }
        
        capturedData["feeds_\(source)"] = feedData
        capturedDataCount += 1
        print("📊 Captured \(feeds.count) feed entries from \(source)")
    }
    
    func captureFeedTotal(total: Int, source: String) {
        guard isCapturing else { return }
        
        capturedData["feed_total_\(source)"] = [
            "total": total,
            "captureTime": ISO8601DateFormatter().string(from: Date())
        ]
        capturedDataCount += 1
        print("📊 Captured feed total: \(total) mL from \(source)")
    }
    
    func capturePumpingData(sessions: [PumpingEntry], source: String) {
        guard isCapturing else { return }
        
        let sessionData = sessions.map { session in
            [
                "date": session.date,
                "time": session.time,
                "volume": session.volume
            ]
        }
        
        capturedData["pumping_\(source)"] = sessionData
        capturedDataCount += 1
        print("📊 Captured \(sessions.count) pumping sessions from \(source)")
    }
    
    func capturePumpingTotal(total: Int, source: String) {
        guard isCapturing else { return }
        
        capturedData["pumping_total_\(source)"] = [
            "total": total,
            "captureTime": ISO8601DateFormatter().string(from: Date())
        ]
        capturedDataCount += 1
        print("📊 Captured pumping total: \(total) mL from \(source)")
    }
    
    func captureWeeklyTotals(totals: [DailyTotal], source: String) {
        guard isCapturing else { return }
        
        let totalsData = totals.map { total in
            [
                "date": ISO8601DateFormatter().string(from: total.date),
                "volume": total.volume,
                "dayName": total.dayName,
                "shortDate": total.shortDate,
                "isToday": total.isToday,
                "isYesterday": total.isYesterday
            ]
        }
        
        capturedData["weekly_totals_\(source)"] = totalsData
        capturedDataCount += 1
        print("📊 Captured \(totals.count) daily totals from \(source)")
    }
    
    func captureRawSheetsResponse(data: Data, endpoint: String) {
        guard isCapturing else { return }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                capturedData["raw_\(endpoint)"] = json
                capturedDataCount += 1
                print("📊 Captured raw response from \(endpoint)")
            }
        } catch {
            print("📊 Failed to capture raw response from \(endpoint): \(error)")
        }
    }
    
    // MARK: - Export Data
    
    func exportCapturedData() -> URL? {
        guard !capturedData.isEmpty else {
            print("📊 No data to export")
            return nil
        }
        
        // Create metadata
        let metadata: [String: Any] = [
            "captureDate": ISO8601DateFormatter().string(from: Date()),
            "appVersion": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
            "buildNumber": Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown",
            "dataCount": capturedDataCount,
            "description": "Real FeedTracker API responses captured for unit testing"
        ]
        
        // Combine all data
        let exportData: [String: Any] = [
            "metadata": metadata,
            "capturedData": capturedData
        ]
        
        // Create JSON file
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            
            // Save to Documents directory for easy access via Files app
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "feedtracker_test_data_\(DateFormatter.filenameFormatter.string(from: Date())).json"
            let fileURL = documentsPath.appendingPathComponent(fileName)
            
            try jsonData.write(to: fileURL)
            
            lastCaptureDate = Date()
            print("📊 Exported captured data to: \(fileURL.path)")
            return fileURL
            
        } catch {
            print("📊 Failed to export captured data: \(error)")
            return nil
        }
    }
    
    // MARK: - Share Data
    
    func shareCapturedData() {
        guard let fileURL = exportCapturedData() else { return }
        
        // Present share sheet
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
            // Handle iPad presentation
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let filenameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM_dd_HH_mm_ss"
        return formatter
    }()
}