# MiniLog – Feed Tracker iOS App

A SwiftUI-based iOS application for tracking baby feeding data with Google Sheets integration.

## Project Overview

MiniLog is designed to help parents log baby feeding information quickly and efficiently. The app uses Google Sheets as a backend database, enabling multi-device synchronization and easy data analysis.

### Core Features
- 🍼 **Smart Feed Tracking** - Quick volume entry, drag gestures, customizable presets
- 📊 **Multi-View Dashboard** - Four-pane swipe navigation (Feed entry, History, Pumping, Analytics)
- 🗂️ **Google Sheets Integration** - Real-time sync, automatic backups, multi-device access
- ⚡ **Intelligent Caching** - 80-90% API reduction with 5-minute smart cache system
- 🔊 **Enhanced Haptic Feedback** - Centralized system with configurable drag speeds and optimal tactile precision
- 🗑️ **Waste Tracking** - Advanced milk waste monitoring with 2-hour expiration awareness
- 📱 **Siri Integration** - Natural voice commands ("Log 100 to MiniLog")
- ⚙️ **Highly Configurable** - Custom volumes, formula types, daily goals, haptic preferences, drag speeds
- 📈 **Analytics & Insights** - 7-day trends, daily totals, pattern recognition
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
├── scripts/                    # Security audit and development tools
└── FeedTracker/               # Source code directory
    ├── FeedTrackerApp.swift           # App entry point & configuration (29 lines)
    ├── HorizontalNavigationView.swift # Four-pane swipe navigation (125 lines)
    ├── ContentView.swift              # Main feed entry (32 lines - 97% reduction!)
    │
    ├── 🎯 Shared Components (MVVM Architecture)
    ├── FeedEntryForm.swift            # Shared UI component (287 lines)
    ├── FeedEntryViewModel.swift       # Feed business logic with app lifecycle (306 lines)
    ├── PumpingEntryViewModel.swift    # Pumping business logic with app lifecycle (240 lines)
    ├── FeedConstants.swift            # Centralized constants (75 lines)
    ├── HapticHelper.swift             # Multi-tier haptic system (230 lines)
    │
    ├── 📊 Views & Features
    ├── FeedHistoryView.swift          # Feed analytics with 7-day trends (285 lines)
    ├── PumpingView.swift              # Pumping session logger with MVVM pattern (180 lines)
    ├── PumpingHistoryView.swift       # Pumping analytics & insights (285 lines)
    ├── WeeklySummaryView.swift        # Reusable trend analysis (189 lines)
    ├── SettingsView.swift             # App configuration (372 lines)
    ├── SpreadsheetPickerView.swift    # Google Sheets browser (249 lines)
    │
    ├── 🔧 Services & Models
    ├── StorageService.swift           # Protocol abstraction with intelligent caching (133 lines)
    ├── GoogleSheetsStorageService.swift # Google Sheets API integration with cache (798 lines)
    ├── Models.swift                   # Data models (69 lines)
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

- **🛡️ GitHub Actions Security Scanning** - Server-side enforcement that cannot be bypassed
- **🔒 Multi-Layer Pre-Commit Protection** - Local hooks with pattern detection and content scanning
- **📋 Enhanced .gitignore** - Comprehensive patterns for all sensitive file types  
- **🔍 Security Audit Tools** - Regular monitoring and incident response capabilities
- **📚 Complete Documentation** - Security guidelines and incident response procedures

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
   - Append new rows to spreadsheet
   - Fetch today's total from all entries
   - Handle API errors gracefully
   - Create new tracking sheets with proper template
   - Browse and select from available spreadsheets

5. **User Experience**
   - Precision drag slider optimized for feeding volumes (3 pixels per 1mL)
   - Smart haptic feedback system with configurable intensity
   - Success/error alerts with haptic confirmation
   - Loading states during API calls
   - Pull-to-refresh for totals
   - Auto-refresh interface after returning from 1+ hour absence
   - Enhanced Settings page with haptic preferences and UI controls

### Latest Release: Smart Caching System & Performance Optimization

#### ⚡ Intelligent Caching Architecture
- **80-90% API call reduction** - Thread-safe DataCache actor with 5-minute expiration
- **Smart refresh logic** - Navigation uses cache, pull-to-refresh forces fresh data
- **Automatic cache invalidation** - Clears cached data when new entries are submitted
- **Enhanced OAuth management** - Proactive token refresh and retry mechanisms
- **Protocol-based storage** - StorageServiceProtocol for future multi-provider support

#### 🎯 User Experience Improvements
- **Removed 5th dynamic "Last" button** - Cleaner, more focused quick volume interface
- **Instant navigation** - Cache hits provide immediate data loading between panes
- **Consistent behavior** - Manual refresh respects user intent for fresh data
- **Enhanced feedback** - Clear cache hit vs API call logging for transparency

#### 🏗️ Latest: Complete MVVM Architecture & Configurable UX
- **Complete MVVM Pattern** - Added `PumpingEntryViewModel` (240 lines) for full architectural consistency across all entry views
- **Configurable Drag Speed** - User-selectable speed (Slow/Default/Fast) in Settings with optimized sensitivity curves
- **Unified App Lifecycle** - Both Feed and Pumping views auto-reset date/time after 1+ hour inactivity using shared lifecycle patterns
- **Centralized Haptic System** - All views use `HapticHelper.shared` for consistent tactile feedback with 5mL precision
- **Enhanced Accessibility** - Improved Settings UI with cleaner segmented controls and better user guidance
- **Production Ready** - Debug statements wrapped for clean App Store builds with comprehensive error handling

