---
name: switch
description: Switch to a different GitHub profile (personal or work)
argument-hint: "<profile>"
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

# Switch GitHub Profile

Switch the current repository to use a specific GitHub profile.

**Arguments**: `$ARGUMENTS` contains the profile name (personal or work)

## Steps

1. **Read profile settings** from `.claude/gh-profile.local.md` (check project directory first, then user home `~/.claude/gh-profile.local.md`)

2. **Parse the YAML frontmatter** to get profile configurations

3. **If no argument provided or invalid profile**:
   - Use AskUserQuestion to ask which profile to switch to
   - Options: personal, work

4. **Apply the selected profile's git configuration**:
   ```bash
   git config user.name "[profile name]"
   git config user.email "[profile email]"
   ```
   - If profile has a signing_key: `git config user.signingkey "[key]"`
   - If profile has NO signing_key: `git config --unset user.signingkey` (ignore error if not set)

5. **If the profile has a different GitHub account**, inform the user they may need to re-authenticate:
   - For HTTPS: `git config credential.helper` may need updating
   - For SSH: Different SSH keys may be needed

6. **Confirm the switch**:
   ```
   Switched to [profile] profile
   - Name: [name]
   - Email: [email]
   - Signing Key: [key]
   ```

7. **If no profile configuration exists**, tell the user to run `/gh-profile:setup` first
