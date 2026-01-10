# gh-profile

Switch between personal and work GitHub profiles with auto-detection based on project folder.

## Features

- **Auto-switch**: Automatically switches git identity based on your project folder on session start
- **Multiple accounts**: Supports different GitHub accounts in different directories simultaneously
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
2. **Path matching**: Compares your current directory against configured paths
3. **Auto-switch**: Automatically applies the matching profile's `user.name`, `user.email`, and `user.signingkey`
4. **Local config**: Uses per-repository git config, so multiple Claude windows can use different profiles

## Multiple GitHub Accounts

To use different GitHub accounts in different directories (e.g., personal and work), you need to configure SSH keys:

### 1. Generate separate SSH keys

```bash
# Personal account
ssh-keygen -t ed25519 -C "personal@email.com" -f ~/.ssh/id_ed25519_personal

# Work account
ssh-keygen -t ed25519 -C "work@email.com" -f ~/.ssh/id_ed25519_work
```

### 2. Add keys to GitHub

Add each public key to its respective GitHub account under Settings → SSH and GPG keys.

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

### 5. Update existing repos

For existing repos, update the remote URL:

```bash
# Check current remote
git remote -v

# Update to use correct host alias
git remote set-url origin git@github.com-personal:username/repo.git
```

This allows you to have two Claude windows open - one in a personal project and one in a work project - each using the correct GitHub account.
