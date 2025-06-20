import AppIntents
import Foundation

struct LogFeedIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Feed"
    static var description = IntentDescription("Log a feeding entry with volume in MiniLog")
    
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = true
    
    @Parameter(title: "Volume", description: "Volume in mL")
    var volume: VolumeEntity
    
    // Simplified parameter summary - only volume
    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$volume) mL")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Validate volume
        guard volume.value > 0 && volume.value <= 1000 else {
            throw LogFeedError.invalidVolume
        }
        
        // Use last used formula type, fallback to default
        let lastFormulaType = UserDefaults.standard.string(forKey: "lastUsedFormulaType") ?? "Breast milk"
        
        // Check if user is signed in - if not, require opening the app
        let sheetsService = GoogleSheetsService()
        guard sheetsService.isSignedIn else {
            throw LogFeedError.notSignedIn
        }
        
        // Get current date and time
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let dateString = dateFormatter.string(from: now)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeString = timeFormatter.string(from: now)
        
        do {
            try await sheetsService.appendRow(
                date: dateString,
                time: timeString,
                volume: String(volume.value),
                formulaType: lastFormulaType
            )
            
            return .result(dialog: "Successfully logged \(volume.value) \(lastFormulaType)")
        } catch {
            throw LogFeedError.saveFailed(error.localizedDescription)
        }
    }
}

enum LogFeedError: LocalizedError {
    case invalidVolume
    case notSignedIn
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidVolume:
            return "Volume must be between 1 and 1000"
        case .notSignedIn:
            return "Please sign in to Google through the MiniLog app first"
        case .saveFailed(let message):
            return "Failed to save feed: \(message)"
        }
    }
}

struct VolumeEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Volume")
    static var defaultQuery = VolumeQuery()
    
    var id: Int
    var value: Int { id }
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(id)")
    }
}

struct VolumeQuery: EntityQuery {
    func entities(for identifiers: [Int]) async throws -> [VolumeEntity] {
        return identifiers.map { VolumeEntity(id: $0) }
    }
    
    func suggestedEntities() async throws -> [VolumeEntity] {
        return [40, 60, 80, 100, 120, 130, 150, 200].map { VolumeEntity(id: $0) }
    }
}

// App Shortcuts for zero-setup commands
struct FeedTrackerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogFeedIntent(),
            phrases: [
                "Log \(\.$volume) to \(.applicationName)",
                "Add \(\.$volume) to \(.applicationName)", 
                "Record \(\.$volume) feed in \(.applicationName)",
                "Log feed \(\.$volume) in \(.applicationName)",
                "Track \(\.$volume) with \(.applicationName)"
            ],
            shortTitle: "Log Feed",
            systemImageName: "drop.fill"
        )
    }
}