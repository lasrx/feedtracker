# MiniLog – Feed Tracker iOS App

A SwiftUI-based iOS application for tracking baby feeding data with Google Sheets integration.

## Project Overview

MiniLog is designed to help parents log baby feeding information quickly and efficiently. The app uses Google Sheets as a backend database, enabling multi-device synchronization and easy data analysis.

### Core Features
- **Feed Tracking** - Quick volume entry, drag gestures, customizable presets
- **Full CRUD Operations** - Edit and delete individual feed entries and pumping sessions with swipe gestures
- **Multi-View Dashboard** - Four-pane swipe navigation (Feed entry, History, Pumping, Analytics)
- **Stacked Formula Charts** - 7-day visualization with formula type breakdown and dynamic colors
- **Google Sheets Integration** - Real-time sync, multi-device access, row-based editing
- **Intelligent Caching** - Smart cache system that significantly reduces API calls
- **Haptic Feedback** - Centralized system with configurable drag speeds and tactile precision
- **Waste Tracking** - Milk waste monitoring with feed-to-waste conversion
- **Siri Integration** - Voice commands ("Log 100 to MiniLog")
- **Multi-Caregiver Sharing** - Share sheets via deep links for instant multi-device setup
- **My Sheets Browser** - Browse and connect existing Google Sheets from Drive
- **Configurable** - Custom volumes, formula types, daily goals, haptic preferences, drag speeds
- **Multi-Layer Security** - Pre-commit hooks and GitHub Actions protect against credential leaks

## Technical Architecture

### Core Technologies
- **SwiftUI** - Declarative UI framework with iOS 26 visual enhancements
- **Google Sign-In SDK** - OAuth authentication with async/await APIs
- **Google Sheets API v4** - Data persistence with intelligent caching
- **App Intents Framework** - Siri integration (iOS 16+)
- **Async/await** - Modern concurrency with @MainActor isolation
- **Thread-Safe Caching** - DataCache actor with configurable expiration
- **Swift 6 Concurrency** - Full compliance with strict concurrency checking

### Visual Design Language
- **iOS 26 Liquid Glass** - Translucent material backgrounds with depth effects
- **Hierarchical SF Symbols** - Enhanced icon rendering for visual depth
- **Adaptive Animations** - Contextual symbol effects and smooth transitions
- **Backward Compatible** - Graceful degradation to iOS 18.5+

### Project Structure
```
feedtracker/
├── README.md                   # Project overview and setup guide
├── SETUP.md                    # Detailed configuration instructions
├── CLAUDE.md                   # Developer documentation
├── SECURITY.md                 # Security guidelines and incident response
├── SECURITY_IMPLEMENTATION.md  # Security system implementation guide
├── Privacy.md                  # Privacy policy and data handling
├── TERMS.md                    # Terms of Use and service limitations
├── LICENSE                     # Apache 2.0 license
├── .github/workflows/          # GitHub Actions security enforcement
├── git-hooks/                  # Security git hooks and installer
└── FeedTracker/               # Source code directory
    ├── FeedTrackerApp.swift           # App entry point and configuration
    ├── HorizontalNavigationView.swift # Four-pane swipe navigation
    ├── ContentView.swift              # Root view wrapper
    │
    ├── Shared Components
    ├── FeedEntryForm.swift            # Feed entry UI component
    ├── FeedEntryViewModel.swift       # Feed business logic with app lifecycle
    ├── PumpingEntryViewModel.swift    # Pumping business logic with app lifecycle
    ├── FeedConstants.swift            # Centralized constants and user preferences
    ├── HapticHelper.swift             # Haptic feedback system
    ├── SwipeActionsView.swift         # Generic swipe-to-edit/delete component
    ├── FeedEditSheet.swift            # Modal feed entry editor
    ├── PumpingEditSheet.swift         # Modal pumping session editor
    │
    ├── Views & Features
    ├── FeedHistoryView.swift          # Feed analytics with stacked charts and CRUD
    ├── PumpingView.swift              # Pumping session logger
    ├── PumpingHistoryView.swift       # Pumping analytics and insights with CRUD
    ├── WeeklySummaryView.swift        # Trend analysis charts
    ├── StackedWeeklySummaryView.swift # Stacked bar charts by formula type
    ├── MySheetsPickerView.swift       # Drive-powered sheet browser
    ├── SettingsView.swift             # App configuration with share and deep link support
    ├── FormulaTypesEditorView.swift   # Formula type list editor
    ├── QuickVolumesEditorView.swift   # Volume preset editor
    ├── DataCaptureView.swift          # Data capture interface
    │
    ├── Services & Models
    ├── StorageService.swift           # Protocol abstraction with CRUD operations
    ├── GoogleSheetsStorageService.swift # Google Sheets API integration
    ├── DataCaptureService.swift       # Data capture service
    ├── Models.swift                   # Core data models with row tracking
    ├── ChartModels.swift              # Chart-specific models and processing
    ├── Utilities.swift                # Shared utilities
    ├── LogFeedIntent.swift            # Siri Shortcuts integration
    │
    └── Configuration
        ├── Info.plist                # App configuration
        ├── Assets.xcassets/           # App icons and assets
        └── GoogleService-Info.plist   # OAuth credentials (git-ignored)
```

