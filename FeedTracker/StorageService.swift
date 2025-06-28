import Foundation

// MARK: - Storage Service Protocol

/// Abstract interface for data storage operations
/// Enables multiple storage providers (Google Sheets, Firebase, etc.)
protocol StorageServiceProtocol: AnyObject, ObservableObject {
    // MARK: - Authentication
    var isSignedIn: Bool { get }
    var userEmail: String? { get }
    var error: Error? { get }
    
    func signIn() async throws
    func signOut() throws
    
    // MARK: - Feed Operations
    func appendFeed(date: String, time: String, volume: String, formulaType: String) async throws
    func fetchTodayFeedTotal() async throws -> Int
    func fetchTodayFeeds() async throws -> [FeedEntry]
    func fetchPast7DaysFeedTotals() async throws -> [DailyTotal]
    
    // MARK: - Pumping Operations
    func appendPumping(date: String, time: String, volume: String) async throws
    func fetchTodayPumpingTotal() async throws -> Int
    func fetchTodayPumpingSessions() async throws -> [PumpingEntry]
    func fetchPast7DaysPumpingTotals() async throws -> [DailyTotal]
    
    // MARK: - Configuration
    func updateConfiguration(_ config: StorageConfiguration) throws
    func fetchAvailableStorageOptions() async throws -> [StorageOption]
    func createNewStorage(title: String) async throws -> String
}

// MARK: - Configuration Models

struct StorageConfiguration {
    let identifier: String // Spreadsheet ID, Firebase project ID, etc.
    let name: String
    let provider: StorageProvider
}

struct StorageOption: Identifiable {
    let id: String
    let name: String
    let provider: StorageProvider
    let lastModified: String?
    
    var displayName: String { name }
}

enum StorageProvider: String, CaseIterable {
    case googleSheets = "google_sheets"
    case firebase = "firebase"
    case aws = "aws"
    
    var displayName: String {
        switch self {
        case .googleSheets: return "Google Sheets"
        case .firebase: return "Firebase"
        case .aws: return "AWS"
        }
    }
}

// MARK: - Storage Service Errors

enum StorageServiceError: LocalizedError {
    case notSignedIn
    case authenticationFailed(Error)
    case configurationInvalid
    case networkError(Error)
    case dataFormatError
    case permissionDenied
    case quotaExceeded
    case providerSpecific(String)
    
    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "Please sign in to continue"
        case .authenticationFailed(let error):
            return "Authentication failed: \(error.localizedDescription)"
        case .configurationInvalid:
            return "Storage configuration is invalid"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .dataFormatError:
            return "Data format error"
        case .permissionDenied:
            return "Permission denied"
        case .quotaExceeded:
            return "Storage quota exceeded"
        case .providerSpecific(let message):
            return message
        }
    }
}