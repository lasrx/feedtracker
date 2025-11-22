# MiniLog – Feed Tracker - Privacy Policy

**Last Updated:** September 3, 2025  
**Effective Date:** September 3, 2025

## Overview

MiniLog is designed with privacy as a core principle. We believe your baby's feeding data is sensitive health information that should remain under your complete control.

## Data Collection and Storage

### What Data We Collect
MiniLog collects only the information you explicitly enter:

**Feeding Data:**
- **Date and Time** - When the feeding occurred
- **Volume** - Amount of milk/formula consumed (in mL)
- **Formula Type** - Type of milk or formula used
- **Waste Amount** - Amount of milk wasted (when advanced features enabled)

**Pumping Data:**
- **Date and Time** - When the pumping session occurred
- **Volume** - Amount of milk pumped (in mL)

### Where Your Data is Stored
**Google Sheets Storage:**
- All feeding and pumping data is stored directly in Google Sheets within your own Google account
- MiniLog acts only as a client to write data to your spreadsheets
- We have no access to your Google account or spreadsheet data
- Your data never passes through our servers

**Local Device Storage:**
- App settings (daily volume goals, formula types, spreadsheet ID)
- Google OAuth tokens (managed by Google's SDK)
- Last used formula type (for Siri convenience)
- Haptic feedback preferences
- Quick volume button configurations
- Advanced features toggle state

## Data We Do NOT Collect

- Personal identifying information
- Contact information (email, phone, address)
- Location data
- Device identifiers
- Usage analytics or crash reports
- Any data outside of what you explicitly enter

## How We Use Google User Data

**MiniLog's use of information received from Google APIs will adhere to [Google API Services User Data Policy](https://developers.google.com/terms/api-services-user-data-policy), including the Limited Use requirements.**

### Specific Uses of Google User Data

**Google Sign-In (Authentication):**
- **Data Accessed:** Your email address and basic profile information
- **Purpose:** To authenticate you and identify your Google account
- **Usage:** Email is displayed in Settings to show which account is connected; not stored on our servers or shared with third parties
- **Storage:** Authentication tokens are stored securely on your device by Google's official SDK

**Google Sheets API:**
- **Data Accessed:** Contents of spreadsheets you explicitly select or create with our app
- **Purpose:** To read existing feeding data and write new feeding/pumping entries
- **Usage:** Data flows directly between your device and Google's servers; we never store or access your spreadsheet data on our servers
- **Storage:** Spreadsheet data remains in your Google account; we only store the spreadsheet ID locally on your device for quick access

**Google Drive API (drive.file scope):**
- **Data Accessed:** Files created by MiniLog in your Google Drive
- **Purpose:** To create new tracking spreadsheets with proper column headers
- **Usage:** Limited to creating and accessing only files that MiniLog creates; cannot access other files in your Drive
- **Storage:** Files are stored in your Google Drive; we have no server-side storage

**Google Drive API (drive.readonly scope - optional):**
- **Data Accessed:** List of spreadsheets in your Google Drive (filename and modification date only)
- **Purpose:** To help you find and connect to existing tracking spreadsheets shared by other users (e.g., shared between two parents)
- **Usage:** Read-only access for browsing only; filtered to show spreadsheets with "tracker" in the name; you must explicitly select which spreadsheet to connect
- **Storage:** Spreadsheet list is not stored; only the ID of your selected spreadsheet is saved locally on your device

### Data Use Limitations

**We use Google user data ONLY for the following purposes:**
1. Authenticating you to access Google Sheets
2. Writing feeding and pumping data you enter to your selected Google Sheet
3. Reading your existing feeding data to display totals and analytics
4. Creating new tracking spreadsheets in your Google Drive when requested
5. Browsing your spreadsheets to help you connect to shared tracking sheets

**We do NOT use Google user data for:**
- Advertising or marketing purposes
- Training machine learning models
- Sharing with third parties (except as required to provide the service via Google's APIs)
- Any purpose not directly related to the core feeding tracking functionality

## Third-Party Services

### Google Services
MiniLog integrates with Google services for core functionality:

**Google Sign-In:**
- Used for authentication to access Google Sheets
- Governed by [Google's Privacy Policy](https://policies.google.com/privacy)
- We only request minimal scopes necessary for spreadsheet access

**Google Sheets API:**
- Used to read and write feeding data to your spreadsheets
- Data flows directly between your device and Google's servers
- We cannot access your spreadsheets or Google account data

**Google Drive API (Limited):**
- Used to create new tracking spreadsheets within your Google Drive
- Used to browse existing spreadsheets for selection via SpreadsheetPickerView
- Limited to `drive.file` scope (only accesses files created by the app)
- Cannot access or modify files not created by MiniLog

## Siri and Voice Data

**Siri Shortcuts:**
- Voice commands are processed locally on your device by Apple's Siri
- No voice data is transmitted to our servers
- Supports natural language commands like "Log 100 to MiniLog"
- Uses App Intents framework for enhanced recognition (iOS 16+)
- Siri integration follows Apple's privacy standards
- You can disable Siri access at any time in iOS Settings

## Data Sharing

**We do not share, sell, or transfer your data to any third parties.**

The only data transmission occurs when:
- You log a feeding or pumping entry (sent directly to your Google Sheets)
- You create a new tracking spreadsheet (created in your Google Drive)
- You browse existing spreadsheets (read-only access to spreadsheet list)

## Data Control and Rights

### Your Rights
- **Access:** View all your data directly in your Google Sheets
- **Export:** Download your data from Google Sheets in various formats
- **Delete:** Remove data by deleting rows in your spreadsheet or deleting the entire sheet
- **Portability:** Your data is in standard spreadsheet format, easily portable

### Account Deletion
To stop using MiniLog:
1. Sign out of the app
2. Revoke app permissions in your Google Account settings
3. Delete any tracking spreadsheets you no longer want
4. Delete the app from your device

## Security

### Data Protection
- All communication with Google services uses HTTPS encryption
- Google OAuth tokens are managed securely by Google's official SDK
- No sensitive data is stored in app logs or debug information

### Access Control
- Only you have access to your feeding data through your Google account
- App permissions are limited to spreadsheet creation and data entry only
- No administrative or elevated access to your Google account

## Children's Privacy

MiniLog is designed for parents to track their baby's feeding information. While the app records data about infants, it does not directly collect personal information from children under 13. Parents are responsible for the data they choose to enter and store.

## Changes to Privacy Policy

We may update this Privacy Policy to reflect changes in our practices or for legal compliance. We will notify users of material changes by:
- Updating the "Last Updated" date
- Providing notice through the app or our website
- For significant changes, requiring explicit consent

## International Users

MiniLog can be used globally. Your data is stored in Google's global infrastructure according to [Google's Data Processing Terms](https://cloud.google.com/terms/data-processing-addendum). Please review Google's privacy practices for information about international data transfers.

## Contact Information

If you have questions about this Privacy Policy or our privacy practices:

**Developer Contact:** For privacy-related inquiries, please contact us:  
**Email:** minilog-feedtracker@googlegroups.com  
**GitHub Issues:** https://github.com/lasrx/feedtracker/issues  
**Project Repository:** https://github.com/lasrx/feedtracker

For questions about Google's data handling, please refer to [Google's Privacy Policy](https://policies.google.com/privacy) and [Google Cloud Privacy](https://cloud.google.com/privacy).

**Response Time:** We aim to respond to privacy inquiries within 30 days.

## Technical Implementation

### OAuth Scopes
MiniLog requests permissions in two tiers:

**Base Permissions (always requested):**
- `https://www.googleapis.com/auth/spreadsheets` - Read and write access to Google Sheets for data logging
- `https://www.googleapis.com/auth/drive.file` - Create new tracking sheets in Google Drive (limited to app-created files only)

**Optional Permission (requested only when browsing existing sheets):**
- `https://www.googleapis.com/auth/drive.readonly` - Browse existing spreadsheets in your Google Drive for selection via SpreadsheetPickerView

### Data Minimization
- Only collects feeding and pumping data necessary for the app's functionality
- No tracking pixels, analytics SDKs, or behavioral monitoring
- Local storage limited to app functionality and user preferences
- Haptic feedback processed locally on device

---

*Last Updated: September 3, 2025*