### Data Model
**Feed Log Sheet:**
- **A**: Date (M/d/yyyy format)
- **B**: Time (h:mm a format - 12-hour with AM/PM)
- **C**: Volume (numeric - positive for feeds, negative for waste entries)
- **D**: Formula Type (text)
- **E**: Waste Amount (numeric - positive value for actual waste amount)

**Pumping Sheet:**
- **A**: Date (M/d/yyyy format)
- **B**: Time (h:mm a format - 12-hour with AM/PM)
- **C**: Volume (numeric only, no units)

### Security Architecture
The app implements multi-layer security to protect sensitive OAuth credentials and API keys:

#### Pre-Commit Protection
- **File Pattern Blocking** - Prevents commits of `GoogleService-Info.plist`, `*.key`, `*.pem`, `.env` files (except templates)
- **Content Pattern Scanning** - Detects 13 credential patterns (API keys, tokens, OAuth clients, database URLs)

#### Automatic Data Protection
- **Smart Backup System** - Sensitive values stored in `.git/sensitive_backup` before removal
- **Post-Commit Restoration** - OAuth client ID automatically restored for development after each commit
- **Template File Support** - Allows `.env.example` and `.env.local.template` for documentation
- **Commit Message Filtering** - Blocks unwanted AI attribution patterns per user preference
- **AI Assistant Guidance** - Blocking messages educate AI tools about automatic OAuth handling

#### GitHub Actions Security Scanning
- **Server-side enforcement** that cannot be bypassed locally
- **Pattern matching** for the same 13 credential types as local hooks
- **Automatic PR blocking** if sensitive data detected

All commits are automatically scanned for API keys, OAuth credentials, and sensitive files before being allowed into the repository.

## TODO / Roadmap

### High Priority
- [ ] Add data validation (prevent future dates, negative volumes)
- [ ] Offline queue for entries when no connection

### Medium Priority
- [ ] Feeding pattern analysis and insights
- [ ] Age-appropriate peer comparisons (anonymized)
- [ ] Predictive feeding recommendations
- [ ] Multiple baby profiles support
- [ ] Pediatrician report generation
- [ ] Smart feeding reminders based on patterns

### Nice to Have
- [ ] Watch app companion
- [ ] Widget for quick entry
- [ ] Enhanced Siri natural language processing
- [ ] iCloud backup of preferences
- [ ] Alexa skill integration (original goal)

## Security Considerations

**IMPORTANT**: This repository contains sensitive configuration files that must NOT be committed to version control.

