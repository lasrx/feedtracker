#!/bin/bash

# Manual Security Audit Script
# Run this periodically to check for potential security issues

echo "🔍 FeedTracker Security Audit"
echo "=============================="

# Change to repository root
cd "$(git rev-parse --show-toplevel)"

ISSUES_FOUND=0

echo ""
echo "📁 Checking for sensitive files in working directory..."

# Check for forbidden files
FORBIDDEN_FILES=(
    ".env.local"
    ".env.development.local" 
    ".env.production.local"
    "FeedTracker/GoogleService-Info.plist"
    "GoogleService-Info.plist"
)

for file in "${FORBIDDEN_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "⚠️  Found sensitive file: $file"
        echo "   - Ensure this file is in .gitignore"
        echo "   - Never commit this file"
        ((ISSUES_FOUND++))
    fi
done

echo ""
echo "🔍 Scanning commit history for potential leaks..."

# Search commit history for sensitive patterns
SENSITIVE_WORDS=("password" "secret" "key" "token" "credential" "oauth" "api_key")

for word in "${SENSITIVE_WORDS[@]}"; do
    RESULTS=$(git log --all --grep="$word" --oneline 2>/dev/null | head -5)
    if [ -n "$RESULTS" ]; then
        echo "⚠️  Found '$word' in commit messages:"
        echo "$RESULTS" | sed 's/^/   /'
        ((ISSUES_FOUND++))
    fi
done

echo ""
echo "🔍 Checking for unwanted co-author tags..."

# Check for Claude co-author tags that user doesn't want
CLAUDE_COAUTHOR_RESULTS=$(git log --all --grep="Co-Authored-By: Claude" --oneline 2>/dev/null | head -5)
if [ -n "$CLAUDE_COAUTHOR_RESULTS" ]; then
    echo "🚨 BLOCKED: Found Claude co-author tags in commit messages:"
    echo "$CLAUDE_COAUTHOR_RESULTS" | sed 's/^/   /'
    echo "   User has requested no Claude co-author tags in commits"
    echo "   Please rewrite commit messages to remove these tags"
    ((ISSUES_FOUND++))
fi

echo ""
echo "🔍 Scanning current files for API key patterns..."

# Common API key patterns
API_PATTERNS=(
    "AIzaSy[A-Za-z0-9_-]{33}"  # Google API keys
    "ya29\.[A-Za-z0-9_-]+"     # Google OAuth tokens
    "sk-[A-Za-z0-9]{48}"       # OpenAI API keys
    "ghp_[A-Za-z0-9]{36}"      # GitHub tokens
    "AKIA[0-9A-Z]{16}"         # AWS access keys
)

for pattern in "${API_PATTERNS[@]}"; do
    RESULTS=$(grep -r -E "$pattern" . --exclude-dir=.git --exclude-dir=node_modules 2>/dev/null)
    if [ -n "$RESULTS" ]; then
        echo "🚨 CRITICAL: Found API key pattern in files:"
        echo "$RESULTS" | sed 's/^/   /'
        ((ISSUES_FOUND++))
    fi
done

echo ""
echo "📋 Checking .gitignore coverage..."

GITIGNORE_PATTERNS=(
    ".env*"
    "GoogleService-Info.plist"
    "*.key"
    "secrets.*"
    "credentials.*"
)

if [ -f ".gitignore" ]; then
    for pattern in "${GITIGNORE_PATTERNS[@]}"; do
        if ! grep -q "$pattern" .gitignore; then
            echo "⚠️  Missing .gitignore pattern: $pattern"
            ((ISSUES_FOUND++))
        fi
    done
else
    echo "🚨 CRITICAL: .gitignore file not found!"
    ((ISSUES_FOUND++))
fi

echo ""
echo "🪝 Checking pre-commit hook..."

if [ -f ".git/hooks/pre-commit" ]; then
    if [ -x ".git/hooks/pre-commit" ]; then
        echo "✅ Pre-commit hook is installed and executable"
    else
        echo "⚠️  Pre-commit hook exists but is not executable"
        echo "   Fix with: chmod +x .git/hooks/pre-commit"
        ((ISSUES_FOUND++))
    fi
else
    echo "🚨 CRITICAL: Pre-commit hook not found!"
    echo "   This is your primary defense against leaks"
    ((ISSUES_FOUND++))
fi

echo ""
echo "🔍 Checking Info.plist for exposed OAuth client ID..."

if [ -f "FeedTracker/Info.plist" ]; then
    if grep -q "com\.googleusercontent\.apps\." "FeedTracker/Info.plist"; then
        echo "⚠️  Info.plist contains real OAuth client ID"
        echo "   This should be 'YOUR_OAUTH_CLIENT_ID_HERE' in commits"
        ((ISSUES_FOUND++))
    fi
fi

echo ""
echo "🔍 Checking SettingsView.swift for exposed spreadsheet ID..."

if [ -f "FeedTracker/SettingsView.swift" ]; then
    SPREADSHEET_ID=$(grep -o 'spreadsheetId = "[^"]*"' "FeedTracker/SettingsView.swift" | sed 's/spreadsheetId = "\(.*\)"/\1/')
    if [ -n "$SPREADSHEET_ID" ] && [ "$SPREADSHEET_ID" != "" ]; then
        echo "⚠️  SettingsView.swift contains real spreadsheet ID"
        echo "   This should be empty string in commits"
        ((ISSUES_FOUND++))
    fi
fi

echo ""
echo "=============================="

if [ $ISSUES_FOUND -eq 0 ]; then
    echo "✅ Security audit complete - No issues found!"
    echo "🔒 Repository appears secure"
else
    echo "🚨 Security audit complete - $ISSUES_FOUND issues found"
    echo "📋 Please address the issues above before committing"
    echo ""
    echo "💡 Need help? Check SECURITY.md for detailed guidance"
fi

echo ""
echo "🛡️  Remember to run this audit regularly!"
echo "🔄 Consider adding this to your development workflow"

exit $ISSUES_FOUND