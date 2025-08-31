#!/bin/bash

# Install Git Hooks for Multi-Layer Security Protection
# This script installs the battle-tested security hooks into .git/hooks/

echo "🪝 Installing multi-layer security git hooks..."
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not in a git repository root"
    echo "   Please run this script from the project root directory"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Copy and install hooks
echo "📋 Installing hooks..."

if [ -f "$SCRIPT_DIR/pre-commit" ]; then
    cp "$SCRIPT_DIR/pre-commit" .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
    echo "✅ pre-commit hook installed"
else
    echo "❌ Error: pre-commit hook not found in $SCRIPT_DIR"
    exit 1
fi

if [ -f "$SCRIPT_DIR/post-commit" ]; then
    cp "$SCRIPT_DIR/post-commit" .git/hooks/post-commit
    chmod +x .git/hooks/post-commit
    echo "✅ post-commit hook installed"
else
    echo "❌ Error: post-commit hook not found in $SCRIPT_DIR"
    exit 1
fi

if [ -f "$SCRIPT_DIR/commit-msg" ]; then
    cp "$SCRIPT_DIR/commit-msg" .git/hooks/commit-msg
    chmod +x .git/hooks/commit-msg
    echo "✅ commit-msg hook installed"
else
    echo "❌ Error: commit-msg hook not found in $SCRIPT_DIR"
    exit 1
fi

echo ""
echo "🎯 Security System Installed Successfully!"
echo ""
echo "🛡️  PROTECTION LAYERS:"
echo "  Layer 1: File pattern blocking (*.key, *.pem, .env*, etc.)"
echo "  Layer 2: Content pattern scanning (API keys, tokens, OAuth IDs)"
echo "  Layer 3: Intelligent data cleaning with backup/restore"
echo "  Layer 4: Commit message filtering"
echo ""
echo "🤖 AI ASSISTANT FRIENDLY:"
echo "  The hooks include guidance for AI tools to work with the"
echo "  automatic OAuth handling system without interference."
echo ""
echo "🧪 TEST THE INSTALLATION:"
echo "  1. Try committing a file with 'sk-1234567890123456789012345678901234567890123456' in it"
echo "  2. The system should block it with helpful error messages"
echo "  3. Normal commits should work transparently"
echo ""
echo "📚 For implementation details, see:"
echo "  - SECURITY_IMPLEMENTATION.md"
echo "  - SECURITY.md"
echo ""
echo "🔒 Your repository now has enterprise-grade automatic protection!"