# gh-profile

Switch between personal and work GitHub profiles with auto-detection based on project folder. Supports both git config and GitHub CLI (`gh`) authentication.

## Features

- **Auto-switch**: Automatically switches git identity AND gh CLI auth based on your project folder on session start
- **Multiple accounts**: Supports different GitHub accounts in different directories simultaneously
- **Profile switching**: Manually switch profiles when needed
- **Clone support**: Clone repos using the correct profile's credentials
- **GPG signing**: Supports different GPG signing keys per profile
- **gh CLI integration**: Automatically switches `gh auth` when changing profiles

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
3. **Auto-switch**: Automatically applies the matching profile's git config AND switches gh CLI auth
4. **Local config**: Uses per-repository git config, so multiple Claude windows can use different profiles

## GitHub CLI Multi-Account Setup

The easiest way to use multiple GitHub accounts is with the GitHub CLI (`gh`).

### 1. Install GitHub CLI

Download from https://cli.github.com/

### 2. Log in to both accounts

```bash
# Log in to your first account
gh auth login

# Log in to your second account (same command, different credentials)
gh auth login
```

When prompted, choose the same host (github.com) - gh supports multiple accounts per host.

### 3. Verify both accounts are logged in

```bash
gh auth status
```

You should see both accounts listed.

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

The plugin will now automatically switch both git config AND gh CLI authentication when you enter different project directories.

## Manual gh auth Commands

```bash
# See all logged-in accounts
gh auth status

# Switch accounts interactively
gh auth switch

# Switch to specific account
gh auth switch --user USERNAME
```

## SSH Key Setup (Alternative)

If you prefer SSH keys over gh CLI authentication, you can still use that approach:

### 1. Generate separate SSH keys

```bash
# Personal account
ssh-keygen -t ed25519 -C "personal@email.com" -f ~/.ssh/id_ed25519_personal

# Work account
ssh-keygen -t ed25519 -C "work@email.com" -f ~/.ssh/id_ed25519_work
```

### 2. Add keys to GitHub

Add each public key to its respective GitHub account under Settings > SSH and GPG keys.

### 3. Configure SSH

Edit `~/.ssh/config`:

```
# Personal GitHub
Host github.com-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_personal
    IdentitiesOnly yes

# Work GitHub
Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_work
    IdentitiesOnly yes
```

### 4. Clone with the correct host

```bash
# Personal repos
git clone git@github.com-personal:username/repo.git

# Work repos
git clone git@github.com-work:company/repo.git
```

## Troubleshooting

### gh auth switch fails

If `gh auth switch` fails with "account not found", you need to log in to that account:

```bash
gh auth login
```

### Profile not switching automatically

1. Check that your current directory matches a path pattern in your config
2. Run `/gh-profile:status` to see the current state
3. Verify your config file syntax with proper YAML formatting

### Multiple Claude windows

Each Claude window maintains its own state. The plugin uses per-repository git config, so different windows can use different profiles simultaneously.
