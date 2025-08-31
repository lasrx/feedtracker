# CLAUDE.md

AI assistant guidance for working with the MiniLog FeedTracker codebase.

## Project Overview

SwiftUI iOS app for baby feeding tracking with Google Sheets integration. See README.md for complete details.

## Build & Run

- Open `FeedTracker.xcodeproj` in Xcode
- Cmd+B to build, Cmd+R to run
- No test target configured

## Architecture & Design Patterns

### Service Layer Pattern
**StorageServiceProtocol**: Abstract interface for data operations enabling multiple providers
- `GoogleSheetsStorageService`: Current implementation with OAuth & caching
- `StorageProvider` enum: Ready for Firebase, AWS expansion
- **Thread-safe caching**: `DataCache` actor with 5-minute TTL

### Reusable Components
**SwipeActionsView<RowContent, Item>**: Generic component for edit/delete across all list views
**HapticHelper.shared**: Centralized haptic feedback with intensity levels
**FeedEntryViewModel/PumpingEntryViewModel**: Business logic separation from Views
**DeleteAlertModifier**: Reusable confirmation dialogs

### MVVM + Dependency Injection
**ViewModels**: Handle all business logic, API calls, lifecycle management
**Views**: Pure UI presentation, bind to ViewModel `@Published` properties  
**Service Injection**: ViewModels receive services via initializers for testability

### User-Configurable UX Pattern
**FeedConstants.swift**: Centralized defaults with user customization support
**@AppStorage integration**: Settings persist user preferences (daily goals, quick volumes, drag speed, formula types)
**Design philosophy**: Avoid hardcoding UX values, allow user control where beneficial
- Daily volume goals, quick volume buttons, drag sensitivity all configurable
- Formula types customizable vs. rigid predefined lists  
- UserDefaults keys centralized for consistency

### Intelligent Caching Strategy
**⚠️ CRITICAL**: 80-90% API call reduction - this is core to the app's performance
**Cache-first navigation**: `forceRefresh: false` for instant UI (onAppear, navigation)
**User-controlled refresh**: `forceRefresh: true` for pull-to-refresh, user actions
**Smart invalidation**: Cache cleared automatically after data mutations (add/edit/delete)
**5-minute TTL**: Configurable via `FeedConstants.cacheMaxAge`
**Thread-safe**: DataCache actor prevents race conditions

### Concurrency & Performance Patterns
**MainActor.run**: All UI updates from background tasks use `await MainActor.run`
**Background processing**: Heavy computations moved off main thread with Task{}
**Parallel API calls**: `async let` for concurrent operations (80-90% performance improvement)
**DEBUG compilation**: Extensive debug logging stripped in production builds (`#if DEBUG`)

### App Lifecycle Management  
**Background/Foreground handling**: NotificationCenter observers in all entry views
**1-hour refresh threshold**: Interface auto-resets after extended absence
**Time tracking**: ViewModels track `lastActiveTime` for smart refresh decisions

### UI Consistency Patterns
**Semantic colors**: Feed=accentColor, Pumping=purple, Waste=orange throughout app
**System color palette**: Uses iOS system colors for theme/accessibility support
**Configurable animations**: Spring stiffness/damping values centralized in FeedConstants
**44pt minimum targets**: All interactive elements meet accessibility guidelines

## Google Sheets Integration

**Column Structure**:
- Feed Log: A=Date, B=Time, C=Volume, D=Formula Type, E=Waste Amount  
- Pumping: A=Date, B=Time, C=Volume

**OAuth Scopes**: `spreadsheets` + `drive.file` (base), `drive.readonly` (optional)

## 🔒 SECURITY SYSTEM - CRITICAL FOR AI ASSISTANTS

**⚠️ READ FIRST**: This repo has automatic security that handles OAuth tokens - don't fight it!

### For AI Tools:
- **NEVER manually remove** Info.plist from staging - hooks handle this automatically
- **Read hook messages carefully** - they contain specific guidance for AI assistants
- **If blocked**: Follow the hook guidance exactly, don't try to bypass
- **Fresh setup**: Run `./git-hooks/install-hooks.sh` in new environments

### Resources:
- `git-hooks/` - Version-controlled hooks and installer
- `SECURITY_IMPLEMENTATION.md` - Complete implementation guide

## Code Navigation & Patterns

**CRITICAL FOR FRESH SESSIONS**: Always read MARK comments first - all files have extensive MARK sections
**Component reuse**: Check similar components before creating new ones - this codebase has mature patterns
- New list views → use `SwipeActionsView<RowContent, Item>` 
- New services → implement `StorageServiceProtocol`
- Business logic → create ViewModel with `@Published` properties
- **CRUD operations → ALWAYS route through service layer** (never direct API calls in views)  
- **Data mutations → invalidate cache** immediately after success
- Haptic feedback → use `HapticHelper.shared`
- Caching → use `DataCache` actor via service layer with `forceRefresh` pattern
- User preferences → add to `FeedConstants.UserDefaultsKeys` & `SettingsView`
- Cache invalidation → call `dataCache.clear(forKey:)` after mutations
- Background tasks → use `Task{}` then `await MainActor.run` for UI updates
- App lifecycle → add NotificationCenter observers for background/foreground
- Debug logging → wrap in `#if DEBUG` blocks for production builds
- Error handling → create LocalizedError enums with user-friendly descriptions

**Key Files**:
- `StorageService.swift`: Protocol definitions and caching infrastructure
- `FeedConstants.swift`: Centralized defaults, user preferences, and UI constants
- `SwipeActionsView.swift`: Generic reusable UI components
- `Models.swift`: Data modeling with computed properties and row tracking
- `ChartModels.swift`: Consistent color assignment and chart data processing
- `HapticHelper.swift`: Centralized haptic feedback with intensity levels
- `*ViewModel.swift`: MVVM patterns, app lifecycle, and service injection
- `*EditSheet.swift`: Modal form patterns with callback architecture
- `README.md`: Complete project details and features