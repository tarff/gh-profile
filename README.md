# gh-profile

Switch between personal and work GitHub profiles with auto-detection based on project folder.

## Features

- **Auto-detection**: Automatically detects which profile to use based on your project folder
- **Interactive prompt**: Prompts you to select a profile when starting in an unmapped git repo
- **Profile switching**: Manually switch profiles when needed
- **Clone support**: Clone repos using the correct profile's credentials
- **GPG signing**: Supports different GPG signing keys per profile

## Installation

```bash
claude --plugin-dir "/path/to/gh-profile"
```

Or add to your Claude Code plugins directory.

## Setup

1. Run `/gh-profile:setup` to configure your profiles
2. Or manually create `.claude/gh-profile.local.md` with your settings

### Configuration File

See `examples/gh-profile.local.md` for a complete configuration template.

Copy to `~/.claude/gh-profile.local.md` and edit with your settings.

## Commands

| Command | Description |
|---------|-------------|
| `/gh-profile:status` | Show current active profile and git configuration |
| `/gh-profile:switch <profile>` | Switch to personal or work profile |
| `/gh-profile:clone <url>` | Clone a repo using the appropriate profile |
| `/gh-profile:setup` | Interactive setup wizard for profiles |

## How It Works

1. **On session start**: The plugin checks if you're in a git repository
2. **Detection**: It detects if a profile config exists and shows your current git user
3. **Suggestion**: If your config doesn't match the expected profile for the path, it suggests running `/gh-profile:switch`
4. **Manual apply**: Run `/gh-profile:switch <profile>` to apply the correct `user.name`, `user.email`, and `user.signingkey`
