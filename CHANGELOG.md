# Changelog

All notable changes to the gh-profile plugin will be documented in this file.

## [1.1.0] - 2025-01-11

### Added
- **GitHub CLI (gh) authentication switching**: Automatically switch `gh auth` when changing profiles
- New `gh_user` field in profile configuration for specifying GitHub CLI account
- Multi-account login instructions in setup wizard
- `gh auth status` display in `/gh-profile:status` command
- Input validation rules for profile configuration

### Fixed
- **Windows path format compatibility**: Fixed `/c/path` vs `C:/path` mismatch between Git Bash and Windows
- **Regex injection vulnerability**: All regex metacharacters now properly escaped in path patterns
- **JSON injection vulnerability**: Double quotes properly escaped in JSON output
- **Paths with spaces**: Now handled correctly using IFS-safe while-read loops
- Root folder matching: Added support for matching root folders (e.g., `C:/Projects`) in addition to subdirectories

### Changed
- Hook script refactored with utility functions for better maintainability
- Improved error messages with actionable guidance
- Updated README with comprehensive gh CLI multi-account setup instructions

### Security
- Added `escape_for_regex()` function to prevent regex injection attacks
- Added `json_escape()` function to prevent JSON injection
- Added input validation for required fields and email format
- Added security notes in command files for shell injection prevention

## [1.0.0] - 2025-01-11

### Added
- Initial release
- Auto-switch git identity based on project folder
- Support for personal and work profiles
- Path pattern matching with glob wildcards
- GPG signing key support
- Commands: `/gh-profile:status`, `/gh-profile:switch`, `/gh-profile:clone`, `/gh-profile:setup`
- SessionStart hook for automatic profile detection
