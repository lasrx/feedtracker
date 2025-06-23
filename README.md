# MiniLog – Feed Tracker iOS App

A SwiftUI-based iOS application for tracking baby feeding data with Google Sheets integration.

## Project Overview

MiniLog is designed to help parents log baby feeding information quickly and efficiently. The app uses Google Sheets as a backend database, enabling multi-device synchronization and easy data analysis.

### Key Features Built
- ✅ **Comprehensive waste tracking** - Advanced milk waste tracking with 2-hour expiration awareness
- ✅ **Customizable Quick Volume buttons** - User-configurable preset buttons for both Feed and Pumping
- ✅ **5mL precision slider** - Optimized drag gesture with 5mL increments for faster volume adjustment
- ✅ **Enhanced haptic feedback** - Smart haptic system with generator preparation and custom intensity
- ✅ Formula type selection (Breast milk, Similac 360, Emfamil Neuropro)
- ✅ Google Sign-In integration with full Drive scope for shared spreadsheet access
- ✅ Real-time sync with Google Sheets (5-column data model with waste tracking)
- ✅ Today's Feed Total tracking with progress bar and goal visualization
- ✅ Last feed time display
- ✅ Dark mode support
- ✅ Comprehensive haptic feedback with settings toggle
- ✅ Settings page with configurable options including haptic preferences and advanced features toggle
- ✅ Mobile-optimized spreadsheet picker with bottom-aligned selection
- ✅ Siri Shortcuts with natural voice commands (no "mL" pronunciation issues)
- ✅ Configurable daily volume goals
- ✅ Custom formula types
- ✅ Auto-refresh interface when returning to app after extended absence (1+ hours)
- ✅ **horizontal swipe horizontal navigation** with four-pane interface
- ✅ **Feed Overview** - Today's feeding summary with statistics, waste metrics, and 7-day trend analysis
- ✅ **Pumping logger** - Dedicated pumping session tracking
- ✅ **Pumping Overview** - Today's pumping summary with session list and weekly insights
- ✅ **7-day historical comparison** - Visual charts and analytics for pattern recognition
- ✅ **Accurate timing displays** - Fixed "Since Last" calculations with proper 12-hour AM/PM parsing
- ✅ **Settings customization** - Configure Quick Volume values for Feed (default: 40,60,130,150) and Pumping (default: 130,140,150,170)
- ✅ **Space-optimized UI** - Compact waste tracking toggle integrated with volume input for clean interface

## Technical Architecture

### Core Technologies
- **SwiftUI** - Modern declarative UI framework
- **Google Sign-In SDK** - OAuth authentication
- **Google Sheets API v4** - Data persistence
- **App Intents Framework** - Natural language Siri integration (iOS 16+)
- **Async/await** - Modern concurrency