### Protected Files
- **GoogleService-Info.plist** - Contains OAuth client secrets
- **Environment files** - `.env*` files (except `.env.example` and `.env.local.template`)
- **Key files** - `*.key`, `*.pem`, `*.p12` certificates and private keys
- **Secret files** - `secrets.*`, `api_keys.*`, `credentials.*`, `config.local.*`
- **Any .xcconfig files** - May contain API keys or build secrets
- **Provisioning profiles** - Contain certificates and team IDs

### Before Cloning/Forking
1. The `.gitignore` file protects these sensitive files
2. You'll need to create your own `GoogleService-Info.plist` from Google Cloud Console
3. Never commit authentication credentials or API keys
4. Use environment variables or secure config files for production deployments

### For Contributors
- Always check what files you're staging before commits
- Use `git status` to verify no sensitive files are tracked
- If you accidentally commit secrets, rotate them immediately

## Development Setup

**IMPORTANT**: This repository contains placeholder values for OAuth configuration. See [SETUP.md](SETUP.md) for complete setup instructions.

### Quick Start
1. Clone the repository
2. Follow the detailed setup guide in [SETUP.md](SETUP.md)
3. Open the project in Xcode and build

### Prerequisites
- Xcode 16+
- iOS 18.5+ deployment target
- Google Cloud Console account with APIs enabled
- Your own OAuth 2.0 credentials

### Package Dependencies
The project uses Swift Package Manager with these dependencies (automatically resolved):
- GoogleSignIn-iOS
- AppAuth-iOS
- GoogleUtilities
- GTMAppAuth

## Design Decisions

### Why Google Sheets?
- Free, reliable backend
- Easy data analysis and sharing
- Multi-device sync out of the box
- No server maintenance required
- Export capabilities built-in

### UI/UX Choices
- **Large touch targets** (44pt minimum) for one-handed use
- **Haptic feedback** for tactile confirmation while holding baby
- **Quick buttons** for common volumes reduce typing
- **Drag gesture** allows fine-tuning without keyboard
- **Simple form layout** for fast data entry

### Technical Choices
- **SwiftUI over UIKit** - Modern, less code, better previews
- **Async/await** - Cleaner than callbacks for API calls
- **@StateObject** for service layer - Proper lifecycle management
- **No external dependencies** beyond Google SDK - Simpler maintenance

## Learning Resources

### For iOS Development
- [Apple SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Hacking with Swift](https://www.hackingwithswift.com/100/swiftui)
- [Swift by Sundell](https://www.swiftbysundell.com)

### For Google APIs
- [Google Sheets API Documentation](https://developers.google.com/sheets/api)
- [Google Sign-In iOS Guide](https://developers.google.com/identity/sign-in/ios)

### For AI-Assisted Development
- Use Claude for architecture decisions and learning concepts
- Use GitHub Copilot or Claude Code for implementation details
- Always understand the code you're committing

## Future Considerations

### Current Architecture
The app uses Google Sheets as a free, reliable backend that provides:
- Zero infrastructure costs
- Complete user data ownership
- Built-in export capabilities
- Multi-device synchronization
- No server maintenance required

### Potential Improvements
- **Offline capabilities** - Local data queuing when network unavailable
- **Improved OAuth flow** - Streamlined authentication experience
- **Analytics** - Built-in insights and trend analysis within the app
- **Additional integrations** - Health app connectivity, Apple Watch support

## Support & Contact

For questions, feedback, or support:
- **Email:** minilog-feedtracker@googlegroups.com
- **Issues:** https://github.com/lasrx/feedtracker/issues

## Contributing

This is a personal project, but if you'd like to contribute:
1. Fork the repository
2. Create a feature branch
3. Test thoroughly with your own Google Sheets
4. Submit a pull request with clear description

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

### What this means:
- **Free to use** - Use for personal or commercial projects
- **Attribution required** - Must credit original work
- **Patent protection** - Contributors grant patent rights
- **Modification allowed** - Can modify and distribute changes
- **Private use** - Can use privately without sharing changes

The Apache 2.0 license ensures proper attribution while enabling open collaboration and innovation.

---

*Built with ❤️ for tired parents everywhere*
