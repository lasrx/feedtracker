import Foundation

// MARK: - Feed Constants
/// Centralized constants for the feed tracking application
struct FeedConstants {
    
    // MARK: - Default Values
    static let defaultDailyVolumeGoal = 1000
    static let defaultFormulaTypes = ["Breast milk", "Similac 360", "Emfamil Neuropro"]
    static let defaultQuickVolumes = "40,60,130,150"
    
    // MARK: - UI Constants
    static let minimumTapTargetHeight: CGFloat = 44
    static let quickVolumeButtonWidth: CGFloat = 50
    static let quickVolumeButtonHeight: CGFloat = 40
    static let dragVolumeDisplayWidth: CGFloat = 120
    static let dragVolumeDisplayHeight: CGFloat = 60
    static let volumeTextFieldWidth: CGFloat = 80
    static let submitButtonHeight: CGFloat = 50
    static let pageIndicatorSize: CGFloat = 8
    static let pageIndicatorSpacing: CGFloat = 8
    static let pageIndicatorBottomPadding: CGFloat = 20
    
    // MARK: - Drag Gesture Constants
    static let maxVolumeLimit = 999
    static let minVolumeLimit = 0
    static let swipeThreshold: CGFloat = 50
    
    // MARK: - Haptic Constants
    static let hapticVolumeIncrement = 5  // mL increments for haptic feedback
    static let strongHapticIncrement = 25  // mL increments for stronger haptic
    
    // MARK: - Animation Constants
    static let springStiffness: Double = 300
    static let springDamping: Double = 30
    static let pageIndicatorAnimationDuration: Double = 0.2
    
    // MARK: - Time Constants
    static let backgroundRefreshThreshold: TimeInterval = 3600  // 1 hour in seconds
    
    // MARK: - Caching Constants
    static let cacheMaxAge: TimeInterval = 300  // 5 minutes - how long cached data stays fresh
    static let tokenRefreshThreshold: TimeInterval = 600  // 10 minutes before OAuth token expiry
    
    // MARK: - Drag Speed Settings
    enum DragSpeed: String, CaseIterable {
        case slow = "Slow"
        case `default` = "Default" 
        case fast = "Fast"
        
        var sensitivity: CGFloat {
            switch self {
            case .slow: return -3.0      // More precise, slower
            case .default: return -2.25  // Balanced speed (updated)
            case .fast: return -1.5      // Faster, less precise
            }
        }
        
        var description: String {
            switch self {
            case .slow: return "Slow"
            case .default: return "Default"
            case .fast: return "Fast"
            }
        }
    }
    
    // MARK: - UserDefaults Keys
    struct UserDefaultsKeys {
        static let dailyVolumeGoal = "dailyVolumeGoal"
        static let formulaTypes = "formulaTypes"
        static let hapticFeedbackEnabled = "hapticFeedbackEnabled"
        static let feedQuickVolumes = "feedQuickVolumes"
        static let pumpingQuickVolumes = "pumpingQuickVolumes"
        static let spreadsheetId = "spreadsheetId"
        static let lastUsedFormulaType = "lastUsedFormulaType"
        static let dragSpeed = "dragSpeed"
    }
    
    // MARK: - Date Formats
    struct DateFormats {
        static let sheetDate = "M/d/yyyy"
        static let displayTime = "h:mm a"  // 12-hour format with AM/PM
        static let combinedDateTime = "M/d/yyyy h:mm a"
        static let dayName = "EEE"  // Mon, Tue, Wed, etc.
        static let shortDate = "M/d"
    }
    
    // MARK: - Google Sheets Constants
    struct GoogleSheets {
        static let feedRange = "A:D"  // Date, Time, Volume (mL), Formula Type
        static let pumpingRange = "Pumping!A:C"  // Date, Time, Volume (mL)
        static let scopes = [
            "https://www.googleapis.com/auth/spreadsheets",
            "https://www.googleapis.com/auth/drive.file"
        ]
    }
    
    // MARK: - Color Scheme Support
    static let progressBarScaleY: CGFloat = 1.5
    static let accentOpacity: Double = 0.1
    static let secondaryOpacity: Double = 0.3
}