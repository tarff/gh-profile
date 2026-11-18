---
description: Interactive setup wizard to configure GitHub profiles
allowed-tools: Bash, Read, Write, AskUserQuestion
---

# GitHub Profile Setup Wizard

Guide the user through setting up their personal and work GitHub profiles with both git config and gh CLI authentication.

## Steps

### Phase 1: Prerequisites Check

1. **Check for existing configuration** in `~/.claude/gh-profile.local.md`
   - If exists, ask if they want to update or start fresh

2. **Check if gh CLI is installed**:
   ```bash
   gh --version 2>/dev/null || echo "NOT_INSTALLED"
   ```
   - If not installed, inform user: "GitHub CLI (gh) is not installed. Install it from https://cli.github.com/ to enable per-profile gh logins. You can continue setup for git config only."

3. **Check each profile's gh login** (each profile has its own config folder):
   ```bash
   GH_CONFIG_DIR="$HOME/.claude/gh-configs/personal" gh auth status 2>&1
   GH_CONFIG_DIR="$HOME/.claude/gh-configs/work" gh auth status 2>&1
   ```
   - Note which profiles are logged in and as which account

4. **Get current git global config** as defaults:
   ```bash
   git config --global user.name
   git config --global user.email
   git config --global user.signingkey
   ```

### Phase 2: GitHub CLI Authentication Setup

5. **If gh is installed, guide through per-profile login**:

   Display current auth status and explain:
   ```
   GitHub CLI Authentication
   =========================
   Each profile has its own gh config folder at ~/.claude/gh-configs/<profile>,
   so you log in once per profile.

   personal: [account or "not logged in"]
   work: [account or "not logged in"]
   ```

6. **For each profile that is not logged in**, provide login instructions:
   ```
   Run this in Git Bash (or any POSIX shell), replacing <profile>:

     GH_CONFIG_DIR="$HOME/.claude/gh-configs/<profile>" gh auth login

   When prompted:
   - Choose "GitHub.com" (or your enterprise host)
   - Choose your preferred protocol (HTTPS recommended)
   - Authenticate with browser or token

   Log in with the account that belongs to that profile.
   ```

   Use AskUserQuestion:
   - "Have you logged in to all the GitHub accounts you need?"
   - Options: "Yes, continue with setup" / "I only need one account" / "I'll set up gh auth later"

### Phase 3: Collect Profile Information

**Input Validation Rules** (apply to all collected values):
- Names: Alphanumeric, spaces, hyphens, periods allowed
- Emails: Must contain `@` and valid domain format
- gh_user: Alphanumeric and hyphens only (GitHub username format)
- Paths: Valid filesystem paths, no shell metacharacters (`;`, `|`, `$`, backticks)

7. **Collect PERSONAL profile information** using AskUserQuestion:
   - Ask for git user.name (default: current git user.name)
   - Ask for git user.email
   - Ask for GPG signing key ID (optional, can be empty)
   - Ask for **gh username** for this profile (the GitHub account username)
   - Ask for folder paths that should use this profile (e.g., `C:\Personal\*`)

8. **Collect WORK profile information** using AskUserQuestion:
   - Ask for git user.name
   - Ask for git user.email
   - Ask for GPG signing key ID (optional, can be empty)
   - Ask for **gh username** for this profile (the GitHub account username)
   - Ask for folder paths that should use this profile (e.g., `C:\Work\*`)

9. **Ask for default profile** (used when no path matches)

### Phase 4: Validate and Save

10. **Validate gh usernames** (if gh is installed), for each profile:
    ```bash
    GH_CONFIG_DIR="$HOME/.claude/gh-configs/[profile]" gh auth status 2>&1 | grep -i "[username]" || echo "NOT_FOUND"
    ```
    - Warn if a profile's gh_user isn't the account logged in to that profile's folder
    - Suggest `GH_CONFIG_DIR="$HOME/.claude/gh-configs/[profile]" gh auth login` to fix it

11. **Ensure directory exists**:
    ```bash
    mkdir -p ~/.claude
    ```

12. **Create the configuration file** at `~/.claude/gh-profile.local.md`:

```yaml
---
profiles:
  personal:
    name: "[collected name]"
    email: "[collected email]"
    signing_key: "[collected key or empty string]"
    gh_user: "[collected gh username]"
    paths:
      - "[collected paths]"
  work:
    name: "[collected name]"
    email: "[collected email]"
    signing_key: "[collected key or empty string]"
    gh_user: "[collected gh username]"
    paths:
      - "[collected paths]"
default: [personal or work]
---

# GitHub Profile Configuration

This file stores your GitHub profile settings for the gh-profile plugin.
Edit the YAML frontmatter above to update your profiles.

## Fields

- **name**: Git user.name for commits
- **email**: Git user.email for commits
- **signing_key**: GPG key ID for signing commits (optional)
- **gh_user**: GitHub CLI account username for `gh` commands
- **paths**: Directory patterns that trigger this profile

## Usage

- `/gh-profile:status` - See current profile and git config
- `/gh-profile:switch personal` - Switch to personal profile
- `/gh-profile:switch work` - Switch to work profile
- `/gh-profile:clone owner/repo` - Clone with correct profile

## Managing gh CLI Accounts

Each profile has its own gh config folder at ~/.claude/gh-configs/<profile>.

To log in a profile:
  GH_CONFIG_DIR="$HOME/.claude/gh-configs/<profile>" gh auth login

To check a profile's login:
  GH_CONFIG_DIR="$HOME/.claude/gh-configs/<profile>" gh auth status
```

### Phase 5: Confirmation

13. **Confirm setup complete** and show a summary:
    ```
    Setup Complete!
    ===============

    Personal Profile:
    - Git: [name] <[email]>
    - GitHub CLI: [gh_user]
    - Paths: [paths]

    Work Profile:
    - Git: [name] <[email]>
    - GitHub CLI: [gh_user]
    - Paths: [paths]

    Default: [profile]
    ```

14. **Offer to apply a profile now** if currently in a git repository:
    - Detect which profile matches current directory
    - Ask if user wants to apply it