### Project Structure
```
feedtracker/
├── README.md                   # Project overview and setup guide
├── SETUP.md                    # Detailed configuration instructions  
├── CLAUDE.md                   # Developer documentation
├── Privacy.md                  # Privacy policy and data handling
├── LICENSE                     # Apache 2.0 license
├── .gitignore                  # Git exclusions for sensitive files
├── MiniLog.xcodeproj/         # Xcode project configuration
└── FeedTracker/               # Source code directory
    ├── FeedTrackerApp.swift           # App entry point, Google Sign-In & Siri config
    ├── HorizontalNavigationView.swift # horizontal swipe four-pane navigation container
    ├── ContentView.swift              # Legacy main UI (now FeedLoggingView)
    ├── FeedHistoryView.swift          # Left pane: Feed overview with 7-day analytics
    ├── PumpingView.swift              # Right pane: Pumping session logger
    ├── PumpingHistoryView.swift       # Far right: Pumping overview with weekly insights
    ├── WeeklySummaryView.swift        # Reusable 7-day trend analysis component
    ├── SettingsView.swift             # Settings page with haptic preferences
    ├── SpreadsheetPickerView.swift    # Mobile-optimized spreadsheet browser  
    ├── GoogleSheetsService.swift      # Google Sheets/Drive API integration
    ├── Models.swift                   # Data models (FeedEntry, PumpingEntry, DailyTotal)
    ├── Utilities.swift                # Shared utilities (RelativeTimeFormatter)
    ├── LogFeedIntent.swift            # Siri Shortcuts integration (iOS 16+)
    ├── Info.plist                     # App configuration (OAuth URL schemes)
    ├── Assets.xcassets/               # App icons and visual assets
    └── GoogleService-Info.plist       # OAuth credentials (git-ignored)
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

### Latest Release: Major Architectural Refactor & Haptic System Overhaul
- **🏗️ Massive Code Cleanup**: Eliminated 917 lines of duplication - reduced ContentView from 987 to 70 lines (92.9% reduction)
- **🎯 Shared Component Architecture**: Created 4 new files (`FeedEntryForm`, `FeedEntryViewModel`, `FeedConstants`, enhanced `HapticHelper`)
- **🔧 Fixed Active Spreadsheet Bug**: Resolved force-close requirement when selecting new sheets via UserDefaults observation
- **🎵 Overhauled Haptic System**: Multi-tier fallback system (UIImpactFeedbackGenerator → UINotificationFeedbackGenerator → AudioToolbox)
- **📱 Subtler Haptic Feedback**: Reduced intensity levels (0.7/0.5/0.3) based on user feedback and removed navigation haptics
- **🛡️ Enhanced Security**: Resolved accidental .env.local leak through improved git workflow and documentation
- **📚 Complete Documentation**: Comprehensive CLAUDE.md with architectural patterns and development context

### Previous Improvements (Pre-Refactor)
- **🗑️ Advanced Waste Tracking**: Complete milk waste tracking system with 2-hour expiration awareness
- **⚡ 5mL Precision Slider**: Optimized volume adjustment with 5mL increments for faster, more practical input
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

### Scaling Beyond MVP
**Strategy**: Multi-tier architecture with Google Sheets as privacy-focused basic tier and cost-optimized AWS for advanced analytics.

#### Tier 1: Google Sheets (Current - Privacy Focused)
- **Zero infrastructure costs** - Users pay nothing, data stays in their Google account
- **Maximum privacy** - No third-party data storage, direct user-to-Google API
- **Simple setup** - Just requires Google account and spreadsheet ID
- **Perfect for**: Privacy-conscious users, single-family use, minimal tech setup

#### Tier 2: Premium Analytics (AWS Cloud)
**Cost-Optimized Architecture with Advanced Insights:**

**Database Layer (Cost-Conscious):**
- **DynamoDB** - Pay-per-request model, generous free tier (25GB, 25 WCU/RCU)
- **Skip RDS initially** - DynamoDB handles ~95% of use cases at fraction of cost
- **S3** - Extremely cheap storage for analytics (~$0.023/GB/month)

**Compute Layer (Serverless-First):**
- **Lambda** - 1M requests/month free, then $0.20 per 1M requests
- **API Gateway** - 1M API calls/month free tier
- **EventBridge** - Pay-per-event, minimal cost for feeding notifications

**Cost Projections (1000 active users):**
- **DynamoDB**: ~$5-15/month (generous free tier coverage)
- **Lambda**: ~$2-5/month (most requests covered by free tier)
- **S3**: ~$1-3/month for analytics storage
- **Total**: ~$10-25/month vs $30-100+ for RDS equivalent

#### Phase 1: Cost-Optimized Foundation
- **DynamoDB single table design** - Minimize provisioned throughput costs
- **Lambda + API Gateway** - Serverless backend with pay-per-use pricing
- **Terraform** - Infrastructure as code from day one
- **CloudWatch free tier** - Basic monitoring and logging

#### Phase 2: Premium Analytics Features
- **DynamoDB Streams** - Real-time data processing (included in DynamoDB cost)
- **S3 + Athena** - Query historical data without dedicated analytics database
- **QuickSight SPICE** - $5/user/month only for admin dashboards
- **Lambda analytics** - Custom insights without expensive ML services

**Premium Analytics Capabilities:**
- **Feeding Pattern Analysis** - Growth trends, volume patterns, timing insights
- **Age-Appropriate Comparisons** - Anonymous peer comparisons by age group
- **Predictive Insights** - Next feeding time predictions, growth projections
- **Health Milestone Tracking** - Integration with pediatric feeding guidelines
- **Custom Reports** - Weekly/monthly summaries, pediatrician reports
- **Smart Notifications** - Feeding reminders based on patterns, growth alerts

#### Benefits by Tier
**Google Sheets Tier:**
- Zero cost, maximum privacy, simple setup

**Premium Analytics Tier:**
- Advanced insights, predictive analytics, peer comparisons
- Estimated $10-25/month for 1000+ users vs $0 for Sheets
- Custom dashboards, automated notifications, health milestone tracking
- Privacy-compliant analytics with user consent and data control

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

## For AI Development Assistance

### **Post-Refactoring Architecture (2024)**
This codebase underwent major architectural improvements in December 2024:

**Before**: 987-line ContentView with 80% code duplication  
**After**: Clean 70-line views using shared components

### **Key Patterns for AI Assistance**
```swift
// When modifying feed entry behavior:
FeedEntryViewModel.swift  // Business logic
FeedEntryForm.swift      // UI components  
FeedConstants.swift      // Configuration values

// Architecture understanding:
ContentView: @StateObject sheetsService     // Owns the service
FeedLoggingView: @ObservedObject sheetsService // Receives the service
```

### **Common Tasks**
- **Adding UI elements**: Edit `FeedEntryForm.swift` (affects both views)
- **Adding business logic**: Edit `FeedEntryViewModel.swift`
- **Modifying constants**: Edit `FeedConstants.swift` (no more magic numbers)
- **Navigation changes**: Check `HorizontalNavigationView.swift` for 4-pane setup

### **Critical Files**
- `CLAUDE.md` - Comprehensive development context for AI assistance
- `FeedConstants.swift` - All configuration values and magic numbers
- `FeedEntryForm.swift` - Shared UI component (245 lines)
- `FeedEntryViewModel.swift` - Shared business logic (200+ lines)

See `CLAUDE.md` for complete development context and patterns.

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

<!-- Trigger security workflow for branch protection setup -->
