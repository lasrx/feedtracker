#!/bin/bash

# Script to install actual git hooks for automatic sensitive data protection
# This creates true pre-commit and post-commit hooks

echo "🪝 Installing automatic git hooks for sensitive data protection..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not in a git repository root"
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Create pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

# Automatic pre-commit hook: Clean sensitive data before commit
echo "🔍 Pre-commit: Checking for sensitive data..."

SETTINGS_FILE="FeedTracker/SettingsView.swift"
BACKUP_FILE=".git/sensitive_backup"

# Check if SettingsView exists
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "✅ No SettingsView.swift found, proceeding with commit"
    exit 0
fi

# Check for non-empty spreadsheet ID
CURRENT_ID=$(grep -o 'spreadsheetId = "[^"]*"' "$SETTINGS_FILE" | sed 's/spreadsheetId = "\(.*\)"/\1/')

if [ -n "$CURRENT_ID" ] && [ "$CURRENT_ID" != "" ]; then
    echo "🔐 Found sensitive data - automatically cleaning for commit..."
    
    # Backup the sensitive data
    echo "SPREADSHEET_ID=$CURRENT_ID" > "$BACKUP_FILE"
    
    # Clean the sensitive data
    sed -i '' 's/@AppStorage("spreadsheetId") private var spreadsheetId = "[^"]*"/@AppStorage("spreadsheetId") private var spreadsheetId = ""/' "$SETTINGS_FILE"
    
    # Re-stage the cleaned file
    git add "$SETTINGS_FILE"
    
    echo "✅ Sensitive data cleaned and backup created"
    echo "📝 Commit will proceed with clean code"
else
    echo "✅ No sensitive data found, proceeding with commit"
fi

exit 0
EOF

# Create post-commit hook
cat > .git/hooks/post-commit << 'EOF'
#!/bin/bash

# Automatic post-commit hook: Restore sensitive data after commit
echo "🔄 Post-commit: Restoring development configuration..."

SETTINGS_FILE="FeedTracker/SettingsView.swift"
BACKUP_FILE=".git/sensitive_backup"

# Check if we have a backup to restore
if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
    source "$BACKUP_FILE"
    
    if [ -n "$SPREADSHEET_ID" ] && [ -f "$SETTINGS_FILE" ]; then
        # Restore the sensitive data
        sed -i '' "s/@AppStorage(\"spreadsheetId\") private var spreadsheetId = \"\"/@AppStorage(\"spreadsheetId\") private var spreadsheetId = \"$SPREADSHEET_ID\"/" "$SETTINGS_FILE"
        
        echo "✅ Development configuration restored: ${SPREADSHEET_ID:0:20}..."
    fi
    
    # Clean up the backup
    rm -f "$BACKUP_FILE"
else
    echo "ℹ️  No sensitive data to restore"
fi

echo "💻 Ready to continue development!"
EOF

# Make hooks executable
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/post-commit

echo "✅ Git hooks installed successfully!"
echo ""
echo "🎯 What happens now:"
echo "  • Every 'git commit' automatically cleans sensitive data"
echo "  • After commit, your development config is automatically restored"
echo "  • No need to remember to use special scripts!"
echo ""
echo "🧪 Test the hooks:"
echo "  1. Edit .env.local with your spreadsheet ID"
echo "  2. Run: ./restore_sensitive_config.sh"
echo "  3. Try a normal: git commit -m \"test commit\""
echo "  4. Check that your development config is restored!"
echo ""
echo "🔒 Your repository now has TRUE automatic protection!"