# CLAUDE.md

AI assistant guidance for working with the MiniLog FeedTracker codebase.

## Project Overview

SwiftUI iOS app for baby feeding tracking with Google Sheets integration. See README.md for complete details.

## Build & Run

- Open `FeedTracker.xcodeproj` in Xcode
- Cmd+B to build, Cmd+R to run
- No test target configured

## Architecture

**MVVM Pattern**: ViewModels handle business logic, Views handle UI
**4-Pane Navigation**: Feed Overview → Feed Entry → Pumping Entry → Pumping Overview  
**Google Sheets**: Full CRUD via GoogleSheetsStorageService with 5-minute caching
**Swipe Gestures**: Context-aware (.leading for left panes, .trailing for right panes)

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

## Code Navigation

**MARK comments**: All files have extensive MARK sections - use them for navigation
**MVVM pattern**: ViewModels contain business logic, Views handle UI only
**Existing patterns**: Check similar components before creating new ones
**README.md**: Complete project details, features, and implementation status