import SwiftUI
import GoogleSignIn
import AppIntents

@main
struct FeedTrackerApp: App {
    @StateObject private var storageService = GoogleSheetsStorageService()

    init() {
        // Configure Google Sign-In
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            fatalError("Google Sign-In configuration file not found")
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)

        // Register App Shortcuts
        FeedTrackerShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            HorizontalNavigationView(storageService: storageService)
                .onOpenURL { url in
                    // Try deep link first, fall back to Google Sign-In
                    if !storageService.handleDeepLink(url: url) {
                        GIDSignIn.sharedInstance.handle(url)
                    }
                }
                .alert("Connect to Tracker", isPresented: $storageService.showingDeepLinkConfirmation) {
                    Button("Cancel", role: .cancel) {
                        storageService.cancelDeepLinkConnection()
                    }
                    Button("Connect") {
                        storageService.confirmDeepLinkConnection()
                    }
                } message: {
                    Text("Connect MiniLog to \"\(storageService.pendingDeepLinkSheetName ?? "Shared Tracker")\"?\n\nThe sheet owner must also share the spreadsheet with you in Google Sheets.")
                }
        }
    }
}
