# Changelog

All notable changes to the gh-profile plugin will be documented in this file.

## [1.2.4] - 2026-11-18

### Fixed
- **gh account isolation**: The SessionStart hook now writes `GH_CONFIG_DIR` to `CLAUDE_ENV_FILE` so later Bash commands use the profile's login, and sends its instructions to Claude through `additionalContext`. The old `env` output field was never supported.
- **Windows paths**: Paths written with escaped backslashes (`"C:\\Work\\*"`, as in the example config) now match
- **Config parsing**: Trailing `# comments`, single-quoted values and unquoted values now work. Before, `default: personal  # comment` (as in the README) gave "Invalid default profile"
- **gh-wrapper**: Uses the same path matching as the hook (new `hooks/profile-lib.sh`), so both always pick the same profile and treat characters like `(` literally
- **Signing**: A profile without a `signing_key` now removes the signing settings a previous profile added, and leaves settings you set yourself. A profile with a key always turns signing on. `/gh-profile:switch` and `/gh-profile:clone` follow the same rules
- **Linux/macOS**: Hook scripts are now committed as executable
- **Escaping**: The `gh` commands in the session start message are shell-escaped, and the message stays valid JSON when a path contains `\`. Double-quoted config values decode `\"` and `\\`, so `name: "Alice \"Ace\" Smith"` works

### Added
- Warning at session start when a profile has no signing key but commits will still be signed with another key

## [1.2.3] - 2026-10-14

### Fixed
- **`/gh-profile:switch` and `/gh-profile:clone`**: Use the profile's own gh config folder (`GH_CONFIG_DIR`) instead of `gh auth switch`, which no longer matched how logins are stored

### Changed
- README, setup wizard and example config now describe logging in once per profile folder, the `gh-wrapper` script, and optional per-folder git credentials

## [1.2.2] - 2026-02-25

### Fixed
- Republished so the marketplace picks up the Windows Git Bash sed path fix from 1.2.1

## [1.2.1] - 2026-01-14

### Added
- **Per-profile `GH_CONFIG_DIR`**: Each profile gets its own gh config folder at `~/.claude/gh-configs/<profile>`, so different terminals can use different accounts at once
- Session start message tells Claude to prefix gh commands with the profile's `GH_CONFIG_DIR`
- `hooks/gh-wrapper.sh` / `gh-wrapper.cmd`: run gh with the profile picked from the current folder

### Fixed
- Windows-compatible hook wrapper (`run-hook.cmd`)
- sed path conversion under Windows Git Bash
- Commands and hooks moved to the plugin root; marketplace name matches directory name

### Changed
- README: plugin update and restart instructions

## [1.2.0] - 2025-01-11

### Fixed
- **Hook configuration format**: Removed incorrect nested `"hooks"` wrapper in hooks.json that prevented plugin from loading
- **Command frontmatter format**: Simplified to match Claude Code expected format (comma-separated `allowed-tools`, removed redundant `name` field)

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
