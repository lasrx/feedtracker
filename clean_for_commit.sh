#!/bin/bash

# Script to safely commit code with sensitive data cleaned
# Usage: ./clean_for_commit.sh "commit message"

if [ $# -eq 0 ]; then
    echo "❌ Error: Please provide a commit message"
    echo "Usage: ./clean_for_commit.sh \"Your commit message\""
    exit 1
fi

COMMIT_MESSAGE="$1"
SETTINGS_FILE="FeedTracker/SettingsView.swift"
INFO_PLIST_FILE="FeedTracker/Info.plist"
BACKUP_FILE="sensitive_backup.tmp"

echo "🧹 Starting secure commit process..."
echo "📝 Commit message: $COMMIT_MESSAGE"
echo ""

# Step 1: Backup current sensitive configuration
echo "1️⃣ Backing up current configuration..."
touch "$BACKUP_FILE"

if [ -f "$SETTINGS_FILE" ]; then
    # Extract current spreadsheet ID from SettingsView
    CURRENT_ID=$(grep -o 'spreadsheetId = "[^"]*"' "$SETTINGS_FILE" | sed 's/spreadsheetId = "\(.*\)"/\1/')
    
    if [ -n "$CURRENT_ID" ] && [ "$CURRENT_ID" != "" ]; then
        echo "SPREADSHEET_ID=$CURRENT_ID" > "$BACKUP_FILE"
        echo "✅ Current spreadsheet ID backed up: ${CURRENT_ID:0:20}..."
    else
        echo "ℹ️  No spreadsheet ID found to backup"
    fi
else
    echo "❌ Error: $SETTINGS_FILE not found"
    exit 1
fi

if [ -f "$INFO_PLIST_FILE" ]; then
    # Extract current OAuth client ID from Info.plist
    CURRENT_OAUTH_ID=$(grep -A 1 "CFBundleURLSchemes" "$INFO_PLIST_FILE" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/' | head -1)
    
    if [ -n "$CURRENT_OAUTH_ID" ] && [ "$CURRENT_OAUTH_ID" != "YOUR_OAUTH_CLIENT_ID_HERE" ]; then
        echo "OAUTH_CLIENT_ID=$CURRENT_OAUTH_ID" >> "$BACKUP_FILE"
        echo "✅ Current OAuth client ID backed up: ${CURRENT_OAUTH_ID:0:20}..."
    else
        echo "ℹ️  No OAuth client ID found to backup"
    fi
else
    echo "❌ Error: $INFO_PLIST_FILE not found"
    exit 1
fi

# Step 2: Clean sensitive data
echo ""
echo "2️⃣ Cleaning sensitive data..."
sed -i '' 's/@AppStorage("spreadsheetId") private var spreadsheetId = "[^"]*"/@AppStorage("spreadsheetId") private var spreadsheetId = ""/' "$SETTINGS_FILE"
echo "✅ Spreadsheet ID cleaned (set to empty string)"

# Clean OAuth client ID in Info.plist
sed -i '' 's/<string>com\.googleusercontent\.apps\.[^<]*<\/string>/<string>YOUR_OAUTH_CLIENT_ID_HERE<\/string>/' "$INFO_PLIST_FILE"
echo "✅ OAuth client ID cleaned (set to placeholder)"

# Step 3: Show what will be committed
echo ""
echo "3️⃣ Review changes to be committed:"
git diff "$SETTINGS_FILE" | grep -E "^[+-].*spreadsheetId" || echo "No spreadsheet ID changes detected"
git diff "$INFO_PLIST_FILE" | grep -E "^[+-].*string" || echo "No Info.plist changes detected"

# Step 4: Stage and commit
echo ""
echo "4️⃣ Staging and committing..."
git add .
git commit -m "$COMMIT_MESSAGE"

if [ $? -eq 0 ]; then
    echo "✅ Commit successful!"
    
    # Step 5: Restore sensitive data
    echo ""
    echo "5️⃣ Restoring development configuration..."
    
    if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
        source "$BACKUP_FILE"
        if [ -n "$SPREADSHEET_ID" ]; then
            sed -i '' "s/@AppStorage(\"spreadsheetId\") private var spreadsheetId = \"\"/@AppStorage(\"spreadsheetId\") private var spreadsheetId = \"$SPREADSHEET_ID\"/" "$SETTINGS_FILE"
            echo "✅ Spreadsheet ID restored: ${SPREADSHEET_ID:0:20}..."
        fi
        if [ -n "$OAUTH_CLIENT_ID" ]; then
            sed -i '' "s/YOUR_OAUTH_CLIENT_ID_HERE/$OAUTH_CLIENT_ID/" "$INFO_PLIST_FILE"
            echo "✅ OAuth client ID restored: ${OAUTH_CLIENT_ID:0:20}..."
        fi
    fi
    
    # Clean up temporary backup
    rm -f "$BACKUP_FILE"
    
    echo ""
    echo "🎉 Secure commit complete!"
    echo "🔒 GitHub will receive clean code with no sensitive data"
    echo "💻 Your local development environment is ready to continue"
else
    echo "❌ Commit failed. Restoring original configuration..."
    
    # Restore on failure
    if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
        source "$BACKUP_FILE"
        if [ -n "$SPREADSHEET_ID" ]; then
            sed -i '' "s/@AppStorage(\"spreadsheetId\") private var spreadsheetId = \"\"/@AppStorage(\"spreadsheetId\") private var spreadsheetId = \"$SPREADSHEET_ID\"/" "$SETTINGS_FILE"
        fi
        if [ -n "$OAUTH_CLIENT_ID" ]; then
            sed -i '' "s/YOUR_OAUTH_CLIENT_ID_HERE/$OAUTH_CLIENT_ID/" "$INFO_PLIST_FILE"
        fi
    fi
    
    rm -f "$BACKUP_FILE"
    exit 1
fi