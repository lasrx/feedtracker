import Foundation
import GoogleSignIn
import Security

/// Google Sheets implementation of StorageServiceProtocol with enhanced OAuth handling
class GoogleSheetsStorageService: StorageServiceProtocol {
    @Published var isSignedIn = false
    @Published var userEmail: String?
    @Published var error: Error?
    @Published var currentConfiguration: StorageConfiguration?
    
    private var spreadsheetId = ""
    private let range = FeedConstants.GoogleSheets.feedRange
    private let pumpingRange = FeedConstants.GoogleSheets.pumpingRange
    private let scopes = FeedConstants.GoogleSheets.scopes
    
    // Enhanced OAuth properties
    private let tokenRefreshThreshold: TimeInterval = FeedConstants.tokenRefreshThreshold
    private let maxRetryAttempts = 3
    private let retryBaseDelay: TimeInterval = 1.0
    
    // Caching infrastructure
    private let dataCache = DataCache()
    
    // Debug data capture (optional - only used in debug builds)
    weak var dataCaptureService: DataCaptureService?
    
    init() {
        loadConfiguration()
        setupSpreadsheetIdObservation()
        setupTokenMonitoring()
        
        // Attempt to restore previous sign-in
        Task {
            await restorePreviousSignIn()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Configuration Management
    
    private func loadConfiguration() {
        if let savedSpreadsheetId = UserDefaults.standard.string(forKey: FeedConstants.UserDefaultsKeys.spreadsheetId) {
            self.spreadsheetId = savedSpreadsheetId
            self.currentConfiguration = StorageConfiguration(
                identifier: savedSpreadsheetId,
                name: "Current Spreadsheet",
                provider: .googleSheets
            )
        }
    }
    
    private func setupSpreadsheetIdObservation() {
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if let newId = UserDefaults.standard.string(forKey: FeedConstants.UserDefaultsKeys.spreadsheetId),
               newId != self?.spreadsheetId {
                self?.spreadsheetId = newId
                self?.currentConfiguration = StorageConfiguration(
                    identifier: newId,
                    name: "Current Spreadsheet",
                    provider: .googleSheets
                )
                    }
        }
    }
    
    // MARK: - Enhanced OAuth Management
    
    private func setupTokenMonitoring() {
        // Monitor app lifecycle for token validation
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.validateAndRefreshTokenIfNeeded()
            }
        }
    }
    
    private func restorePreviousSignIn() async {
        await MainActor.run {
            GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
                if let user = user {
                    self?.isSignedIn = true
                    self?.userEmail = user.profile?.email
                    
                    // Validate token immediately
                    Task {
                        await self?.validateAndRefreshTokenIfNeeded()
                    }
                } else if let error = error {
                    self?.error = StorageServiceError.authenticationFailed(error)
                }
            }
        }
    }
    
    private func validateAndRefreshTokenIfNeeded() async {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            await MainActor.run {
                self.isSignedIn = false
                self.userEmail = nil
            }
            return
        }
        
        // Check if token needs proactive refresh
        let expirationDate = user.accessToken.expirationDate
        let timeUntilExpiry = expirationDate?.timeIntervalSinceNow ?? 0
        
        if timeUntilExpiry < tokenRefreshThreshold {
            do {
                try await performTokenRefreshWithRetry(user: user)
            } catch {
                await MainActor.run {
                    self.error = StorageServiceError.authenticationFailed(error)
                }
            }
        }
    }
    
    private func performTokenRefreshWithRetry(user: GIDGoogleUser) async throws {
        var lastError: Error?
        
        for attempt in 1...maxRetryAttempts {
            do {
                try await user.refreshTokensIfNeeded()
                return // Success
            } catch {
                lastError = error
                
                if attempt < maxRetryAttempts {
                    let delay = retryBaseDelay * pow(2.0, Double(attempt - 1))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? StorageServiceError.authenticationFailed(NSError(domain: "GoogleSheetsStorageService", code: -1))
    }
    
    // MARK: - StorageServiceProtocol Implementation
    
    func signIn() async throws {
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = await windowScene.windows.first?.rootViewController else {
            throw StorageServiceError.configurationInvalid
        }
        
        let scopes = self.scopes
        
        // Use async alternative for modern concurrency
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootViewController,
                hint: nil,
                additionalScopes: scopes
            )
            
            // Update properties on main actor
            await MainActor.run {
                self.isSignedIn = true
                self.userEmail = result.user.profile?.email
                self.error = nil
            }
            
        } catch {
            throw StorageServiceError.authenticationFailed(error)
        }
    }
    
    func signOut() throws {
        GIDSignIn.sharedInstance.signOut()
        isSignedIn = false
        userEmail = nil
        error = nil
    }
    
    func updateConfiguration(_ config: StorageConfiguration) throws {
        guard config.provider == .googleSheets else {
            throw StorageServiceError.configurationInvalid
        }
        
        spreadsheetId = config.identifier
        currentConfiguration = config
        UserDefaults.standard.set(config.identifier, forKey: FeedConstants.UserDefaultsKeys.spreadsheetId)
    }
    
    // MARK: - API Request Helper
    
    private func performAuthenticatedRequest<T>(operation: (String) async throws -> T) async throws -> T {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw StorageServiceError.notSignedIn
        }
        
        // Enhanced token management with retry
        try await performTokenRefreshWithRetry(user: user)
        let accessToken = user.accessToken.tokenString
        
        do {
            return try await operation(accessToken)
        } catch {
            // If request fails, try refreshing token once more
            try await performTokenRefreshWithRetry(user: user)
            let refreshedToken = user.accessToken.tokenString
            return try await operation(refreshedToken)
        }
    }
    
    // MARK: - Feed Operations
    
    func appendFeed(date: String, time: String, volume: String, formulaType: String, wasteAmount: String = "0") async throws {
        try await performAuthenticatedRequest { accessToken in
            let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(range):append?valueInputOption=USER_ENTERED")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // 5-column model: Date, Time, Volume, Formula Type, Waste Amount
            let body: [String: Any] = [
                "values": [[date, time, volume, formulaType, wasteAmount]]
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StorageServiceError.networkError(NSError(domain: "InvalidResponse", code: -1))
            }
            
            if httpResponse.statusCode != 200 {
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorData["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw StorageServiceError.providerSpecific(message)
                }
                throw StorageServiceError.networkError(NSError(domain: "HTTPError", code: httpResponse.statusCode))
            }
        }
        
        // Invalidate related cache entries after successful append
        await dataCache.clear(forKey: CacheKeys.todayFeedTotal)
        await dataCache.clear(forKey: CacheKeys.todayFeeds)
        await dataCache.clear(forKey: CacheKeys.recentFeedEntries)
        await dataCache.clear(forKey: CacheKeys.past7DaysFeedTotals)
    }
    
    func fetchTodayFeedTotal(forceRefresh: Bool) async throws -> Int {
        // Check cache first unless force refresh is requested
        if !forceRefresh,
           let cachedTotal = await dataCache.retrieve(Int.self, forKey: CacheKeys.todayFeedTotal) {
            return cachedTotal
        }
        
        let total: Int = try await performAuthenticatedRequest { accessToken in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d/yyyy"
            let todayString = dateFormatter.string(from: Date())
            
            let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(range)")!
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StorageServiceError.networkError(NSError(domain: "InvalidResponse", code: -1))
            }
            
            if httpResponse.statusCode != 200 {
                throw StorageServiceError.networkError(NSError(domain: "HTTPError", code: httpResponse.statusCode))
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let values = json["values"] as? [[String]] else {
                return 0
            }
            
            var totalVolume = 0
            for row in values {
                if row.count >= 3,
                   row[0] == todayString,
                   let volume = Int(row[2]) {
                    totalVolume += volume
                }
            }
            
            return totalVolume
        }
        
        // Capture data for testing if capture service is available
        await dataCaptureService?.captureFeedTotal(total: total, source: "fetchTodayFeedTotal")
        
        // Cache the result
        await dataCache.store(total, forKey: CacheKeys.todayFeedTotal)
        return total
    }
    
    func fetchTodayFeeds(forceRefresh: Bool) async throws -> [FeedEntry] {
        // Check cache first unless force refresh is requested
        if !forceRefresh,
           let cachedFeeds = await dataCache.retrieve([FeedEntry].self, forKey: CacheKeys.todayFeeds) {
            return cachedFeeds
        }
        
        let feeds: [FeedEntry] = try await performAuthenticatedRequest { accessToken in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d/yyyy"
            let todayString = dateFormatter.string(from: Date())
            
            let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(range)")!
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StorageServiceError.networkError(NSError(domain: "InvalidResponse", code: -1))
            }
            
            if httpResponse.statusCode != 200 {
                throw StorageServiceError.networkError(NSError(domain: "HTTPError", code: httpResponse.statusCode))
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let values = json["values"] as? [[String]] else {
                return []
            }
            
            var todayFeeds: [FeedEntry] = []
            for (index, row) in values.enumerated() {
                // Support both 4-column (legacy) and 5-column (with waste) models
                if row.count >= 4,
                   row[0] == todayString,
                   let volume = Int(row[2]) {
                    let wasteAmount = row.count >= 5 ? Int(row[4]) ?? 0 : 0
                    let feedEntry = FeedEntry(
                        date: row[0],
                        time: row[1],
                        volume: volume,
                        formulaType: row[3],
                        wasteAmount: wasteAmount,
                        rowIndex: index + 1  // Google Sheets API uses 1-based indexing
                    )
                    todayFeeds.append(feedEntry)
                }
            }
            
            return todayFeeds
        }
        
        // Capture data for testing if capture service is available
        await dataCaptureService?.captureFeedData(feeds: feeds, source: "fetchTodayFeeds")
        
        // Cache the result
        await dataCache.store(feeds, forKey: CacheKeys.todayFeeds)
        return feeds
    }
    
    func fetchRecentFeedEntries(days: Int, forceRefresh: Bool) async throws -> [FeedEntry] {
        // Check cache first unless force refresh is requested
        if !forceRefresh,
           let cachedEntries = await dataCache.retrieve([FeedEntry].self, forKey: CacheKeys.recentFeedEntries) {
            return cachedEntries
        }
        
        let entries: [FeedEntry] = try await performAuthenticatedRequest { accessToken in
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d/yyyy"
            
            var recentDays: Set<String> = []
            for i in 0...days { // Include today plus requested number of days
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    recentDays.insert(dateFormatter.string(from: date))
                }
            }
            
            let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(range)")!
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StorageServiceError.networkError(NSError(domain: "InvalidResponse", code: -1))
            }
            
            if httpResponse.statusCode != 200 {
                throw StorageServiceError.networkError(NSError(domain: "HTTPError", code: httpResponse.statusCode))
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let values = json["values"] as? [[String]] else {
                return []
            }
            
            var feedEntries: [FeedEntry] = []
            for (index, row) in values.enumerated() {
                // Support both 4-column (legacy) and 5-column (with waste) models
                if row.count >= 4,
                   recentDays.contains(row[0]),
                   let volume = Int(row[2]) {
                    let wasteAmount = row.count >= 5 ? Int(row[4]) ?? 0 : 0
                    let feedEntry = FeedEntry(
                        date: row[0],
                        time: row[1],
                        volume: volume,
                        formulaType: row[3],
                        wasteAmount: wasteAmount,
                        rowIndex: index + 1
                    )
                    feedEntries.append(feedEntry)
                }
            }
            
            return feedEntries.sorted { $0.fullDate > $1.fullDate } // Most recent first
        }
        
        // Cache the result
        await dataCache.store(entries, forKey: CacheKeys.recentFeedEntries)
        return entries
    }
    
    func fetchPast7DaysFeedTotals(forceRefresh: Bool) async throws -> [DailyTotal] {
        // Check cache first unless force refresh is requested
        if !forceRefresh,
           let cachedTotals = await dataCache.retrieve([DailyTotal].self, forKey: CacheKeys.past7DaysFeedTotals) {
            return cachedTotals
        }
        
        let totals: [DailyTotal] = try await performAuthenticatedRequest { accessToken in
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d/yyyy"
            
            var past7Days: [Date] = []
            for i in 1...7 {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    past7Days.append(date)
                }
            }
            
            let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(range)")!
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StorageServiceError.networkError(NSError(domain: "InvalidResponse", code: -1))
            }
            
            if httpResponse.statusCode != 200 {
                throw StorageServiceError.networkError(NSError(domain: "HTTPError", code: httpResponse.statusCode))
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let values = json["values"] as? [[String]] else {
                return []
            }
            
            var dailyTotals: [DailyTotal] = []
            
            for date in past7Days {
                let dateString = dateFormatter.string(from: date)
                var dayTotal = 0
                
                for row in values {
                    if row.count >= 4,
                       row[0] == dateString,
                       let volume = Int(row[2]) {
                        dayTotal += volume
                    }
                }
                
                dailyTotals.append(DailyTotal(date: date, volume: dayTotal))
            }
            
            return dailyTotals.sorted { $0.date < $1.date }
        }
        
        // Capture data for testing if capture service is available  
        await dataCaptureService?.captureWeeklyTotals(totals: totals, source: "fetchPast7DaysFeedTotals")
        
        // Cache the result
        await dataCache.store(totals, forKey: CacheKeys.past7DaysFeedTotals)
        return totals
    }
    
    // MARK: - Pumping Operations
    
    func appendPumping(date: String, time: String, volume: String) async throws {
        try await performAuthenticatedRequest { accessToken in
            let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(pumpingRange):append?valueInputOption=USER_ENTERED")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "values": [[date, time, volume]]
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StorageServiceError.networkError(NSError(domain: "InvalidResponse", code: -1))
            }
            
            if httpResponse.statusCode != 200 {
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorData["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw StorageServiceError.providerSpecific(message)
                }
                throw StorageServiceError.networkError(NSError(domain: "HTTPError", code: httpResponse.statusCode))
            }
        }
        
        // Invalidate related cache entries after successful append
        await dataCache.clear(forKey: CacheKeys.todayPumpingTotal)
        await dataCache.clear(forKey: CacheKeys.todayPumpingSessions)
        await dataCache.clear(forKey: CacheKeys.past7DaysPumpingTotals)
    }
    
    func fetchTodayPumpingTotal(forceRefresh: Bool) async throws -> Int {
        // Check cache first unless force refresh is requested
        if !forceRefresh,
           let cachedTotal = await dataCache.retrieve(Int.self, forKey: CacheKeys.todayPumpingTotal) {
            return cachedTotal
        }
        
        let total: Int = try await performAuthenticatedRequest { accessToken in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d/yyyy"
            let todayString = dateFormatter.string(from: Date())
            
            let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(pumpingRange)")!
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StorageServiceError.networkError(NSError(domain: "InvalidResponse", code: -1))
            }
            
            if httpResponse.statusCode != 200 {
                throw StorageServiceError.networkError(NSError(domain: "HTTPError", code: httpResponse.statusCode))
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let values = json["values"] as? [[String]] else {
                return 0
            }
            
            var totalVolume = 0
            for row in values {
                if row.count >= 3,
                   row[0] == todayString,
                   let volume = Int(row[2]) {
                    totalVolume += volume
                }
            }
            
            return totalVolume
        }
        
        // Capture data for testing if capture service is available
        await dataCaptureService?.capturePumpingTotal(total: total, source: "fetchTodayPumpingTotal")
        
        // Cache the result
        await dataCache.store(total, forKey: CacheKeys.todayPumpingTotal)
        return total
    }
    
    func fetchTodayPumpingSessions(forceRefresh: Bool) async throws -> [PumpingEntry] {
        // Check cache first unless force refresh is requested
        if !forceRefresh,
           let cachedSessions = await dataCache.retrieve([PumpingEntry].self, forKey: CacheKeys.todayPumpingSessions) {
            return cachedSessions
        }
        
        let sessions: [PumpingEntry] = try await performAuthenticatedRequest { accessToken in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d/yyyy"
            let todayString = dateFormatter.string(from: Date())
            
            let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(pumpingRange)")!
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StorageServiceError.networkError(NSError(domain: "InvalidResponse", code: -1))
            }
            
            if httpResponse.statusCode != 200 {
                throw StorageServiceError.networkError(NSError(domain: "HTTPError", code: httpResponse.statusCode))
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let values = json["values"] as? [[String]] else {
                return []
            }
            
            var todaySessions: [PumpingEntry] = []
            for (index, row) in values.enumerated() {
                if row.count >= 3,
                   row[0] == todayString,
                   let volume = Int(row[2]) {
                    let pumpingEntry = PumpingEntry(
                        date: row[0],
                        time: row[1],
                        volume: volume,
                        rowIndex: index + 1  // Google Sheets API uses 1-based indexing
                    )
                    todaySessions.append(pumpingEntry)
                }
            }
            
            return todaySessions
        }
        
        // Capture data for testing if capture service is available
        await dataCaptureService?.capturePumpingData(sessions: sessions, source: "fetchTodayPumpingSessions")
        
        // Cache the result
        await dataCache.store(sessions, forKey: CacheKeys.todayPumpingSessions)
        return sessions
    }
    
    func fetchPast7DaysPumpingTotals(forceRefresh: Bool) async throws -> [DailyTotal] {
        // Check cache first unless force refresh is requested
        if !forceRefresh,
           let cachedTotals = await dataCache.retrieve([DailyTotal].self, forKey: CacheKeys.past7DaysPumpingTotals) {
            return cachedTotals
        }
        
        let totals: [DailyTotal] = try await performAuthenticatedRequest { accessToken in
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d/yyyy"
            
            var past7Days: [Date] = []
            for i in 1...7 {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    past7Days.append(date)
                }
            }
            
            let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(pumpingRange)")!
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StorageServiceError.networkError(NSError(domain: "InvalidResponse", code: -1))
            }
            
            if httpResponse.statusCode != 200 {
                throw StorageServiceError.networkError(NSError(domain: "HTTPError", code: httpResponse.statusCode))
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let values = json["values"] as? [[String]] else {
                return []
            }
            
            var dailyTotals: [DailyTotal] = []
            
            for date in past7Days {
                let dateString = dateFormatter.string(from: date)
                var dayTotal = 0
                
                for row in values {
                    if row.count >= 3,
                       row[0] == dateString,
                       let volume = Int(row[2]) {
                        dayTotal += volume
                    }
                }
                
                dailyTotals.append(DailyTotal(date: date, volume: dayTotal))
            }
            
            return dailyTotals.sorted { $0.date < $1.date }
        }
        
        // Capture data for testing if capture service is available
        await dataCaptureService?.captureWeeklyTotals(totals: totals, source: "fetchPast7DaysPumpingTotals")
        
        // Cache the result
        await dataCache.store(totals, forKey: CacheKeys.past7DaysPumpingTotals)
        return totals
    }
    
    // MARK: - Storage Management
    
    func fetchAvailableStorageOptions() async throws -> [StorageOption] {
        return try await performAuthenticatedRequest { accessToken in
            let urlString = "https://www.googleapis.com/drive/v3/files?q=mimeType='application/vnd.google-apps.spreadsheet'&fields=files(id,name,modifiedTime)&orderBy=modifiedTime desc"
            guard let url = URL(string: urlString) else {
                throw StorageServiceError.configurationInvalid
            }
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StorageServiceError.networkError(NSError(domain: "InvalidResponse", code: -1))
            }
            
            if httpResponse.statusCode != 200 {
                throw StorageServiceError.networkError(NSError(domain: "HTTPError", code: httpResponse.statusCode))
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let files = json["files"] as? [[String: Any]] else {
                return []
            }
            
            return files.compactMap { file in
                guard let id = file["id"] as? String,
                      let name = file["name"] as? String else {
                    return nil
                }
                
                let modifiedTime = file["modifiedTime"] as? String
                return StorageOption(
                    id: id,
                    name: name,
                    provider: .googleSheets,
                    lastModified: modifiedTime
                )
            }
        }
    }
    
    func createNewStorage(title: String) async throws -> String {
        return try await performAuthenticatedRequest { accessToken in
            let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let spreadsheetBody: [String: Any] = [
                "properties": [
                    "title": title
                ],
                "sheets": [
                    [
                        "properties": [
                            "title": "Feed Log"
                        ],
                        "data": [
                            [
                                "startRow": 0,
                                "startColumn": 0,
                                "rowData": [
                                    [
                                        "values": [
                                            ["userEnteredValue": ["stringValue": "Date"]],
                                            ["userEnteredValue": ["stringValue": "Time"]],
                                            ["userEnteredValue": ["stringValue": "Volume (mL)"]],
                                            ["userEnteredValue": ["stringValue": "Formula Type"]]
                                        ]
                                    ],
                                    [
                                        "values": [
                                            ["userEnteredValue": ["stringValue": "6/19/2025"]],
                                            ["userEnteredValue": ["stringValue": "09:30"]],
                                            ["userEnteredValue": ["numberValue": 120]],
                                            ["userEnteredValue": ["stringValue": "Breast milk"]]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ],
                    [
                        "properties": [
                            "title": "Pumping"
                        ],
                        "data": [
                            [
                                "startRow": 0,
                                "startColumn": 0,
                                "rowData": [
                                    [
                                        "values": [
                                            ["userEnteredValue": ["stringValue": "Date"]],
                                            ["userEnteredValue": ["stringValue": "Time"]],
                                            ["userEnteredValue": ["stringValue": "Volume (mL)"]]
                                        ]
                                    ],
                                    [
                                        "values": [
                                            ["userEnteredValue": ["stringValue": "6/19/2025"]],
                                            ["userEnteredValue": ["stringValue": "08:00"]],
                                            ["userEnteredValue": ["numberValue": 60]]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: spreadsheetBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StorageServiceError.networkError(NSError(domain: "InvalidResponse", code: -1))
            }
            
            if httpResponse.statusCode != 200 {
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorData["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw StorageServiceError.providerSpecific(message)
                }
                throw StorageServiceError.networkError(NSError(domain: "HTTPError", code: httpResponse.statusCode))
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let spreadsheetId = json["spreadsheetId"] as? String else {
                throw StorageServiceError.dataFormatError
            }
            
            return spreadsheetId
        }
    }
    
    // MARK: - Edit/Delete Operations
    
    func updateFeedEntry(_ entry: FeedEntry, newDate: String, newTime: String, newVolume: String, newFormulaType: String, newWasteAmount: String) async throws {
        guard let rowIndex = entry.rowIndex else {
            throw StorageServiceError.dataFormatError
        }
        
        let _: Void = try await performAuthenticatedRequest { accessToken in
            let updateRange = "A\(rowIndex):E\(rowIndex)"
            let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(updateRange)?valueInputOption=USER_ENTERED")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let values = [[newDate, newTime, newVolume, newFormulaType, newWasteAmount]]
            let body = ["values": values]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw StorageServiceError.networkError(NSError(domain: "HTTPError", code: (response as? HTTPURLResponse)?.statusCode ?? -1))
            }
            
            return ()
        }
        
        // Invalidate related cache entries after successful update
        await dataCache.clear(forKey: CacheKeys.todayFeedTotal)
        await dataCache.clear(forKey: CacheKeys.todayFeeds)
        await dataCache.clear(forKey: CacheKeys.recentFeedEntries)
        await dataCache.clear(forKey: CacheKeys.past7DaysFeedTotals)
    }
    
    func deleteFeedEntry(_ entry: FeedEntry) async throws {
        guard let rowIndex = entry.rowIndex else {
            throw StorageServiceError.dataFormatError
        }
        
        // Clear the row content instead of deleting the entire row for simplicity
        let _: Void = try await performAuthenticatedRequest { accessToken in
            let updateRange = "A\(rowIndex):E\(rowIndex)"
            let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(updateRange):clear")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw StorageServiceError.networkError(NSError(domain: "HTTPError", code: (response as? HTTPURLResponse)?.statusCode ?? -1))
            }
            
            return ()
        }
        
        // Invalidate related cache entries after successful delete
        await dataCache.clear(forKey: CacheKeys.todayFeedTotal)
        await dataCache.clear(forKey: CacheKeys.todayFeeds)
        await dataCache.clear(forKey: CacheKeys.recentFeedEntries)
        await dataCache.clear(forKey: CacheKeys.past7DaysFeedTotals)
    }
    
    func updatePumpingEntry(_ entry: PumpingEntry, newDate: String, newTime: String, newVolume: String) async throws {
        guard let rowIndex = entry.rowIndex else {
            throw StorageServiceError.dataFormatError
        }
        
        let _: Void = try await performAuthenticatedRequest { accessToken in
            let updateRange = "Pumping!A\(rowIndex):C\(rowIndex)"
            let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(updateRange)?valueInputOption=USER_ENTERED")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let values = [[newDate, newTime, newVolume]]
            let body = ["values": values]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw StorageServiceError.networkError(NSError(domain: "HTTPError", code: (response as? HTTPURLResponse)?.statusCode ?? -1))
            }
            
            return ()
        }
        
        // Invalidate related cache entries after successful update
        await dataCache.clear(forKey: CacheKeys.todayPumpingTotal)
        await dataCache.clear(forKey: CacheKeys.todayPumpingSessions)
        await dataCache.clear(forKey: CacheKeys.past7DaysPumpingTotals)
    }
    
    func deletePumpingEntry(_ entry: PumpingEntry) async throws {
        guard let rowIndex = entry.rowIndex else {
            throw StorageServiceError.dataFormatError
        }
        
        // For now, clear the row content instead of deleting the entire row
        // This is simpler and avoids the complexity of sheet ID lookups
        let _: Void = try await performAuthenticatedRequest { accessToken in
            let updateRange = "Pumping!A\(rowIndex):C\(rowIndex)"
            let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(updateRange):clear")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw StorageServiceError.networkError(NSError(domain: "HTTPError", code: (response as? HTTPURLResponse)?.statusCode ?? -1))
            }
            
            return ()
        }
        
        // Invalidate related cache entries after successful delete
        await dataCache.clear(forKey: CacheKeys.todayPumpingTotal)
        await dataCache.clear(forKey: CacheKeys.todayPumpingSessions)
        await dataCache.clear(forKey: CacheKeys.past7DaysPumpingTotals)
    }
}