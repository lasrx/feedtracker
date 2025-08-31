# MiniLog – Feed Tracker iOS App

A SwiftUI-based iOS application for tracking baby feeding data with Google Sheets integration.

## Project Overview

MiniLog is designed to help parents log baby feeding information quickly and efficiently. The app uses Google Sheets as a backend database, enabling multi-device synchronization and easy data analysis.

### Core Features
- 🍼 **Smart Feed Tracking** - Quick volume entry, drag gestures, customizable presets
- ✏️ **Full CRUD Operations** - Edit and delete individual feed entries and pumping sessions with swipe gestures
- 📊 **Multi-View Dashboard** - Four-pane swipe navigation (Feed entry, History, Pumping, Analytics)
- 📈 **Stacked Formula Charts** - Advanced 7-day visualization with formula type breakdown and dynamic colors
- 🗂️ **Google Sheets Integration** - Real-time sync, automatic backups, multi-device access, row-based editing
- ⚡ **Intelligent Caching** - 80-90% API reduction with 5-minute smart cache system
- 🔊 **Enhanced Haptic Feedback** - Centralized system with configurable drag speeds and optimal tactile precision
- 🗑️ **Waste Tracking** - Advanced milk waste monitoring with 2-hour expiration awareness
- 📱 **Siri Integration** - Natural voice commands ("Log 100 to MiniLog")
- ⚙️ **Highly Configurable** - Custom volumes, formula types, daily goals, haptic preferences, drag speeds
- 🔒 **Enterprise-Grade Security** - Multi-layer protection against credential leaks

## Technical Architecture

### Core Technologies
- **SwiftUI** - Modern declarative UI framework
- **Google Sign-In SDK** - OAuth authentication with enhanced token refresh
- **Google Sheets API v4** - Data persistence with intelligent caching
- **App Intents Framework** - Natural language Siri integration (iOS 16+)
- **Async/await** - Modern concurrency with actor-based caching
- **Thread-Safe Caching** - DataCache actor with configurable expiration

