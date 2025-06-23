# 🔒 Security Guidelines for FeedTracker

## ⚠️ CRITICAL: Protecting Sensitive Data

This repository contains iOS app code that integrates with Google APIs. **NEVER commit sensitive credentials** to version control.

## 🚨 Files That Must NEVER Be Committed

### Environment Files
- `.env.local` - Contains actual API keys and credentials  
- `.env.*` - Any environment configuration files
- `GoogleService-Info.plist` - OAuth configuration from Google Cloud Console

### Development Files  
- Any file containing real API keys, tokens, or credentials
- Database connection strings with passwords
- OAuth client secrets
- Private keys (.key, .pem, .p12 files)

## 🛡️ Multi-Layer Protection System

### Layer 1: .gitignore Protection
Comprehensive patterns block sensitive files:
```
.env*
GoogleService-Info.plist  
*.key
secrets.*
credentials.*
```

### Layer 2: Enhanced Pre-Commit Hook
Automatically scans for:
- ✅ Forbidden file patterns (.env*, GoogleService-Info.plist)
- ✅ API key patterns (Google, AWS, GitHub, etc.)
- ✅ OAuth client IDs and tokens
- ✅ Database connection strings
- ✅ Development credentials in code

### Layer 3: Content Cleaning
Automatically replaces sensitive values in:
- `SettingsView.swift` - Clears spreadsheet IDs
- `Info.plist` - Replaces OAuth client IDs with placeholders

### Layer 4: Hard Blocking
**COMMITS ARE BLOCKED** if sensitive patterns are detected.

## 🔧 Setup for New Developers

### 1. Clone Repository
```bash
git clone https://github.com/lasrx/feedtracker.git
cd feedtracker
```

### 2. Create Local Environment File
```bash
cp .env.example .env.local
# Edit .env.local with your actual credentials
```

### 3. Configure Google OAuth
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create OAuth 2.0 credentials
3. Download `GoogleService-Info.plist`
4. Place in project root (already in .gitignore)

### 4. Verify Security Setup
```bash
# Test that pre-commit hook works
git add .env.local  # This should be BLOCKED
git commit -m "test"  # Should fail with security warning
```

## 🚨 If You Accidentally Commit Sensitive Data

### Immediate Actions
1. **STOP** - Don't make more commits
2. **Rotate credentials immediately**:
   - Generate new OAuth credentials in Google Cloud Console
   - Create new API keys
   - Update local files with new credentials
3. **Contact GitHub support** to purge the commit permanently
4. **Check commit history** for other potential leaks

### Recovery Commands
```bash
# Remove file from staging
git reset HEAD sensitive_file.txt

# Remove from repository completely
git rm --cached sensitive_file.txt

# Rewrite history (DANGEROUS - coordinate with team)
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch sensitive_file.txt' \
  --prune-empty --tag-name-filter cat -- --all
```

## 📋 Security Checklist

Before every commit:
- [ ] No .env* files staged
- [ ] No GoogleService-Info.plist staged  
- [ ] No real API keys in code
- [ ] No real OAuth client IDs in Info.plist
- [ ] No real spreadsheet IDs in SettingsView.swift
- [ ] Pre-commit hook executed successfully

## 🔍 Regular Security Audits

### Monthly Review
- [ ] Check .gitignore coverage
- [ ] Test pre-commit hook effectiveness
- [ ] Scan commit history for accidental leaks
- [ ] Rotate long-lived credentials

### Tools for Auditing
```bash
# Search entire history for potential secrets
git log --all --grep="password\|secret\|key\|token" --oneline

# Check current repository for sensitive patterns
grep -r "AIzaSy" . --exclude-dir=.git
grep -r "sk-" . --exclude-dir=.git  
grep -r "ghp_" . --exclude-dir=.git
```

## 🛠️ Advanced Protection

### Git Hooks Installation
```bash
# Install pre-commit hook globally for all repos
git config --global init.templatedir ~/.git-template
mkdir -p ~/.git-template/hooks
cp .git/hooks/pre-commit ~/.git-template/hooks/
```

### IDE Integration
- **VS Code**: Install GitLens extension for commit safety
- **Xcode**: Enable version control warnings
- **Terminal**: Use `git status` before every commit

## 📞 Security Incident Response

If sensitive data is exposed:
1. **Document the exposure** - What was leaked? For how long?
2. **Rotate all affected credentials** immediately
3. **Contact platform support** (GitHub, Google, etc.)
4. **Review access logs** for unauthorized usage
5. **Update security measures** to prevent recurrence
6. **Team notification** if working with others

## 🔗 Resources

- [GitHub Security Best Practices](https://docs.github.com/en/code-security)
- [Google Cloud Security](https://cloud.google.com/security)
- [OWASP API Security](https://owasp.org/www-project-api-security/)
- [Git Security Guide](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage)

---

**Remember**: Security is everyone's responsibility. When in doubt, ask for a review before committing.