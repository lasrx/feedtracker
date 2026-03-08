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
                // Deep link confirmation → stages Picker instead of connecting directly
                .alert("Connect to Tracker", isPresented: $storageService.showingDeepLinkConfirmation) {
                    Button("Cancel", role: .cancel) {
                        storageService.cancelDeepLinkConnection()
                    }
                    Button("Authorize & Connect") {
                        storageService.stagePickerForDeepLink()
                    }
                } message: {
                    Text("Connect MiniLog to \"\(storageService.pendingDeepLinkSheetName ?? "Shared Tracker")\"?\n\nYou'll select the sheet in a file picker to authorize access.")
                }
                // Picker for deep link authorization (with preselected file)
                .sheet(isPresented: $storageService.showingPickerForDeepLink) {
                    GooglePickerSheet(
                        storageService: storageService,
                        preselectedFileIds: storageService.pendingDeepLinkSheetId.map { [$0] }
                    ) { fileId, fileName in
                        storageService.completePickerAuthorization(fileId: fileId, fileName: fileName)
                    }
                }
                // Picker for 403 recovery (re-authorize current sheet)
                .sheet(isPresented: $storageService.needsPickerAuthorization) {
                    GooglePickerSheet(
                        storageService: storageService,
                        preselectedFileIds: storageService.pendingPickerSheetId.map { [$0] }
                    ) { fileId, fileName in
                        storageService.completePickerAuthorization(fileId: fileId, fileName: fileName)
                    }
                }
        }
    }
}
