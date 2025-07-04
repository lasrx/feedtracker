# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MiniLog is a SwiftUI iOS app for tracking baby feeding data with Google Sheets integration. Parents can quickly log feeding volume, time, and formula type, with real-time sync to Google Sheets for multi-device access and data analysis. Features voice logging via Siri Shortcuts and a comprehensive settings system.

## Build Commands

- **Build**: Open `MiniLog.xcodeproj` in Xcode and use Cmd+B, or Product → Build
- **Run**: Use Cmd+R in Xcode, or Product → Run
- **Clean**: Product → Clean Build Folder
- **Test**: Not currently configured - no test target exists

## Architecture Overview

### Core Application
- **FeedTrackerApp.swift**: App entry point, configures Google Sign-In and Siri Shortcuts (29 lines)
- **HorizontalNavigationView.swift**: Main UI with four-pane horizontal swipe navigation (125 lines)
- **ContentView.swift**: Main feed entry (32 lines - massive reduction from original!)

### 🎯 Shared Components (NEW - Post-Refactor)
- **FeedEntryForm.swift**: Shared UI component (287 lines) - eliminates code duplication
- **FeedEntryViewModel.swift**: Shared business logic (306 lines) - centralized feed logic
- **FeedConstants.swift**: Centralized constants (75 lines) - no more magic numbers
- **HapticHelper.swift**: Multi-tier haptic system (230 lines) - enhanced feedback

### Feature Views
- **FeedHistoryView.swift**: Left pane - Today's feed overview with 7-day analytics
- **PumpingView.swift**: Right pane - Pumping session logger with customizable quick volumes
- **PumpingHistoryView.swift**: Far right pane - Pumping overview with session list and weekly insights
- **WeeklySummaryView.swift**: Reusable 7-day trend analysis component for both feed and pumping data
- **SettingsView.swift**: Configuration UI for spreadsheet selection, haptic preferences, daily goals, formula types, and Quick Volume customization
- **SpreadsheetPickerView.swift**: Google Drive API-powered spreadsheet browser with bottom-aligned selection

### Services & Models
- **StorageService.swift**: Protocol abstraction for storage providers with intelligent caching infrastructure (133 lines)
- **GoogleSheetsStorageService.swift**: Google Sheets/Drive API integration with 5-minute cache, OAuth token refresh, and retry mechanisms (798 lines) 
- **Models.swift**: Data models (FeedEntry, PumpingEntry, DailyTotal) with proper 12-hour time parsing
- **LogFeedIntent.swift**: Siri Shortcuts integration for voice logging (iOS 16+)
- **Utilities.swift**: Shared utilities and helper functions

### Data Flow
1. User authentication via Google Sign-In SDK with enhanced token refresh
2. Feed data (date, time, volume, formula type) entered through SwiftUI form with precision drag slider
3. Smart haptic feedback provides tactile confirmation during volume adjustment
4. Data appended to Google Sheets via REST API calls with haptic success/error feedback
5. **Intelligent caching layer**: Subsequent data requests check 5-minute cache before API calls
6. **Cache invalidation**: New submissions automatically clear related cache entries
7. Today's total fetched from cache or API based on staleness and user intent
8. Auto-refresh system updates interface after extended absence

### Smart Caching System
- **DataCache Actor**: Thread-safe caching with configurable 5-minute expiration
- **Cache Keys**: Separate storage for feeds, pumping, totals, and weekly data
- **forceRefresh Logic**: Navigation triggers use cache (false), pull-to-refresh bypasses cache (true)
- **Performance**: 80-90% reduction in API calls for typical navigation patterns
- **Invalidation**: Automatic cache clearing when new data is submitted

### Google Sheets Integration
- **Spreadsheet ID**: Configurable via Settings (stored in UserDefaults)
- **Column Structure**: A=Date (M/d/yyyy), B=Time (h:mm a), C=Volume (numeric), D=Formula Type (Feed Log); A=Date, B=Time, C=Volume (Pumping sheet)
- **API Scope**: `https://www.googleapis.com/auth/spreadsheets` and `https://www.googleapis.com/auth/drive.file`
- **Authentication**: OAuth 2.0 with automatic token refresh

### Haptic Feedback System
- **Configurable**: Toggle in Settings with user-friendly description
- **Smart Intervals**: Light haptic every 5mL, medium haptic every 25mL during drag
- **Comprehensive Coverage**: Drag slider, quick buttons, success/error states, auto-refresh
- **Performance Optimized**: Haptic logic runs independently of UI updates for smooth operation
- **Drag Slider Precision**: 3 pixels per 1mL for optimal balance of speed and control

