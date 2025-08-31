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

## Google Sheets Integration

**Column Structure**:
- Feed Log: A=Date, B=Time, C=Volume, D=Formula Type, E=Waste Amount  
- Pumping: A=Date, B=Time, C=Volume

**OAuth Scopes**: `spreadsheets` + `drive.file` (base), `drive.readonly` (optional)

## 🔒 SECURITY SYSTEM - CRITICAL FOR AI ASSISTANTS

**IMPORTANT**: This repo has multi-layer security that automatically handles OAuth tokens.

### For AI Tools:
- **DO NOT manually remove** Info.plist from staging
- **Let the hooks work**: They clean, backup, commit clean version, restore for development  
- **If blocked**: Follow hook guidance, don't bypass the security system
- **New environments**: Run `./git-hooks/install-hooks.sh`

### Resources:
- `git-hooks/` - Version-controlled hooks and installer
- `SECURITY_IMPLEMENTATION.md` - Complete implementation guide

## Code Navigation & Patterns

**MARK comments**: All files have extensive MARK sections - use them for navigation
**Follow existing patterns**: Check similar components before creating new ones
- New list views → use `SwipeActionsView<RowContent, Item>` 
- New services → implement `StorageServiceProtocol`
- Business logic → create ViewModel with `@Published` properties
- Haptic feedback → use `HapticHelper.shared`
- Caching → use `DataCache` actor via service layer
- User preferences → add to `FeedConstants.UserDefaultsKeys` & `SettingsView`

**Key Files**:
- `StorageService.swift`: Protocol definitions and caching infrastructure
- `FeedConstants.swift`: Centralized defaults and user preference patterns
- `SwipeActionsView.swift`: Generic reusable UI components
- `SettingsView.swift`: User customization patterns with @AppStorage
- `*ViewModel.swift`: Business logic patterns and service injection
- `README.md`: Complete project details and features