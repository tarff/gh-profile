---
name: status
description: Show current GitHub profile and git configuration
allowed-tools:
  - Bash
  - Read
---

# GitHub Profile Status

Show the user their current GitHub profile status including both git config and gh CLI authentication.

## Steps

1. **Get current git config and gh auth status** (run as single command):
   ```bash
   echo "=== GIT CONFIG ===" && \
   echo "NAME=$(git config user.name 2>/dev/null || echo '')" && \
   echo "EMAIL=$(git config user.email 2>/dev/null || echo '')" && \
   echo "SIGNINGKEY=$(git config user.signingkey 2>/dev/null || echo '')" && \
   echo "REMOTE=$(git config remote.origin.url 2>/dev/null || echo '')" && \
   echo "PWD=$(pwd)" && \
   echo "=== GH AUTH ===" && \
   (gh auth status 2>&1 || echo "GH_NOT_INSTALLED")
   ```

2. **Read profile settings** from `.claude/gh-profile.local.md` (check project directory first, then `~/.claude/gh-profile.local.md`)

3. **Parse the YAML frontmatter** to get both profiles with their:
   - `name`, `email`, `signing_key` (git config)
   - `gh_user` (GitHub CLI account)
   - `paths` (directory patterns)

4. **Match current directory** against profile path patterns:
   - Compare current `pwd` against each profile's `paths` array
   - Use glob matching (e.g., `C:\Work\*` matches `C:\Work\project1`)

5. **Parse gh auth status** to determine:
   - Active GitHub account username
   - Whether gh CLI is installed
   - List of all logged-in accounts

6. **Display results**:
   ```
   GitHub Profile Status
   =====================
   Current Directory: [pwd]

   Git Config:
   - Name: [user.name]
   - Email: [user.email]
   - Signing Key: [key or "not set"]
   - Remote: [origin URL or "no remote"]

   GitHub CLI:
   - Active Account: [gh username]
   - Logged-in Accounts: [list all]

   Profile Match: [personal/work/none]
   Expected Git Config: [name] <[email]>
   Expected gh Account: [gh_user]

   Status:
   - Git Config: [✓ matches / ⚠ mismatch]
   - gh Auth: [✓ matches / ⚠ mismatch / ⚠ not configured]
   ```

   If there's a mismatch:
   ```
   ⚠ Config mismatch detected!
   Run: /gh-profile:switch [profile]
   ```

7. **If gh CLI is not installed**:
   ```
   GitHub CLI:
   - Status: Not installed
   - Install from: https://cli.github.com/
   ```

8. **If no config file found**, suggest `/gh-profile:setup`

9. **If profile doesn't have gh_user configured**:
   ```
   GitHub CLI:
   ⚠ gh_user not configured for this profile
   Run: /gh-profile:setup to add gh usernames
   ```