## Dependencies

The app uses Swift Package Manager with these dependencies:
- **GoogleSignIn-iOS** (v8.0.0): OAuth authentication
- **AppAuth-iOS** (v1.7.6): OAuth protocol support
- **GoogleUtilities** (v8.1.0): Google SDK utilities
- **GTMAppAuth** (v4.1.1): Google authentication helpers

## Configuration Requirements

### Google Services Setup
1. **GoogleService-Info.plist**: Required for Google Sign-In configuration (git-ignored)
2. **URL Scheme**: Configured in Info.plist for OAuth callback
3. **Spreadsheet ID**: Must be updated in GoogleSheetsService.swift for different spreadsheets
4. **OAuth Scopes**: Currently limited to Sheets API access

### Development Setup
- **Xcode**: 14+ required
- **iOS Target**: 18+ deployment target
- **Bundle ID**: Must match Google Cloud Console OAuth configuration
- **Test Users**: Must be added in Google Cloud Console during development

## Key Implementation Details

### UI/UX Features
- **Haptic Feedback**: Extensive use throughout app for tactile confirmation
- **Drag Gesture**: Volume adjustment via vertical swipe on number field
- **Customizable Quick Buttons**: User-configurable volume buttons for Feed (default: 40,60,130,150 mL) and Pumping (default: 130,140,150,170 mL) plus dynamic "Last" button
- **Pull-to-Refresh**: Updates today's total from spreadsheet
- **Dark Mode**: Full support via SwiftUI environment

### State Management
- **@StateObject**: GoogleSheetsService managed as observable object
- **@State**: Local UI state for form fields and loading states
- **@Published**: Authentication state and user email in service layer

### Error Handling
- **Custom Error Types**: SheetsServiceError enum with localized descriptions
- **Async/Await**: Modern concurrency for all API calls
- **Token Refresh**: Automatic OAuth token renewal before API calls

## Key Features Implemented

### Core Four-Pane Navigation
- **Four-Pane Interface**: Horizontal swipe navigation between four specialized panes
- **Feed Overview** (Left): Today's feeding summary with 7-day trend analysis and session list
- **Feed Logging** (Center): Main entry form with drag slider and customizable quick volumes
- **Pumping Logger** (Right): Dedicated pumping session tracking with separate volume presets
- **Pumping Overview** (Far Right): Pumping statistics, session history, and weekly insights

### Advanced Features
- **Intelligent Caching System**: 5-minute smart cache with 80-90% API call reduction for optimal performance
- **Enhanced Settings Page**: Configurable spreadsheet ID, haptic feedback toggle, daily goals, formula types, and Quick Volume customization
- **Precision Drag Slider**: 3 pixels per 1mL sensitivity optimized for feeding volumes (0-200mL range)
- **Advanced Haptic System**: Smart feedback with light clicks (5mL) and medium clicks (25mL)
- **Customizable Quick Volumes**: User-configurable preset buttons via Settings (removed 5th dynamic "Last" button for cleaner interface)
- **Accurate Timing Displays**: Fixed "Since Last" calculations with proper 12-hour AM/PM date parsing
- **Siri Shortcuts**: Natural voice logging with phrases like "Log 100 to MiniLog"
- **Progress Tracking**: Visual progress bar toward daily volume goal
- **Auto-refresh**: Interface resets after 1+ hour absence, smart cache management for instant navigation
- **Mobile-Optimized UI**: Bottom-aligned spreadsheet selection, pagination, improved button placement

### Performance & Reliability
- **Protocol-Based Storage**: StorageServiceProtocol abstraction enables future multi-provider support
- **Enhanced OAuth Management**: Proactive token refresh (10 minutes before expiry) with retry mechanisms
- **Thread-Safe Operations**: DataCache actor ensures safe concurrent access to cached data
- **Smart Refresh Logic**: Navigation uses cached data, manual refresh forces fresh API calls
- **Automatic Cache Invalidation**: Submitting new data clears related cache for immediate consistency

## Siri Integration Implementation

### Supported Voice Commands
- **"Log 100 to MiniLog"** - Primary logging phrase
- **"Add 150 to MiniLog"** - Alternative syntax
- **"Track 120 with MiniLog"** - Action-based command
- **"Log feed 80 in MiniLog"** - Explicit context
- **"Record 150 feed in MiniLog"** - Formal language