### Project Structure
```
feedtracker/
├── README.md                   # Project overview and setup guide
├── SETUP.md                    # Detailed configuration instructions  
├── CLAUDE.md                   # Developer documentation
├── SECURITY.md                 # Security guidelines and incident response
├── Privacy.md                  # Privacy policy and data handling
├── LICENSE                     # Apache 2.0 license
├── .github/workflows/          # GitHub Actions security enforcement
└── FeedTracker/               # Source code directory
    ├── FeedTrackerApp.swift           # App entry point & configuration (29 lines)
    ├── HorizontalNavigationView.swift # Four-pane swipe navigation (125 lines)
    ├── ContentView.swift              # Main feed entry (34 lines - 97% reduction!)
    │
    ├── 🎯 Shared Components (MVVM Architecture)
    ├── FeedEntryForm.swift            # Shared UI component (312 lines)
    ├── FeedEntryViewModel.swift       # Feed business logic with app lifecycle (318 lines)
    ├── PumpingEntryViewModel.swift    # Pumping business logic with app lifecycle (266 lines)
    ├── FeedConstants.swift            # Centralized constants (103 lines)
    ├── HapticHelper.swift             # Multi-tier haptic system (246 lines)
    ├── SwipeActionsView.swift         # Generic swipe-to-edit/delete component (91 lines)
    ├── FeedEditSheet.swift            # Modal feed entry editor (180+ lines)
    ├── PumpingEditSheet.swift         # Modal pumping session editor (120+ lines)
    │
    ├── 📊 Views & Features
    ├── FeedHistoryView.swift          # Feed analytics with stacked charts & edit/delete (493 lines)
    ├── PumpingView.swift              # Pumping session logger with MVVM pattern (180 lines)
    ├── PumpingHistoryView.swift       # Pumping analytics & insights with edit/delete (350+ lines)
    ├── WeeklySummaryView.swift        # Reusable trend analysis (189 lines)
    ├── StackedWeeklySummaryView.swift # Advanced stacked bar charts (303 lines)
    ├── SettingsView.swift             # App configuration (372 lines)
    ├── SpreadsheetPickerView.swift    # Google Sheets browser (249 lines)
    │
    ├── 🔧 Services & Models
    ├── StorageService.swift           # Protocol abstraction with CRUD operations (174 lines)
    ├── GoogleSheetsStorageService.swift # Google Sheets API integration with full CRUD (1039 lines)
    ├── Models.swift                   # Core data models with row tracking (90+ lines)
    ├── ChartModels.swift              # Chart-specific models and processing (120+ lines)
    ├── Utilities.swift                # Shared utilities (11 lines)
    ├── LogFeedIntent.swift            # Siri Shortcuts (iOS 16+) (113 lines)
    │
    └── 📱 Configuration
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
The app implements enterprise-grade security to protect sensitive OAuth credentials and API keys:

#### Multi-Layer Pre-Commit Protection
- **File Pattern Blocking** - Prevents commits of `GoogleService-Info.plist`, `*.key`, `*.pem`, `.env` files (except templates)
- **Content Pattern Scanning** - Detects 13+ credential patterns (API keys, tokens, OAuth clients, database URLs)

#### Automatic Data Protection
- **Smart Backup System** - Sensitive values stored in `.git/sensitive_backup` before removal
- **Post-Commit Restoration** - OAuth client ID automatically restored for development after each commit
- **Template File Support** - Allows `.env.example` and `.env.local.template` for documentation
- **Commit Message Filtering** - Blocks unwanted AI attribution patterns per user preference
- **AI Assistant Guidance** - Blocking messages educate AI tools about automatic OAuth handling

#### GitHub Actions Security Scanning
- **Server-side enforcement** that cannot be bypassed locally
- **Pattern matching** for the same 13+ credential types as local hooks
- **Automatic PR blocking** if sensitive data detected

All commits are automatically scanned for API keys, OAuth credentials, and sensitive files before being allowed into the repository.

## Current Implementation Status

### Working Features
1. **Authentication Flow**
   - Sign in/out with Google
   - Persistent authentication state
   - Scoped permissions for Sheets API

2. **Data Entry**
   - Date/time pickers (default to current)
   - Volume entry via text field or drag gesture
   - Quick volume buttons
   - Formula type picker

3. **Voice Logging (Siri Shortcuts)**
   - Natural language commands without pronunciation issues
   - Supported phrases: "Log 100 to MiniLog", "Add 150 to MiniLog", "Track 120 with MiniLog"
   - Uses last selected formula type automatically
   - No "mL" pronunciation confusion

4. **Google Sheets Integration**
   - **Three setup options**: Create new sheets, browse existing sheets, or manual entry
   - **Incremental permissions**: App Store ready with non-sensitive scopes, optional restricted scopes for advanced features
   - **Sheet name persistence**: Human-readable names displayed in Settings
   - Append new rows to spreadsheet
   - Fetch today's total from all entries
   - **Full CRUD operations** - Edit and delete individual entries with row-based targeting
   - **Row index tracking** - Maintain Google Sheets row positions for precise modifications
   - Handle API errors gracefully
   - Create new tracking sheets with proper template
   - Browse and select from available spreadsheets

5. **Edit/Delete Operations**
   - **Swipe-to-edit** - Context-aware swipe gestures on entries reveal Edit/Delete buttons
   - **Context menu fallback** - Long press for accessibility
   - **Comprehensive editing** - Modify date, time, volume, formula type, and waste amount
   - **Feed ↔ Waste conversion** - Toggle between feed and waste entries with proper negative volume storage
   - **Modal edit forms** - Full-featured editors with native iOS controls and streamlined arrow-based volume controls
   - **Safe deletion** - Confirmation alerts with entry details
   - **Instant sync** - Changes immediately reflected in Google Sheets
   - **Smart cache invalidation** - Automatic cache clearing after modifications

6. **User Experience**
   - Precision drag slider optimized for feeding volumes (3 pixels per 1mL)
   - Smart haptic feedback system with configurable intensity
   - Success/error alerts with haptic confirmation
   - Loading states during API calls
   - Pull-to-refresh for totals
   - Auto-refresh interface after returning from 1+ hour absence
   - Enhanced Settings page with haptic preferences and UI controls

### Latest Release: Performance-Optimized Full CRUD Operations & Advanced Analytics

#### ⚡ Performance Optimization System
- **Chart rendering optimized** - ~90% faster through smart caching and background processing  
- **API call consolidation** - 66% reduction in network requests with single comprehensive calls
- **Parallel processing** - Concurrent API calls for 50% faster data loading
- **Smart caching** - Hash-based change detection prevents unnecessary recomputation
- **Today included in charts** - Real-time progress visibility with partial day data

#### ✏️ Complete Edit/Delete System
- **Full CRUD operations** - Edit and delete individual feed entries and pumping sessions
- **Optimized swipe gestures** - Context-aware swipe directions (left-to-right on left panes, right-to-left on right panes) with context menu fallback
- **Gesture conflict resolution** - Competing gesture priorities allow both list swipes and navigation to work reliably
- **Row-based Google Sheets targeting** - Precise modifications with 1-based row indexing
- **Comprehensive modal editors** - Full-featured forms with date/time pickers and volume controls
- **Reusable component architecture** - SwipeActionsView eliminates code duplication across views

#### 📊 Advanced Stacked Charts
- **Formula type breakdown** - 7-day visualization showing which formulas were used each day, including today
- **Dynamic color assignment** - Consistent color mapping between charts and legends
- **Optimized rendering** - Background processing with cached results for instant display
- **Enhanced visual analytics** - Better insights into feeding patterns and formula preferences

#### 🏗️ Architectural Improvements
- **Smart cache invalidation** - Automatic cache clearing after edit/delete operations
- **Generic storage methods** - Flexible data fetching with configurable day ranges
- **Clean component separation** - Chart logic moved to chart components for better maintainability

#### 🏗️ Latest: Complete MVVM Architecture & Configurable UX
- **Complete MVVM Pattern** - Added `PumpingEntryViewModel` (266 lines) for full architectural consistency across all entry views
- **Configurable Drag Speed** - User-selectable speed (Slow/Default/Fast) in Settings with optimized sensitivity curves
- **Unified App Lifecycle** - Both Feed and Pumping views auto-reset date/time after 1+ hour inactivity using shared lifecycle patterns
- **Centralized Haptic System** - All views use `HapticHelper.shared` for consistent tactile feedback with 5mL precision
- **Enhanced Accessibility** - Improved Settings UI with cleaner segmented controls and better user guidance
- **Production Ready** - Debug statements wrapped for clean App Store builds with comprehensive error handling

#### 🏗️ Previous: Architectural Refactor & Security Overhaul
- **955+ lines eliminated** - Removed all code duplication through shared components
- **ContentView: 987 → 34 lines** (96.6% reduction!)
- **Created 4 shared components** - `FeedEntryForm` (312), `FeedEntryViewModel` (318), `FeedConstants` (103), `HapticHelper` (246)
- **Enterprise Security System** - GitHub Actions secrets scanner with multi-layer protection

### Previous Improvements (Pre-Refactor)
- **🗑️ Advanced Waste Tracking**: Complete milk waste tracking system with 2-hour expiration awareness
- **⚡ Configurable Drag Slider**: User-selectable speed settings (Slow/Default/Fast) with 5mL increments and optimized sensitivity curves
- **📱 Space-Optimized UI**: Compact Feed/Waste toggle integrated directly on volume line for cleaner interface
- **📊 Waste Analytics**: Feed Overview displays waste metrics and statistics when advanced features enabled
- **🔧 Settings Integration**: Advanced features toggle in Settings to keep interface clean for basic users
- **📈 Full Data Model**: 5-column Google Sheets integration supporting comprehensive feeding and waste data
- **🎨 Accessibility Optimized**: Shortened "Wasted" label prevents text overflow with magnification enabled

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

⚠️ **IMPORTANT**: This repository contains sensitive configuration files that must NOT be committed to version control.

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

⚠️ **IMPORTANT**: This repository contains placeholder values for OAuth configuration. See [SETUP.md](SETUP.md) for complete setup instructions.

### Quick Start
1. Clone the repository
2. Follow the detailed setup guide in [SETUP.md](SETUP.md)
3. Open the project in Xcode and build

### Prerequisites
- Xcode 14+
- iOS 18+ deployment target  
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
The app successfully uses Google Sheets as a free, reliable backend that provides:
- Zero infrastructure costs
- Complete user data ownership
- Built-in export capabilities
- Multi-device synchronization
- No server maintenance required

### Potential Improvements
- **Enhanced offline capabilities** - Local data queuing when network unavailable
- **Improved OAuth flow** - Streamlined authentication experience
- **Advanced analytics** - Built-in insights and trend analysis within the app
- **Additional integrations** - Health app connectivity, Apple Watch support

## Contributing

This is a personal project, but if you'd like to contribute:
1. Fork the repository
2. Create a feature branch
3. Test thoroughly with your own Google Sheets
4. Submit a pull request with clear description

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

### What this means:
- ✅ **Free to use** - Use for personal or commercial projects
- ✅ **Attribution required** - Must credit original work
- ✅ **Patent protection** - Contributors grant patent rights
- ✅ **Modification allowed** - Can modify and distribute changes
- ✅ **Private use** - Can use privately without sharing changes

The Apache 2.0 license ensures proper attribution while enabling open collaboration and innovation.

---

*Built with ❤️ for tired parents everywhere*