#### 🏗️ Previous: Architectural Refactor & Security Overhaul
- **955+ lines eliminated** - Removed all code duplication through shared components
- **ContentView: 987 → 32 lines** (96.8% reduction!)
- **Created 4 shared components** - `FeedEntryForm` (287), `FeedEntryViewModel` (306), `FeedConstants` (75), `HapticHelper` (230)
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
- [ ] Premium Analytics tier development (AWS infrastructure)
- [ ] Implement last feed details (volume + formula type, not just time)
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

### Dual-Strategy Cloud Migration Plan
**Approach**: Solve current OAuth pain points with simplified onboarding while maintaining privacy-focused Sheets option.

#### Current Challenge: OAuth User Experience
- Complex Google Sign-In flow with scary permission dialogs
- Frequent re-authentication required (token expiry issues)
- Users getting signed out periodically 
- High friction onboarding deterring adoption

#### Proposed Solution: Dual-Tier Strategy

### Tier 1: Firebase Anonymous Auth (Default - Simplified UX)
**Immediate Solution for OAuth Problems:**
- **Instant onboarding** - "Start Tracking" button, no sign-up required
- **Anonymous Firebase users** - Automatic device syncing via persistent user ID
- **Cross-device sync** - Data follows user across devices seamlessly
- **Optional account linking** - Upgrade to Google account for backup later
- **Cost**: $0-3/month for 1000+ users (Firebase free tier coverage)

**User Experience:**
```
1. App opens → "Start Tracking" button
2. Immediate logging (no authentication friction)
3. Data automatically syncs across user's devices
4. Optional: "Link Google account" for backup/export
```

### Tier 2: Google Sheets (Privacy Pro Mode)
**Keep Current Implementation as Premium Option:**
- **Market as "Advanced Privacy Mode"** - For users who want spreadsheet control
- **Full data ownership** - Data stays in user's Google account
- **Power user features** - Direct spreadsheet access, custom formulas
- **Zero infrastructure costs** - Maintain current $0 hosting model
- **Target audience**: Privacy-conscious users, data analysts, spreadsheet power users

### Infrastructure as Code + Learning Path

#### Phase 1: Firebase Foundation (Immediate - 2-3 months)
**Technology Stack:**
- **Firebase Auth** - Anonymous users + optional Google linking
- **Firestore** - Real-time database with offline sync
- **Cloud Functions** - Serverless processing
- **Firebase Hosting** - Web dashboard (optional)

**Development Benefits:**
- **Terraform support** - Full IaC for Firebase project setup
- **GCP ecosystem integration** - Leverage existing Google Sign-In knowledge
- **Lower migration complexity** - Keep authentication patterns
- **Free tier advantages** - 50K reads/20K writes daily free

#### Phase 2: AWS + Kubernetes Learning (Future - when ready)
**Learning-Focused Infrastructure:**
- **Amazon EKS** - Real Kubernetes cluster management experience
- **Terraform modules** - Complete infrastructure as code
- **DynamoDB** - Cost-effective database with single-table design
- **Container architecture** - API services running in K8s pods

**Cost-Optimized K8s Setup:**
- **EKS Fargate** - Pay-per-pod, no EC2 management (~$100/month)
- **Spot instances** - Cost reduction for development workloads
- **Full DevOps stack** - CI/CD, monitoring, service mesh learning

#### Long-term Architecture Vision

**Three-Tier Strategy:**
1. **Firebase Tier** - Simplified UX, $0-5/month operational costs
2. **Google Sheets Tier** - Privacy-focused, zero infrastructure costs  
3. **AWS K8s Tier** - Learning environment, advanced analytics (~$100/month)

**Premium Analytics Capabilities (Future):**
- **Machine Learning Insights** - Feeding pattern recognition, growth predictions
- **Peer Comparisons** - Anonymous age-appropriate benchmarking
- **Health Integration** - Pediatric milestone tracking
- **Professional Reports** - Automated pediatrician summaries
- **Advanced Notifications** - Predictive feeding reminders

#### Migration Timeline
**Immediate (Next 1-2 months):**
- Add Firebase Anonymous Auth as default onboarding
- Keep Google Sheets as "Pro Mode" option
- Solve current OAuth friction problems

**Medium-term (3-6 months):**
- Terraform Firebase infrastructure 
- Advanced analytics on Firebase data
- Enhanced user dashboard

**Long-term (6+ months):**
- AWS EKS learning environment
- Kubernetes-based microservices
- Advanced ML analytics pipeline

### Privacy & Security

#### Current (Google Sheets)
- All data stays in user's own Google account
- No data collected by the app itself
- Direct user-to-Google API communication

#### Future (AWS Infrastructure)
- **Encryption at rest and in transit** - All data encrypted using AWS KMS
- **HIPAA compliance considerations** - For health data protection
- **User data isolation** - Each user's data in separate logical partitions
- **Face ID/Touch ID** - Biometric app access for sensitive health data
- **Data retention policies** - Configurable retention with automatic cleanup
- **Audit logging** - CloudTrail for all data access and modifications
- **Privacy controls** - User data export, deletion, and consent management

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
