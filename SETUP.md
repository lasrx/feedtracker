# MiniLog Setup Guide

This guide walks you through setting up the MiniLog app for development or personal use.

## Prerequisites

- Xcode 14+
- iOS 15+ deployment target
- Google Cloud Console account

## Required Configuration Files

### 1. Google OAuth Setup

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

### 2. Update Info.plist

Update the OAuth URL scheme in `Info.plist`:

```xml
<key>CFBundleURLSchemes</key>
<array>
    <string>com.googleusercontent.apps.YOUR_ACTUAL_CLIENT_ID</string>
</array>
```

Replace `YOUR_OAUTH_CLIENT_ID_HERE` with your actual client ID from GoogleService-Info.plist.

### 3. Bundle Identifier

Update the bundle identifier in your Xcode project settings to match your Apple Developer account.

## First Run Setup

1. Sign in with Google when prompted
2. Create a new spreadsheet via Settings, or
3. Manually enter an existing spreadsheet ID in Settings

## Security Notes

⚠️ **IMPORTANT**: The following files contain sensitive information and should NEVER be committed to public repositories:

- `GoogleService-Info.plist` - Contains OAuth secrets
- `Info.plist` - Contains OAuth client ID (automatically protected by security scripts)
- Any `.xcconfig` files with API keys
- Provisioning profiles (`.mobileprovision`, `.provisionprofile`)

The project includes security scripts that automatically clean sensitive data before commits. See `SECURE_WORKFLOW.md` for details.

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

- Use the Simulator for development - no real device provisioning needed
- Test with different Google accounts to ensure OAuth flow works
- The app stores spreadsheet ID in UserDefaults, so it persists between app launches

## License

[Choose appropriate license for your use case]