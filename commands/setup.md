---
name: setup
description: Interactive setup wizard to configure GitHub profiles
allowed-tools:
  - Bash
  - Read
  - Write
  - AskUserQuestion
---

# GitHub Profile Setup Wizard

Guide the user through setting up their personal and work GitHub profiles.

## Steps

1. **Check for existing configuration** in `~/.claude/gh-profile.local.md`
   - If exists, ask if they want to update or start fresh

2. **Get current git global config** as defaults:
   ```bash
   git config --global user.name
   git config --global user.email
   git config --global user.signingkey
   ```

3. **Collect PERSONAL profile information** using AskUserQuestion:
   - Ask for name (default: current git user.name)
   - Ask for email
   - Ask for GPG signing key ID
   - Ask for folder paths that should use this profile (e.g., `C:\Personal\*`)

4. **Collect WORK profile information** using AskUserQuestion:
   - Ask for name
   - Ask for email
   - Ask for GPG signing key ID
   - Ask for folder paths that should use this profile (e.g., `C:\Work\*`)

5. **Ask for default profile** (used when no path matches)

6. **Ensure directory exists**:
   ```bash
   mkdir -p ~/.claude
   ```

7. **Create the configuration file** at `~/.claude/gh-profile.local.md`:

```yaml
---
profiles:
  personal:
    name: "[collected name]"
    email: "[collected email]"
    signing_key: "[collected key]"
    paths:
      - "[collected paths]"
  work:
    name: "[collected name]"
    email: "[collected email]"
    signing_key: "[collected key]"
    paths:
      - "[collected paths]"
default: [personal or work]
---

# GitHub Profile Configuration

This file stores your GitHub profile settings for the gh-profile plugin.
Edit the YAML frontmatter above to update your profiles.

## Usage

- Profiles are automatically selected based on the `paths` patterns
- Use `/gh-profile:switch <profile>` to manually switch
- Use `/gh-profile:status` to see current settings
```

8. **Confirm setup complete** and show a summary of configured profiles

9. **Offer to apply a profile now** if currently in a git repository
