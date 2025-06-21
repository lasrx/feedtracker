#!/bin/bash

# Script to set up secure development environment for FeedTracker
# This initializes the secure workflow for handling sensitive configuration

echo "🚀 Setting up FeedTracker secure development environment..."
echo ""

# Step 1: Set up .env.local from template
if [ ! -f ".env.local" ]; then
    if [ -f ".env.local.template" ]; then
        echo "1️⃣ Creating .env.local from template..."
        cp .env.local.template .env.local
        echo "✅ Created .env.local from template"
    else
        echo "1️⃣ Creating .env.local template..."
        cat > .env.local << 'EOF'
# Local development configuration - DO NOT COMMIT
# TEMPLATE: Replace placeholder values with your actual development data

# Google Sheets Configuration
SPREADSHEET_ID=your_development_spreadsheet_id_here

# Setup Instructions:
# 1. Replace values above with your actual development data
# 2. Run: ./restore_sensitive_config.sh
# 3. Start developing!
EOF
        echo "✅ Created .env.local template"
    fi
else
    echo "1️⃣ .env.local already exists ✅"
fi

# Step 2: Verify .gitignore protection
echo ""
echo "2️⃣ Verifying .gitignore protection..."
if grep -q ".env.local" .gitignore; then
    echo "✅ .env.local is protected by .gitignore"
else
    echo "⚠️  Adding .env.local to .gitignore..."
    echo ".env.local" >> .gitignore
fi

# Step 3: Check script permissions
echo ""
echo "3️⃣ Checking script permissions..."
for script in backup_sensitive_config.sh restore_sensitive_config.sh clean_for_commit.sh; do
    if [ -x "$script" ]; then
        echo "✅ $script is executable"
    else
        echo "🔧 Making $script executable..."
        chmod +x "$script"
    fi
done

# Step 4: Initial configuration
echo ""
echo "4️⃣ Development environment setup:"
echo ""
echo "📁 Project structure:"
echo "├── .env.local                    # Your sensitive config (git-ignored)"
echo "├── backup_sensitive_config.sh    # Extract current sensitive values"
echo "├── restore_sensitive_config.sh   # Apply sensitive values from .env.local"
echo "├── clean_for_commit.sh          # Safe commit with auto-cleanup"
echo "└── setup_dev_environment.sh     # This setup script"
echo ""

# Step 5: Usage instructions
echo "📖 USAGE INSTRUCTIONS:"
echo ""
echo "🔧 INITIAL SETUP:"
echo "   1. Edit .env.local with your actual development values:"
echo "      SPREADSHEET_ID=your_actual_spreadsheet_id"
echo ""
echo "   2. Apply development config:"
echo "      ./restore_sensitive_config.sh"
echo ""
echo "🔒 SECURE COMMITS:"
echo "   Use this instead of 'git commit':"
echo "   ./clean_for_commit.sh \"Your commit message\""
echo ""
echo "   This automatically:"
echo "   ✓ Backs up your sensitive config"
echo "   ✓ Cleans sensitive data for commit"
echo "   ✓ Commits to GitHub with clean code"
echo "   ✓ Restores your development config"
echo ""
echo "🔄 MANUAL RESTORE (if needed):"
echo "   ./restore_sensitive_config.sh"
echo ""

# Step 6: Next steps
echo "🎯 NEXT STEPS:"
echo "1. Edit .env.local with your development spreadsheet ID"
echo "2. Run: ./restore_sensitive_config.sh"
echo "3. Start developing!"
echo "4. Use: ./clean_for_commit.sh \"message\" for all commits"
echo ""
echo "✅ Secure development environment ready!"
echo "🔒 Your sensitive data will never be committed to GitHub again!"