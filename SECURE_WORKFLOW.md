# 🔒 Secure Development Workflow

This document outlines the secure development workflow to prevent sensitive configuration data from being committed to GitHub.

## 📋 Overview

The FeedTracker project uses a secure workflow that:
- ✅ Keeps sensitive data (spreadsheet IDs, OAuth client IDs) in local files only
- ✅ Automatically cleans sensitive data before commits
- ✅ Restores development configuration after commits
- ✅ Prevents accidental exposure in version control

## 🛠️ Setup

### Initial Setup
```bash
# Run the setup script
./setup_dev_environment.sh

# Install automatic git hooks (RECOMMENDED)
./install_git_hooks.sh

# Edit your local configuration
nano .env.local

# Apply development configuration
./restore_sensitive_config.sh
```

### Your .env.local should look like:
```bash
# Local development configuration - DO NOT COMMIT
SPREADSHEET_ID=your_actual_spreadsheet_id_here
OAUTH_CLIENT_ID=your_actual_oauth_client_id_here
```

## 🔄 Daily Workflow

### Making Commits

**Option 1: Automatic (Recommended)**
If you installed git hooks, just use normal git:
```bash
git commit -m "Your commit message"
```
The hooks automatically clean/restore sensitive data!

**Option 2: Manual**
If you prefer manual control:
```bash
./clean_for_commit.sh "Your commit message"
```

Both methods:
1. 🔐 Back up your current sensitive config
2. 🧹 Clean sensitive data (sets to empty strings)
3. 📝 Commit clean code to GitHub
4. 🔄 Restore your development config
5. 💻 Leave you ready to continue developing

### Manual Operations

**Restore development config:**
```bash
./restore_sensitive_config.sh
```

**Backup current sensitive values:**
```bash
./backup_sensitive_config.sh
```

## 📁 File Structure

```
FeedTracker/
├── .env.local                     # Your sensitive config (git-ignored)
├── backup_sensitive_config.sh     # Extract current sensitive values
├── restore_sensitive_config.sh    # Apply values from .env.local
├── clean_for_commit.sh            # Safe commit workflow
├── setup_dev_environment.sh       # Initial setup
└── SECURE_WORKFLOW.md            # This documentation
```

## 🔒 Security Features

### Protected Files
- `.env.local` - Git-ignored, contains your development values
- `sensitive_backup.*` - Temporary files, git-ignored
- All scripts automatically handle cleanup

### What Gets Committed
- ✅ Empty spreadsheet IDs (`""`)
- ✅ OAuth client ID placeholders (`YOUR_OAUTH_CLIENT_ID_HERE`)
- ✅ No sensitive development data
- ✅ Clean, shareable code

### What Stays Local
- 🔐 Your actual spreadsheet IDs
- 🔐 OAuth client IDs and secrets
- 🔐 Development configuration

## 🚨 Emergency Recovery

If you accidentally commit sensitive data:

1. **Stop immediately** - Don't push to GitHub yet
2. **Reset the commit:**
   ```bash
   git reset --soft HEAD~1
   ```
3. **Clean and recommit:**
   ```bash
   ./clean_for_commit.sh "Fixed: removed sensitive data"
   ```

If already pushed to GitHub:
```bash
git push --force-with-lease origin main
```
*(This rewrites GitHub history - use carefully)*

## ✅ Best Practices

1. **Never use `git commit` directly** - Always use `./clean_for_commit.sh`
2. **Keep .env.local updated** with your current development values
3. **Run `./restore_sensitive_config.sh`** after pulling changes
4. **Check commit diffs** before pushing to verify cleanliness
5. **Document new sensitive config** in this workflow

## 🎯 Benefits

- 🔒 **Security**: Never accidentally expose sensitive data
- 🤖 **Automation**: No manual cleanup required
- 🔄 **Seamless**: Continue development without interruption
- 📈 **Scalable**: Easy to add new sensitive configuration
- 👥 **Team-friendly**: Safe for multiple developers

---

**Remember**: This workflow protects you from accidentally committing sensitive data while keeping your development environment fully functional!