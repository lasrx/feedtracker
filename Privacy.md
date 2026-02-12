# MiniLog – Feed Tracker - Privacy Policy

**Effective:** September 3, 2025 | **Updated:** February 11, 2026

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

### Data Use Limitations

**We use Google user data ONLY for the following purposes:**
1. Authenticating you to access Google Sheets
2. Writing feeding and pumping data you enter to your selected Google Sheet
3. Reading your existing feeding data to display totals and analytics
4. Creating new tracking spreadsheets when requested

**We do NOT use Google user data for:**
- Advertising or marketing purposes
- Training machine learning models
- Sharing with third parties (except as required to provide the service via Google's APIs)
- Any purpose not directly related to the core feeding tracking functionality

## Third-Party Services

### Google Services
MiniLog integrates with Google services for core functionality. All Google services are governed by [Google's Privacy Policy](https://policies.google.com/privacy) and [Google Cloud Privacy](https://cloud.google.com/privacy).

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
- You create a new tracking spreadsheet (created in your Google account)

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
MiniLog requests a single permission:

- `https://www.googleapis.com/auth/spreadsheets` - Read and write access to Google Sheets for data logging and creating new tracking sheets

### Data Minimization
- Only collects feeding and pumping data necessary for the app's functionality
- No tracking pixels, analytics SDKs, or behavioral monitoring
- Local storage limited to app functionality and user preferences
- Haptic feedback processed locally on device

---

*Effective: September 3, 2025 | Updated: February 11, 2026*