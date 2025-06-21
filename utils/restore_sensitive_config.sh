#!/bin/bash

# Script to restore sensitive configuration from .env.local
# This applies backed-up sensitive values to source files for development

echo "🔄 Restoring sensitive configuration..."

# Find the correct paths regardless of where script is run from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env.local"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: $ENV_FILE not found. Run backup_sensitive_config.sh first."
    exit 1
fi

# Source the environment file
source "$ENV_FILE"

# Apply spreadsheet ID to UserDefaults storage in SettingsView
SETTINGS_FILE="$SCRIPT_DIR/FeedTracker/SettingsView.swift"

if [ ! -f "$SETTINGS_FILE" ]; then
    echo "❌ Error: $SETTINGS_FILE not found"
    exit 1
fi

if [ -n "$SPREADSHEET_ID" ] && [ "$SPREADSHEET_ID" != "your_development_spreadsheet_id_here" ]; then
    echo "📝 Applying spreadsheet ID: ${SPREADSHEET_ID:0:20}..."
    
    # Update the @AppStorage default value in SettingsView
    sed -i '' "s/@AppStorage(\"spreadsheetId\") private var spreadsheetId = \"\"/@AppStorage(\"spreadsheetId\") private var spreadsheetId = \"$SPREADSHEET_ID\"/" "$SETTINGS_FILE"
    
    echo "✅ Spreadsheet ID restored to development configuration"
else
    echo "⚠️  No valid spreadsheet ID found in $ENV_FILE"
    echo "   Please update $ENV_FILE with: SPREADSHEET_ID=your_actual_id"
fi

# Apply OAuth client ID to Info.plist
INFO_PLIST_FILE="$SCRIPT_DIR/FeedTracker/Info.plist"

if [ ! -f "$INFO_PLIST_FILE" ]; then
    echo "❌ Error: $INFO_PLIST_FILE not found"
    exit 1
fi

if [ -n "$OAUTH_CLIENT_ID" ] && [ "$OAUTH_CLIENT_ID" != "your_oauth_client_id_here" ]; then
    echo "📝 Applying OAuth client ID: ${OAUTH_CLIENT_ID:0:20}..."
    
    # Update Info.plist with the OAuth client ID
    sed -i '' "s/YOUR_OAUTH_CLIENT_ID_HERE/$OAUTH_CLIENT_ID/" "$INFO_PLIST_FILE"
    
    echo "✅ OAuth client ID restored to Info.plist"
else
    echo "⚠️  No valid OAuth client ID found in $ENV_FILE"
    echo "   Please update $ENV_FILE with: OAUTH_CLIENT_ID=your_actual_id"
fi

echo ""
echo "🔍 Current configuration status:"
grep -n "spreadsheetId.*=" "$SETTINGS_FILE" | head -1
echo ""
echo "✅ Configuration restore complete!"
echo "💡 Remember: Run clean_for_commit.sh before committing to GitHub"