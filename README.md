# gh-profile

Switch between personal and work GitHub profiles with auto-detection based on project folder. Supports both git config and GitHub CLI (`gh`) authentication.

## Features

- **Auto-switch**: Automatically switches git identity AND points gh CLI at the matching profile's login, based on your project folder on session start
- **Multiple accounts**: Supports different GitHub accounts in different directories simultaneously
- **Profile switching**: Manually switch profiles when needed
- **Clone support**: Clone repos using the correct profile's credentials
- **GPG signing**: Supports different GPG signing keys per profile
- **gh CLI isolation**: Each profile has its own gh config folder (`~/.claude/gh-configs/<profile>`), so different terminals can use different accounts at the same time

## Installation

### Via Claude Code CLI (Recommended)

```bash
# Add the marketplace
claude plugin marketplace add https://github.com/tarff/gh-profile

# Install the plugin
claude plugin install gh-profile@tarff
```

### Verify Installation

```bash
# Check it's installed
claude plugin marketplace list
```

Then restart Claude Code for the plugin to load.

## Setup

1. Run `/gh-profile:setup` to configure your profiles
2. Or manually create `.claude/gh-profile.local.md` with your settings

### Configuration File

See `examples/gh-profile.local.md` for a complete configuration template.

Copy to `~/.claude/gh-profile.local.md` and edit with your settings.

### Configuration Fields

```yaml
profiles:
  personal:
    name: "Your Name"           # git user.name
    email: "you@personal.com"   # git user.email
    signing_key: ""             # GPG key ID (optional)
    gh_user: "your-gh-username" # GitHub CLI account
    paths:
      - "C:/Personal/*"         # Directories using this profile
  work:
    name: "Your Name"
    email: "you@company.com"
    signing_key: ""
    gh_user: "work-gh-username"
    paths:
      - "C:/Work/*"
default: personal               # Used when no path matches
```

## Commands

| Command | Description |
|---------|-------------|
| `/gh-profile:status` | Show current active profile, git config, and gh auth status |
| `/gh-profile:switch <profile>` | Switch to personal or work profile (git + gh auth) |
| `/gh-profile:clone <url>` | Clone a repo using the appropriate profile |
| `/gh-profile:setup` | Interactive setup wizard for profiles |

## How It Works

1. **On session start**: The plugin checks if you're in a git repository
2. **Path matching**: Compares your current directory against configured paths
3. **Auto-switch**: Applies the matching profile's git config and sets `GH_CONFIG_DIR` to `~/.claude/gh-configs/<profile>` for the session
4. **Local config**: Uses per-repository git config, so multiple Claude windows can use different profiles

## GitHub CLI Multi-Account Setup

Each profile gets its own gh config folder at `~/.claude/gh-configs/<profile>`. gh reads the folder named by `GH_CONFIG_DIR`, so each folder holds one login and nothing has to be switched back and forth.

### 1. Install GitHub CLI

Download from https://cli.github.com/

### 2. Log in once per profile

Run these in Git Bash (or any POSIX shell):

```bash
GH_CONFIG_DIR="$HOME/.claude/gh-configs/personal" gh auth login
GH_CONFIG_DIR="$HOME/.claude/gh-configs/work" gh auth login
```

Log in with your personal account for the first and your work account for the second.

### 3. Verify each login

```bash
GH_CONFIG_DIR="$HOME/.claude/gh-configs/personal" gh auth status
GH_CONFIG_DIR="$HOME/.claude/gh-configs/work" gh auth status
```

### 4. Configure gh-profile

Run `/gh-profile:setup` or add `gh_user` to your config file:

```yaml
profiles:
  personal:
    # ... other settings ...
    gh_user: "your-personal-username"
  work:
    # ... other settings ...
    gh_user: "your-work-username"
```

### 5. Done!

On session start the plugin sets `GH_CONFIG_DIR` for the matching profile and tells Claude to prefix gh commands with it.

### Optional: gh-wrapper

`hooks/gh-wrapper.sh` (and `hooks/gh-wrapper.cmd` on Windows) picks the profile from the current folder and runs `gh` with the right `GH_CONFIG_DIR`. Call it in place of `gh` in your own terminals if you want the same behaviour outside Claude Code.

### Optional: make `git push` use the same account

`gh` commands use `GH_CONFIG_DIR`, but plain `git push`/`git pull` over HTTPS use git's credential helper. To make git pick the right account by folder, create one gitconfig per profile:

```ini
# ~/.claude/gh-configs/personal.gitconfig
[credential "https://github.com"]
	helper =
	helper = !GH_CONFIG_DIR=\"C:/Users/you/.claude/gh-configs/personal\" gh auth git-credential
```

Then include it for that profile's folders in your global `~/.gitconfig`:

```ini
[includeIf "gitdir/i:C:/Personal/"]
	path = C:/Users/you/.claude/gh-configs/personal.gitconfig
```

Repeat for work.

## Manual gh Commands

```bash
# Check which account a profile is logged in as
GH_CONFIG_DIR="$HOME/.claude/gh-configs/<profile>" gh auth status

# Re-login a profile
GH_CONFIG_DIR="$HOME/.claude/gh-configs/<profile>" gh auth login
```

## Troubleshooting

### gh commands use the wrong account (or say not logged in)

Check the profile's own login:

```bash
GH_CONFIG_DIR="$HOME/.claude/gh-configs/<profile>" gh auth status
```

If it's missing or the wrong account, log in again for that profile:

```bash
GH_CONFIG_DIR="$HOME/.claude/gh-configs/<profile>" gh auth login
```

### Profile not switching automatically

1. **Restart Claude Code** after installing or updating the plugin
2. Check that your current directory matches a path pattern in your config
3. Run `/gh-profile:status` to see the current state
4. Verify your config file syntax with proper YAML formatting
5. Check that the plugin is enabled: look for `gh-profile@tarff: true` in `~/.claude/settings.json`

### Updating the plugin

To get the latest version:

```bash
# Update the marketplace
cd ~/.claude/plugins/marketplaces/tarff
git pull

# Clear the cache to force reinstall
rm -rf ~/.claude/plugins/cache/tarff

# Restart Claude Code
```

### Multiple Claude windows

Each Claude window maintains its own state. The plugin uses per-repository git config and a per-profile `GH_CONFIG_DIR`, so different windows can use different profiles simultaneously.

## License

MIT
