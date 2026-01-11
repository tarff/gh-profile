---
profiles:
  personal:
    name: "Your Name"
    email: "your.personal@email.com"
    signing_key: "ABCD1234EFGH5678"
    gh_user: "your-personal-username"
    paths:
      - "C:\\Personal\\*"
      - "C:\\Users\\YourName\\personal-projects\\*"
      - "D:\\hobby-projects\\*"
  work:
    name: "Your Name"
    email: "your.name@company.com"
    signing_key: "WXYZ9876STUV5432"
    gh_user: "your-work-username"
    paths:
      - "C:\\Work\\*"
      - "C:\\Users\\YourName\\work\\*"
      - "C:\\Projects\\company-name\\*"
default: personal
---

# GitHub Profile Configuration

This file stores your GitHub profile settings for the gh-profile plugin.

## How to Use

1. Copy this file to `~/.claude/gh-profile.local.md` (for global config)
2. Or copy to `<project>/.claude/gh-profile.local.md` (for project-specific override)
3. Edit the YAML frontmatter above with your actual settings

## Profile Fields

- **name**: Your git user.name for this profile
- **email**: Your git user.email for this profile
- **signing_key**: Your GPG key ID for signing commits (optional, can be empty string)
- **gh_user**: Your GitHub username for this profile (used for `gh auth switch`)
- **paths**: Array of path patterns that should use this profile (supports * wildcard)

## Path Patterns

Use `*` as a wildcard:
- `C:\\Work\\*` matches `C:\Work\project1`, `C:\Work\project2`, etc.
- `C:\\Users\\YourName\\repos\\client-*` matches client-specific folders

## Commands

- `/gh-profile:status` - See current profile, git config, and gh auth status
- `/gh-profile:switch personal` - Switch to personal profile (git + gh auth)
- `/gh-profile:switch work` - Switch to work profile (git + gh auth)
- `/gh-profile:clone owner/repo` - Clone with correct profile
- `/gh-profile:setup` - Run setup wizard

## GitHub CLI Multi-Account Setup

To use different GitHub accounts for personal and work:

1. Log in to your first account:
   ```
   gh auth login
   ```

2. Log in to your second account:
   ```
   gh auth login
   ```
   (Choose the same host, it will add as a second account)

3. Verify both are logged in:
   ```
   gh auth status
   ```

4. The plugin will automatically switch between them based on your directory!

## Manual gh auth commands

- `gh auth status` - See all logged-in accounts
- `gh auth switch` - Interactively switch accounts
- `gh auth switch --user USERNAME` - Switch to specific account
