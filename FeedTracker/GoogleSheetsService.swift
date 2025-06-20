import Foundation
import GoogleSignIn

class GoogleSheetsService: ObservableObject {
    @Published var isSignedIn = false
    @Published var userEmail: String?
    @Published var error: Error?
    
    private var spreadsheetId = "1Et-xvX1mCv6xOEUAjGbgFERhWpx1t-RzjBDtwXZUSNw" // Default development spreadsheet
    private let range = "A:D" // Date, Time, Volume (mL), Formula Type
    private let pumpingRange = "Pumping!A:C" // Date, Time, Volume (mL) for pumping sheet
    private let scopes = ["https://www.googleapis.com/auth/spreadsheets", "https://www.googleapis.com/auth/drive.file"]
    
    init() {
        // Load spreadsheet ID from UserDefaults
        if let savedSpreadsheetId = UserDefaults.standard.string(forKey: "spreadsheetId") {
            self.spreadsheetId = savedSpreadsheetId
        }
        
        // Check if already signed in
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            if let user = user {
                self?.isSignedIn = true
                self?.userEmail = user.profile?.email
            }
        }
    }
    
    func updateSpreadsheetId(_ newId: String) {
        spreadsheetId = newId
        UserDefaults.standard.set(newId, forKey: "spreadsheetId")
    }
    
    func signIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController,
                                       hint: nil,
                                       additionalScopes: scopes) { [weak self] result, error in
            if let error = error {
                self?.error = error
                return
            }
            
            if let user = result?.user {
                self?.isSignedIn = true
                self?.userEmail = user.profile?.email
            }
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        isSignedIn = false
        userEmail = nil
    }
    
    func appendRow(date: String, time: String, volume: String, formulaType: String) async throws {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw SheetsServiceError.notSignedIn
        }
        
        // Refresh token if needed
        do {
            try await user.refreshTokensIfNeeded()
        } catch {
            throw SheetsServiceError.authenticationError(error)
        }
        
        let accessToken = user.accessToken.tokenString
        
        // Prepare the request
        let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(range):append?valueInputOption=USER_ENTERED")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create the body
        let body: [String: Any] = [
            "values": [[date, time, volume, formulaType]]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SheetsServiceError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw SheetsServiceError.apiError(message)
            }
            throw SheetsServiceError.httpError(httpResponse.statusCode)
        }
    }
    
    func fetchTodayTotal() async throws -> Int {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw SheetsServiceError.notSignedIn
        }
        
        // Refresh token if needed
        do {
            try await user.refreshTokensIfNeeded()
        } catch {
            throw SheetsServiceError.authenticationError(error)
        }
        
        let accessToken = user.accessToken.tokenString
        
        // Get today's date in the format used by the spreadsheet
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let todayString = dateFormatter.string(from: Date())
        
        // Fetch all data from the sheet
        let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(range)")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SheetsServiceError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw SheetsServiceError.httpError(httpResponse.statusCode)
        }
        
        // Parse the response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let values = json["values"] as? [[String]] else {
            return 0 // No data in sheet
        }
        
        // Sum up today's volumes
        var totalVolume = 0
        for row in values {
            // Skip header row and check if we have enough columns
            if row.count >= 3,
               row[0] == todayString,  // Date matches today
               let volume = Int(row[2]) {  // Volume is in column C (index 2)
                totalVolume += volume
            }
        }
        
        return totalVolume
    }
    
    func fetchTodayPumpingTotal() async throws -> Int {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw SheetsServiceError.notSignedIn
        }
        
        // Refresh token if needed
        do {
            try await user.refreshTokensIfNeeded()
        } catch {
            throw SheetsServiceError.authenticationError(error)
        }
        
        let accessToken = user.accessToken.tokenString
        
        // Get today's date in the format used by the spreadsheet
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let todayString = dateFormatter.string(from: Date())
        
        // Fetch all data from the pumping sheet
        let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(pumpingRange)")!
        print("fetchTodayPumpingTotal: Requesting URL: \(url)")
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SheetsServiceError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            print("fetchTodayPumpingTotal: HTTP error \(httpResponse.statusCode)")
            throw SheetsServiceError.httpError(httpResponse.statusCode)
        }
        
        // Parse the response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let values = json["values"] as? [[String]] else {
            print("fetchTodayPumpingTotal: No data found in pumping sheet")
            return 0 // No data in sheet
        }
        
        print("fetchTodayPumpingTotal: Found \(values.count) rows in pumping sheet, looking for date: \(todayString)")
        
        // Sum up today's volumes
        var totalVolume = 0
        for (index, row) in values.enumerated() {
            print("fetchTodayPumpingTotal: Row \(index): \(row)")
            // Skip header row and check if we have enough columns
            if row.count >= 3,
               row[0] == todayString,  // Date matches today
               let volume = Int(row[2]) {  // Volume is in column C (index 2)
                totalVolume += volume
                print("fetchTodayPumpingTotal: Added pumping entry: \(volume)mL at \(row[1])")
            }
        }
        
        print("fetchTodayPumpingTotal: Returning total: \(totalVolume)mL")
        return totalVolume
    }
    
    func fetchTodayPumpingSessions() async throws -> [PumpingEntry] {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw SheetsServiceError.notSignedIn
        }
        
        // Refresh token if needed
        do {
            try await user.refreshTokensIfNeeded()
        } catch {
            throw SheetsServiceError.authenticationError(error)
        }
        
        let accessToken = user.accessToken.tokenString
        
        // Get today's date in the format used by the spreadsheet
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let todayString = dateFormatter.string(from: Date())
        
        // Fetch all data from the pumping sheet
        let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(pumpingRange)")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SheetsServiceError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw SheetsServiceError.httpError(httpResponse.statusCode)
        }
        
        // Parse the response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let values = json["values"] as? [[String]] else {
            return [] // No data in sheet
        }
        
        // Convert today's entries to PumpingEntry objects
        var todaySessions: [PumpingEntry] = []
        for row in values {
            // Skip header row and check if we have enough columns
            if row.count >= 3,
               row[0] == todayString,  // Date matches today
               let volume = Int(row[2]) {  // Volume is in column C (index 2)
                let pumpingEntry = PumpingEntry(
                    date: row[0],
                    time: row[1],
                    volume: volume
                )
                todaySessions.append(pumpingEntry)
            }
        }
        
        return todaySessions
    }
    
    func appendPumpingRow(date: String, time: String, volume: String) async throws {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw SheetsServiceError.notSignedIn
        }
        
        // Refresh token if needed
        do {
            try await user.refreshTokensIfNeeded()
        } catch {
            throw SheetsServiceError.authenticationError(error)
        }
        
        let accessToken = user.accessToken.tokenString
        
        // Prepare the request
        let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(pumpingRange):append?valueInputOption=USER_ENTERED")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create the body
        let body: [String: Any] = [
            "values": [[date, time, volume]]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SheetsServiceError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw SheetsServiceError.apiError(message)
            }
            throw SheetsServiceError.httpError(httpResponse.statusCode)
        }
    }
    
    func fetchTodayFeeds() async throws -> [FeedEntry] {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw SheetsServiceError.notSignedIn
        }
        
        // Refresh token if needed
        do {
            try await user.refreshTokensIfNeeded()
        } catch {
            throw SheetsServiceError.authenticationError(error)
        }
        
        let accessToken = user.accessToken.tokenString
        
        // Get today's date in the format used by the spreadsheet
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let todayString = dateFormatter.string(from: Date())
        
        // Fetch all data from the sheet
        let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(range)")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SheetsServiceError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw SheetsServiceError.httpError(httpResponse.statusCode)
        }
        
        // Parse the response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let values = json["values"] as? [[String]] else {
            print("fetchTodayFeeds: No data found in sheet")
            return [] // No data in sheet
        }
        
        // Convert today's entries to FeedEntry objects
        var todayFeeds: [FeedEntry] = []
        for row in values {
            // Skip header row and check if we have enough columns
            if row.count >= 4,
               row[0] == todayString,  // Date matches today
               let volume = Int(row[2]) {  // Volume is in column C (index 2)
                let feedEntry = FeedEntry(
                    date: row[0],
                    time: row[1],
                    volume: volume,
                    formulaType: row[3]
                )
                todayFeeds.append(feedEntry)
            }
        }
        
        return todayFeeds
    }
    
    func fetchPast7DaysFeedTotals() async throws -> [DailyTotal] {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw SheetsServiceError.notSignedIn
        }
        
        // Refresh token if needed
        do {
            try await user.refreshTokensIfNeeded()
        } catch {
            throw SheetsServiceError.authenticationError(error)
        }
        
        let accessToken = user.accessToken.tokenString
        
        // Get date range for past 7 days (excluding today)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        
        // Create array of past 7 days (excluding today)
        var past7Days: [Date] = []
        for i in 1...7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                past7Days.append(date)
            }
        }
        
        // Fetch all data from the sheet
        let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(range)")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SheetsServiceError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw SheetsServiceError.httpError(httpResponse.statusCode)
        }
        
        // Parse the response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let values = json["values"] as? [[String]] else {
            return [] // No data in sheet
        }
        
        // Calculate daily totals for each of the past 7 days
        var dailyTotals: [DailyTotal] = []
        
        for date in past7Days {
            let dateString = dateFormatter.string(from: date)
            var dayTotal = 0
            
            for row in values {
                // Skip header row and check if we have enough columns
                if row.count >= 4,
                   row[0] == dateString,  // Date matches this day
                   let volume = Int(row[2]) {  // Volume is in column C (index 2)
                    dayTotal += volume
                }
            }
            
            dailyTotals.append(DailyTotal(date: date, volume: dayTotal))
        }
        
        // Return sorted by date (oldest first)
        return dailyTotals.sorted { $0.date < $1.date }
    }
    
    func fetchPast7DaysPumpingTotals() async throws -> [DailyTotal] {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw SheetsServiceError.notSignedIn
        }
        
        // Refresh token if needed
        do {
            try await user.refreshTokensIfNeeded()
        } catch {
            throw SheetsServiceError.authenticationError(error)
        }
        
        let accessToken = user.accessToken.tokenString
        
        // Get date range for past 7 days (excluding today)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        
        // Create array of past 7 days (excluding today)
        var past7Days: [Date] = []
        for i in 1...7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                past7Days.append(date)
            }
        }
        
        // Fetch all data from the pumping sheet
        let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(pumpingRange)")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SheetsServiceError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw SheetsServiceError.httpError(httpResponse.statusCode)
        }
        
        // Parse the response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let values = json["values"] as? [[String]] else {
            return [] // No data in sheet
        }
        
        // Calculate daily totals for each of the past 7 days
        var dailyTotals: [DailyTotal] = []
        
        for date in past7Days {
            let dateString = dateFormatter.string(from: date)
            var dayTotal = 0
            
            for row in values {
                // Skip header row and check if we have enough columns
                if row.count >= 3,
                   row[0] == dateString,  // Date matches this day
                   let volume = Int(row[2]) {  // Volume is in column C (index 2)
                    dayTotal += volume
                }
            }
            
            dailyTotals.append(DailyTotal(date: date, volume: dayTotal))
        }
        
        // Return sorted by date (oldest first)
        return dailyTotals.sorted { $0.date < $1.date }
    }
    
    func createNewFeedTrackingSheet(title: String = "Feed Tracking") async throws -> String {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw SheetsServiceError.notSignedIn
        }
        
        // Refresh token if needed
        do {
            try await user.refreshTokensIfNeeded()
        } catch {
            throw SheetsServiceError.authenticationError(error)
        }
        
        let accessToken = user.accessToken.tokenString
        
        // Create new spreadsheet with template
        let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create spreadsheet body with headers and sample data
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
            throw SheetsServiceError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw SheetsServiceError.apiError(message)
            }
            throw SheetsServiceError.httpError(httpResponse.statusCode)
        }
        
        // Parse response to get spreadsheet ID
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let spreadsheetId = json["spreadsheetId"] as? String else {
            throw SheetsServiceError.invalidResponse
        }
        
        return spreadsheetId
    }
    
    func fetchUserSpreadsheets() async throws -> [SpreadsheetInfo] {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw SheetsServiceError.notSignedIn
        }
        
        // Refresh token if needed
        do {
            try await user.refreshTokensIfNeeded()
        } catch {
            throw SheetsServiceError.authenticationError(error)
        }
        
        let accessToken = user.accessToken.tokenString
        
        // Use Google Drive API to list spreadsheets
        let urlString = "https://www.googleapis.com/drive/v3/files?q=mimeType='application/vnd.google-apps.spreadsheet'&fields=files(id,name,modifiedTime)&orderBy=modifiedTime desc"
        guard let url = URL(string: urlString) else {
            throw SheetsServiceError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SheetsServiceError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw SheetsServiceError.httpError(httpResponse.statusCode)
        }
        
        // Parse the response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let files = json["files"] as? [[String: Any]] else {
            return []
        }
        
        // Convert to SpreadsheetInfo objects
        return files.compactMap { file in
            guard let id = file["id"] as? String,
                  let name = file["name"] as? String else {
                return nil
            }
            
            let modifiedTime = file["modifiedTime"] as? String
            return SpreadsheetInfo(id: id, name: name, modifiedTime: modifiedTime)
        }
    }
}

struct SpreadsheetInfo: Identifiable {
    let id: String
    let name: String
    let modifiedTime: String?
    
    var displayName: String {
        return name
    }
    
    var lastModified: String {
        guard let modifiedTime = modifiedTime else { 
            return "" 
        }
        
        // Try ISO8601 formatter with fractional seconds
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: modifiedTime) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }
        
        // Fallback: try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: modifiedTime) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }
        
        return ""
    }
}

enum SheetsServiceError: LocalizedError {
    case notSignedIn
    case noAccessToken
    case authenticationError(Error)
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "Please sign in to Google"
        case .noAccessToken:
            return "Unable to get access token"
        case .authenticationError(let error):
            return "Authentication failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}
