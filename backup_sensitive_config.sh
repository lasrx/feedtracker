#!/bin/bash

# Script to backup current sensitive configuration to .env.local
# This extracts sensitive values from source files and stores them safely

echo "🔐 Backing up sensitive configuration..."

# Check if SettingsView.swift exists
SETTINGS_FILE="FeedTracker/SettingsView.swift"
ENV_FILE=".env.local"

if [ ! -f "$SETTINGS_FILE" ]; then
    echo "❌ Error: $SETTINGS_FILE not found"
    exit 1
fi

# Extract current spreadsheet ID from UserDefaults (if any)
# This is a placeholder - in practice, you'd extract from where you store it
echo "# Local development configuration - DO NOT COMMIT" > "$ENV_FILE"
echo "# Updated: $(date)" >> "$ENV_FILE"
echo "" >> "$ENV_FILE"

# Check if there's a current spreadsheet ID in the UserDefaults or ask user
echo "🔍 Checking for existing spreadsheet ID..."

# You can add your actual development spreadsheet ID here
read -p "Enter your development spreadsheet ID (or press Enter to skip): " SPREADSHEET_ID

if [ -n "$SPREADSHEET_ID" ]; then
    echo "SPREADSHEET_ID=$SPREADSHEET_ID" >> "$ENV_FILE"
    echo "✅ Spreadsheet ID backed up to $ENV_FILE"
else
    echo "SPREADSHEET_ID=your_development_spreadsheet_id_here" >> "$ENV_FILE"
    echo "⚠️  Placeholder added - update $ENV_FILE with your actual spreadsheet ID"
fi

echo "" >> "$ENV_FILE"

# Backup OAuth client ID from Info.plist
read -p "Enter your OAuth client ID (or press Enter to skip): " OAUTH_CLIENT_ID

if [ -n "$OAUTH_CLIENT_ID" ]; then
    echo "OAUTH_CLIENT_ID=$OAUTH_CLIENT_ID" >> "$ENV_FILE"
    echo "✅ OAuth client ID backed up to $ENV_FILE"
else
    echo "OAUTH_CLIENT_ID=your_oauth_client_id_here" >> "$ENV_FILE"
    echo "⚠️  Placeholder added - update $ENV_FILE with your actual OAuth client ID"
fi

echo ""
echo "📝 Current $ENV_FILE contents:"
cat "$ENV_FILE"
echo ""
echo "✅ Backup complete! Edit $ENV_FILE with your actual development values."