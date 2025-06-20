import SwiftUI
import GoogleSignIn
import AppIntents

@main
struct FeedTrackerApp: App {
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
            HorizontalNavigationView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