### Design Principles
- **No unit pronunciation** - Eliminates "mL/milliliter" confusion
- **Simple numeric values** - Reduces Siri parsing complexity
- **Automatic formula type** - Uses last selected type from app
- **App-specific naming** - Prevents conflicts with HomeKit/other services
- **Natural language** - Phrases people actually say

### Technical Implementation
- **App Intents framework** (iOS 16+) for modern Siri integration
- **VolumeEntity** for structured parameter handling
- **Auto-donation** after successful feeds to improve recognition
- **Consent-based** - Users control Siri access via iOS Settings

## 🔒 SECURITY SYSTEM - FULLY OPERATIONAL

**STATUS**: Enterprise-grade security system is fully implemented and operational.

### Multi-Layer Protection:
- **GitHub Actions Secrets Scanner** - Server-side enforcement on every commit
- **Pre-commit hooks** - Local protection with automatic cleaning
- **Enhanced .gitignore** - Comprehensive pattern blocking
- **Template file support** - Allows `.env.local.template` and `.env.example`

### Protected Files:
- **GoogleService-Info.plist** - OAuth secrets (git-ignored)
- **.env.local** - Development config (removed from tracking, git-ignored)
- **Info.plist** - OAuth client ID (auto-cleaned by pre-commit hooks)
- **Any API keys/credentials** - Detected by pattern scanning

### Security Status:
- ✅ **Secrets Scanner**: Fully operational, scans 13+ credential patterns
- ✅ **Template files**: Properly allowed (.env.local.template, .env.example)
- ✅ **Self-aware**: Security workflow excludes its own patterns
- ✅ **Auto-cleanup**: Pre-commit hooks clean sensitive data automatically
- **Check `git status`** before commits - sensitive files should show as modified but not be staged

### Emergency Recovery:
If sensitive data is accidentally committed:
1. `git reset --soft HEAD~1` (before push)
2. `./utils/clean_for_commit.sh "Fixed: removed sensitive data"`
3. Use `git push --force-with-lease` if already pushed (CAREFUL!)

## Current Limitations

- No offline queue for entries without internet connection
- No data validation (allows future dates, negative volumes)
- Spreadsheet picker limited to app-created sheets (drive.file scope)
- Cannot access existing user spreadsheets (requires full drive scope + verification)

## Future Multi-Tier Architecture

### Tier Strategy
The current Google Sheets approach will remain as **Tier 1** (privacy-focused, zero-cost). A cost-optimized **Tier 2** AWS solution will provide advanced analytics.

### Tier 1: Google Sheets (Privacy-First)
- **Zero infrastructure costs** - Users pay nothing
- **Maximum data privacy** - No third-party storage
- **Current implementation** - Fully functional MVP

### Tier 2: Premium Analytics (AWS Cloud)

**Database Layer (Budget-Conscious):**
- **DynamoDB only** - Skip expensive RDS, use pay-per-request model
- **Single table design** - Minimize throughput costs
- **S3** - Ultra-cheap analytics storage (~$0.023/GB/month)

**Serverless-First Compute:**
- **Lambda** - 1M requests/month free tier coverage
- **API Gateway** - Pay-per-use, extensive free tier
- **DynamoDB Streams** - Real-time processing included in DynamoDB cost

**Cost Targets:**
- **<$25/month for 1000 users** - Leverage free tiers and pay-per-use pricing
- **<$5/month for 100 users** - Most usage covered by free tiers
- **Terraform managed** - Infrastructure as code from day one

**Premium Analytics Features:**
- **S3 + Athena** - Query analytics data without dedicated database
- **Lambda functions** - Custom insights processing
- **CloudWatch** - Free tier monitoring and basic dashboards
- **QuickSight SPICE** - Only for admin dashboards ($5/user/month)

**Advanced Analytics Capabilities:**
- **Feeding Pattern Recognition** - ML-powered trend analysis and growth tracking
- **Peer Comparisons** - Anonymous age-appropriate benchmarking against similar babies
- **Predictive Insights** - Next feeding predictions, growth trajectory forecasting
- **Health Integration** - Pediatric milestone tracking and feeding guideline compliance
- **Smart Notifications** - Pattern-based feeding reminders and growth alerts
- **Professional Reports** - Pediatrician-ready summaries and detailed analytics

### Implementation Philosophy
- **Start with free tiers** - Design around AWS free tier limits
- **Pay-per-use model** - No fixed costs until significant scale
- **Gradual migration** - Users can choose tier based on needs
- **Privacy options** - Sheets tier for privacy-conscious users
- **Consent-based analytics** - Premium features require explicit user consent
- **Anonymized insights** - Peer comparisons use aggregated, non-identifiable data