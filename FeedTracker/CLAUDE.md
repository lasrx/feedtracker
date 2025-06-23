# Claude Code Assistant Instructions

## Project Overview
MiniLog is an iOS SwiftUI app for tracking baby feeding with Google Sheets integration, haptic feedback, and multi-view navigation.

## Architecture Summary (Post-Refactor June 2025)
- **MVVM Pattern**: Views use `@StateObject` for service ownership and `@ObservedObject` for dependency injection
- **Shared Components**: Eliminated 917 lines of duplication through architectural refactor
- **Google Sheets Integration**: Real-time sync with spreadsheet data
- **Multi-Tier Haptic System**: Modern haptics with AudioToolbox fallback
- **Enterprise Security**: GitHub Actions enforcement and multi-layer protection

## Key Components

### Core Views
- `ContentView.swift` (70 lines) - Main entry point, owns GoogleSheetsService
- `FeedLoggingView.swift` - Feed tracking interface in navigation view
- `HorizontalNavigationView.swift` - 4-panel swipe navigation system
- `SettingsView.swift` - App configuration and Google account management

### Shared Architecture (NEW - June 2025)
- `FeedEntryForm.swift` (245 lines) - Shared UI component for feed entry
- `FeedEntryViewModel.swift` (200+ lines) - Centralized business logic
- `FeedConstants.swift` (50 lines) - App-wide constants and configuration
- `HapticHelper.swift` (100+ lines) - Multi-fallback haptic system

### Services
- `GoogleSheetsService.swift` - API integration with UserDefaults observation
- `HapticHelper.swift` - Cross-device haptic compatibility

## Recent Major Changes (June 2025)

### Architectural Refactor
- **Eliminated 917 lines of duplication** between ContentView and FeedLoggingView
- **Created shared component architecture** with 4 new files
- **Reduced ContentView from 987 to 70 lines** (92.9% reduction)
- **Fixed active spreadsheet selection bug** via UserDefaults observation
- **Overhauled haptic system** with multi-tier fallback

### Component Extraction
```swift
// Before: 987 lines of duplicated code
// After: 70-line ContentView + shared components

struct ContentView: View {
    @StateObject private var sheetsService = GoogleSheetsService()
    @StateObject private var viewModel = FeedEntryViewModel()
    
    var body: some View {
        NavigationView {
            FeedEntryForm(viewModel: viewModel, sheetsService: sheetsService)
        }
    }
}
```

### Haptic System Overhaul
- **Multi-tier fallback**: UIImpactFeedbackGenerator → UINotificationFeedbackGenerator → AudioToolbox
- **Device compatibility**: Handles iOS settings and hardware variations
- **Subtler feedback**: Reduced intensities (0.7/0.5/0.3 vs 1.0/0.8)
- **Removed navigation haptics**: User feedback "felt out of place"

## Development Commands

### Testing & Building
```bash
# Run tests (if available)
xcodebuild test -scheme FeedTracker -destination 'platform=iOS Simulator,name=iPhone 15'

# Build for release
xcodebuild archive -scheme FeedTracker -archivePath build/FeedTracker.xcarchive

# Security audit
../scripts/security-check.sh
```

### Git Workflow
```bash
# Increment build and commit
./increment_build.sh && git add . && git commit -m "Your message"

# Push to main (requires PR due to branch protection)
git checkout -b feature-branch
git push origin feature-branch
# Create PR on GitHub
```

## Development Patterns

### Architecture Overview
**Before**: 987-line ContentView with 80% code duplication  
**After**: Clean 70-line views using shared components

### Key Patterns
```swift
// When modifying feed entry behavior:
FeedEntryViewModel.swift  // Business logic
FeedEntryForm.swift      // UI components  
FeedConstants.swift      // Configuration values

// Architecture understanding:
ContentView: @StateObject sheetsService     // Owns the service
FeedLoggingView: @ObservedObject sheetsService // Receives the service
```

### Common Development Tasks
- **Adding UI elements**: Edit `FeedEntryForm.swift` (affects both views)
- **Adding business logic**: Edit `FeedEntryViewModel.swift`
- **Modifying constants**: Edit `FeedConstants.swift` (no more magic numbers)
- **Navigation changes**: Check `HorizontalNavigationView.swift` for 4-pane setup

### Critical Files for Development
- `FeedConstants.swift` - All configuration values and magic numbers
- `FeedEntryForm.swift` - Shared UI component (245 lines)
- `FeedEntryViewModel.swift` - Shared business logic (200+ lines)
- `HapticHelper.swift` - Multi-tier haptic system
- `GoogleSheetsService.swift` - API integration with UserDefaults observation

## Security Guidelines

### Critical Security Measures
⚠️ **NEVER commit sensitive files** - .env.local, GoogleService-Info.plist, API keys

### GitHub Actions Protection
- **Server-side enforcement** - Cannot be bypassed by local tools
- **Multi-layer scanning** - Files, content, patterns, configuration
- **Automatic blocking** - Commits rejected if sensitive data detected
- **Branch protection** - All changes must pass security scan

### Security Workflow
```bash
# MANDATORY: Security check before any commit
../scripts/security-check.sh

# Stage specific files only (never git add .)
git add SpecificFile.swift

# Verify staged files
git diff --cached --name-only

# Commit (blocked if security issues found)
git commit -m "description"
```

## Current Status
- ✅ Major architectural refactor completed (June 2025)
- ✅ All duplication eliminated (917 lines removed)
- ✅ Haptic system overhauled with multi-tier fallback
- ✅ Active spreadsheet bug fixed via UserDefaults observation
- ✅ Enterprise security system implemented
- 🔄 Ready for continued development

---

*This documentation reflects the post-refactor architecture completed in June 2025.*