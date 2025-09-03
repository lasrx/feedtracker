# MiniLog Setup Guide

This guide walks you through setting up the MiniLog app for development or personal use.

## Architecture Overview

MiniLog follows a clean MVVM (Model-View-ViewModel) architecture with complete consistency:

### **MVVM Components**
- **FeedEntryViewModel** & **PumpingEntryViewModel**: Shared business logic with consistent app lifecycle handling
- **FeedEntryForm.swift**: Reusable UI component eliminating code duplication
- **FeedConstants.swift**: Centralized configuration including drag speed settings and user preferences

### **Key Features**
- **Configurable Drag Speed**: User-selectable (Slow/Default/Fast) with optimized sensitivity curves
- **Unified Haptics**: `HapticHelper.shared` provides consistent tactile feedback across all views
- **Smart App Lifecycle**: Auto-reset date/time after 1+ hour inactivity to prevent stale timestamps
- **Production Ready**: Debug statements wrapped for clean App Store builds

## Prerequisites

- Xcode 14+
- iOS 18+ deployment target
- Google Cloud Console account
- Git (for repository cloning and security features)

## Quick Start

1. **Clone Repository**
   ```bash
   git clone https://github.com/lasrx/feedtracker.git
   cd feedtracker
   ```

2. **Set up environment** (see detailed steps below)
3. **Open in Xcode** and build

## Required Configuration Files

### 1. Environment File Setup

Create your local environment configuration:

```bash
# Copy the template file
cp .env.local.template .env.local

# Edit with your actual values
# SPREADSHEET_ID=your_actual_spreadsheet_id_here
# OAUTH_CLIENT_ID=your_oauth_client_id_here
```

⚠️ **Important**: The `.env.local` file is automatically git-ignored and should NEVER be committed.

### 2. Google OAuth Setup

You'll need to create your own Google OAuth credentials:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing project
3. Enable the Google Sheets API and Google Drive API
4. Create OAuth 2.0 credentials for iOS
5. Download the `GoogleService-Info.plist` file

#### Place GoogleService-Info.plist
- Add the downloaded `GoogleService-Info.plist` to your Xcode project
- Make sure it's added to the target
- **NEVER commit this file to git** (it's already in .gitignore)

### 3. Security System Verification

Test that the automated security system is working:

```bash
# Test that security hooks work (should be blocked)
git add .env.local
git commit -m "test"  # Should fail with security warning
```

The security system will automatically:
- Block commits of sensitive files
- Clean OAuth client IDs from Info.plist during commits  
- Restore development configuration after commits

### 4. Update Info.plist

Update the OAuth URL scheme in `Info.plist`:

```xml
<key>CFBundleURLSchemes</key>
<array>
    <string>com.googleusercontent.apps.YOUR_ACTUAL_CLIENT_ID</string>
</array>
```

Replace `YOUR_OAUTH_CLIENT_ID_HERE` with your actual client ID from GoogleService-Info.plist.

⚠️ **Security Note**: The pre-commit hooks will automatically clean this file before commits to prevent credential leaks.

### 4. Bundle Identifier

Update the bundle identifier in your Xcode project settings to match your Apple Developer account.

## First Run Setup

1. Sign in with Google when prompted
2. Create a new spreadsheet via Settings, or
3. Manually enter an existing spreadsheet ID in Settings

## 🔒 Security System

This project includes **enterprise-grade security** to prevent credential leaks:

### Multi-Layer Protection
- **🛡️ GitHub Actions Secrets Scanner** - Server-side enforcement on every commit
- **🔧 Pre-commit hooks** - Local protection with automatic cleaning
- **📋 Enhanced .gitignore** - Comprehensive pattern blocking
- **✅ Template file support** - Allows `.env.local.template` and `.env.example`

### Protected Files
The following files are automatically protected:
- `.env.local` - Development environment (git-ignored)
- `GoogleService-Info.plist` - OAuth secrets (git-ignored)
- `Info.plist` - OAuth client ID (auto-cleaned by pre-commit hooks)

### Security Verification
Test that the security system is working:
```bash
# This should be BLOCKED by pre-commit hooks
git add .env.local
git commit -m "test"  # Should fail with security warning
```

See `SECURITY.md` for complete security documentation.

## Troubleshooting

### "Could not find GoogleService-Info.plist"
- Ensure the file is added to your Xcode project target
- Check that the file is in the same directory as other source files
- Clean and rebuild the project

### OAuth Sign-In Fails
- Verify the URL scheme in Info.plist matches your OAuth client ID
- Check that Google Sheets API and Drive API are enabled in Google Cloud Console
- Ensure your bundle identifier matches the one configured in Google Cloud Console

### Empty Spreadsheet List
- The app uses `drive.file` scope, so it only shows spreadsheets created by the app
- Create a new spreadsheet using the "Create Sheet" button in Settings
- Or manually enter an existing spreadsheet ID if you have access

## Development Tips

### General Development
- Use the Simulator for development - no real device provisioning needed
- Test with different Google accounts to ensure OAuth flow works
- The app stores spreadsheet ID in UserDefaults, so it persists between app launches

### Architecture Understanding
The app uses a **shared component architecture** (post-refactor):
- **ContentView.swift** - Main feed entry (32 lines)
- **Shared Components** - `FeedEntryForm`, `FeedEntryViewModel`, `FeedConstants`, `HapticHelper`
- **Feature Views** - `FeedHistoryView`, `PumpingView`, `SettingsView`, etc.

### Code Guidelines
- Follow existing patterns in shared components
- Use `FeedConstants.swift` for configuration values
- All haptic feedback goes through `HapticHelper.swift`
- Business logic belongs in `FeedEntryViewModel.swift`

### Security During Development
- The security system will clean sensitive data automatically
- Never bypass security warnings - they prevent credential leaks
- Use `git status` to verify what's being committed

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

### What this means:
- ✅ **Free to use** - Use for personal or commercial projects
- ✅ **Attribution required** - Must credit original work
- ✅ **Patent protection** - Contributors grant patent rights
- ✅ **Modification allowed** - Can modify and distribute changes
- ✅ **Private use** - Can use privately without sharing changes