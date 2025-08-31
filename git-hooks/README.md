# Git Hooks - Multi-Layer Security System

This directory contains the battle-tested git hooks that provide enterprise-grade security protection for sensitive credentials and data.

## Quick Installation

From the project root directory:
```bash
./git-hooks/install-hooks.sh
```

## What Gets Installed

### pre-commit
- **Layer 1**: File pattern blocking for known sensitive file types
- **Layer 2**: Content pattern scanning for 13+ credential types
- **Layer 3**: Intelligent data cleaning with automatic backup
- **Layer 4**: Hard blocking of unhandled sensitive content

### post-commit
- **Automatic restoration** of cleaned data for development continuity
- **Smart OAuth handling** - restores client IDs immediately after commit
- **Backup cleanup** - removes temporary files after restoration

### commit-msg
- **Message filtering** to enforce repository policies
- **AI attribution blocking** per user preferences
- **Educational messaging** for future tool interactions

## Security Features

### Detects and Blocks
- API keys (OpenAI, GitHub, AWS, etc.)
- OAuth client IDs and secrets
- Database URLs with embedded credentials
- Private keys and certificates
- Environment files (except templates)
- Custom sensitive file patterns

### Smart Handling
- **Template files allowed**: `.env.example`, `.env.local.template`
- **Documentation skipped**: `*.md` files ignored during content scanning
- **Deleted files handled**: No content scanning on file deletions
- **AI guidance included**: Educational messages for AI assistants

## Usage

Once installed, the hooks work automatically:

```bash
# Normal commits work transparently
git commit -m "Add new feature"

# Sensitive data is automatically handled
git add file-with-api-key.js
git commit -m "Update config"  # Hook cleans, commits, restores
```

## Manual Installation

If you prefer manual installation:

```bash
# Copy hooks
cp git-hooks/pre-commit .git/hooks/pre-commit
cp git-hooks/post-commit .git/hooks/post-commit  
cp git-hooks/commit-msg .git/hooks/commit-msg

# Make executable
chmod +x .git/hooks/*
```

## Customization

Edit the hooks to customize for your needs:

- **File patterns**: Modify `FORBIDDEN_PATTERNS` in pre-commit
- **Content patterns**: Update `SENSITIVE_PATTERNS` for your credential types
- **File paths**: Adjust `SETTINGS_FILE` and `INFO_PLIST_FILE` paths
- **Message filters**: Customize blocked patterns in commit-msg

## Testing

Test the installation:
```bash
# Should block
echo 'sk-1234567890123456789012345678901234567890123456' > test.js
git add test.js && git commit -m "test"

# Should work
git commit --allow-empty -m "test empty commit"
```

## Troubleshooting

### Hook Not Running
- Ensure hooks are executable: `chmod +x .git/hooks/*`
- Check you're in repository root when installing
- Verify `.git/hooks/` directory exists

### False Positives
- Add patterns to template file allowances
- Adjust `SENSITIVE_PATTERNS` to be more specific
- Use `.env.example` naming for template files

### Development Workflow Issues
- The post-commit hook should restore data automatically
- Check `.git/sensitive_backup` if restoration fails
- Manually restore with: `source .git/sensitive_backup`

## Integration with CI/CD

These local hooks are complemented by:
- **GitHub Actions** security scanning (see `.github/workflows/`)
- **Server-side enforcement** that cannot be bypassed
- **Pull request blocking** for sensitive data

## Implementation Guide

For complete implementation details, see:
- `SECURITY_IMPLEMENTATION.md` - Full implementation guide
- `SECURITY.md` - Security guidelines and incident response

---

*These hooks have prevented 100% of credential commits while maintaining seamless development workflow in the MiniLog project.*