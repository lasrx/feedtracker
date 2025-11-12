import Foundation

// MARK: - Storage Service Protocol

/// Abstract interface for data storage operations
/// Enables multiple storage providers (Google Sheets, Firebase, etc.)
@MainActor
protocol StorageServiceProtocol: AnyObject, ObservableObject {
    // MARK: - Authentication
    var isSignedIn: Bool { get }
    var userEmail: String? { get }
    var error: Error? { get }
    
    func signIn() async throws
    func signOut() throws
    
    // MARK: - Feed Operations
    func appendFeed(date: String, time: String, volume: String, formulaType: String, wasteAmount: String) async throws
    func fetchTodayFeedTotal(forceRefresh: Bool) async throws -> Int
    func fetchTodayFeeds(forceRefresh: Bool) async throws -> [FeedEntry]
    func fetchPast7DaysFeedTotals(forceRefresh: Bool) async throws -> [DailyTotal]
    func fetchRecentFeedEntries(days: Int, forceRefresh: Bool) async throws -> [FeedEntry]
    
    // MARK: - Pumping Operations
    func appendPumping(date: String, time: String, volume: String) async throws
    func fetchTodayPumpingTotal(forceRefresh: Bool) async throws -> Int
    func fetchTodayPumpingSessions(forceRefresh: Bool) async throws -> [PumpingEntry]
    func fetchPast7DaysPumpingTotals(forceRefresh: Bool) async throws -> [DailyTotal]
    
    // MARK: - Edit/Delete Operations
    func updateFeedEntry(_ entry: FeedEntry, newDate: String, newTime: String, newVolume: String, newFormulaType: String, newWasteAmount: String) async throws
    func deleteFeedEntry(_ entry: FeedEntry) async throws
    func updatePumpingEntry(_ entry: PumpingEntry, newDate: String, newTime: String, newVolume: String) async throws
    func deletePumpingEntry(_ entry: PumpingEntry) async throws
    
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

// MARK: - Caching Infrastructure

/// Cache entry with timestamp for staleness checking
struct CacheEntry<T> {
    let data: T
    let timestamp: Date
    let cacheKey: String
    
    /// Check if cache entry is stale (older than specified interval)
    func isStale(maxAge: TimeInterval) -> Bool {
        Date().timeIntervalSince(timestamp) > maxAge
    }
}

/// Thread-safe cache manager for storage operations
actor DataCache {
    private var cache: [String: Any] = [:]
    private let defaultMaxAge: TimeInterval = FeedConstants.cacheMaxAge
    
    /// Store data in cache with current timestamp
    func store<T>(_ data: T, forKey key: String) {
        let entry = CacheEntry(data: data, timestamp: Date(), cacheKey: key)
        cache[key] = entry
    }
    
    /// Retrieve cached data if not stale, otherwise return nil
    func retrieve<T>(_ type: T.Type, forKey key: String, maxAge: TimeInterval? = nil) -> T? {
        guard let entry = cache[key] as? CacheEntry<T> else { return nil }
        
        let ageLimit = maxAge ?? defaultMaxAge
        return entry.isStale(maxAge: ageLimit) ? nil : entry.data
    }
    
    /// Clear specific cache entry
    func clear(forKey key: String) {
        cache.removeValue(forKey: key)
    }
    
    /// Clear all cached data
    func clearAll() {
        cache.removeAll()
    }
    
    /// Clear stale entries older than maxAge
    func clearStale(maxAge: TimeInterval? = nil) {
        let ageLimit = maxAge ?? defaultMaxAge
        let keysToRemove = cache.compactMap { key, value -> String? in
            if let entry = value as? CacheEntry<Any> {
                return entry.isStale(maxAge: ageLimit) ? key : nil
            }
            return nil
        }
        
        for key in keysToRemove {
            cache.removeValue(forKey: key)
        }
    }
}

/// Cache keys for different data types
enum CacheKeys {
    static let todayFeedTotal = "today_feed_total"
    static let todayFeeds = "today_feeds"
    static let past7DaysFeedTotals = "past_7_days_feed_totals"
    static let recentFeedEntries = "recent_feed_entries"
    static let todayPumpingTotal = "today_pumping_total"
    static let todayPumpingSessions = "today_pumping_sessions"
    static let past7DaysPumpingTotals = "past_7_days_pumping_totals"
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