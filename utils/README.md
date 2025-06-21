# Utility Scripts

This directory contains utility scripts for secure development and repository management.

## Security Scripts

### `clean_for_commit.sh`
**Primary security script** - Use this for all commits with sensitive data.
```bash
./utils/clean_for_commit.sh "Your commit message"
```
- Automatically cleans OAuth client IDs and spreadsheet IDs before commit
- Creates backups and restores development configuration after commit
- Handles both old and new OAuth URL scheme formats

### `backup_sensitive_config.sh`
Manually backup sensitive configuration files.
```bash
./utils/backup_sensitive_config.sh
```

### `restore_sensitive_config.sh`
Manually restore sensitive configuration from backups.
```bash
./utils/restore_sensitive_config.sh
```

## Development Setup Scripts

### `install_git_hooks.sh`
Install automatic git hooks for commit protection.
```bash
./utils/install_git_hooks.sh
```
- Sets up pre-commit and post-commit hooks
- Automatically cleans sensitive data on every commit
- Restores development configuration after commits

### `setup_dev_environment.sh`
Complete development environment setup.
```bash
./utils/setup_dev_environment.sh
```

## Usage Notes

- **Always use `clean_for_commit.sh`** instead of `git commit` directly when working with sensitive files
- Git hooks provide automatic protection but manual script offers more control
- All scripts are designed to work from the project root directory
- Scripts handle both Info.plist (OAuth) and SettingsView.swift (spreadsheet ID) automatically

## File Paths

Scripts are designed to work with these sensitive files:
- `FeedTracker/Info.plist` - OAuth client ID
- `FeedTracker/SettingsView.swift` - Spreadsheet ID
- `FeedTracker/GoogleService-Info.plist` - OAuth secrets (git-ignored)