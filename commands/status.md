---
name: status
description: Show current GitHub profile and git configuration
allowed-tools:
  - Bash
  - Read
---

# GitHub Profile Status

Show the user their current GitHub profile status.

## Steps

1. **Get current git config** (run as single command):
   ```bash
   echo "NAME=$(git config user.name 2>/dev/null || echo '')" && \
   echo "EMAIL=$(git config user.email 2>/dev/null || echo '')" && \
   echo "SIGNINGKEY=$(git config user.signingkey 2>/dev/null || echo '')" && \
   echo "REMOTE=$(git config remote.origin.url 2>/dev/null || echo '')" && \
   echo "PWD=$(pwd)"
   ```

2. **Read profile settings** from `.claude/gh-profile.local.md` (check project directory first, then `~/.claude/gh-profile.local.md`)

3. **Parse the YAML frontmatter** to get both profiles with their paths

4. **Match current directory** against profile path patterns:
   - Compare current `pwd` against each profile's `paths` array
   - Use glob matching (e.g., `C:\Work\*` matches `C:\Work\project1`)

5. **Display results**:
   ```
   GitHub Profile Status
   =====================
   Current Directory: [pwd]

   Git Config:
   - Name: [user.name]
   - Email: [user.email]
   - Signing Key: [key or "not set"]
   - Remote: [origin URL or "no remote"]

   Profile Match: [personal/work/none]
   Expected Config: [if matched, show expected name/email]
   Status: [✓ Config matches / ⚠ Config mismatch - run /gh-profile:switch]
   ```

6. If no config file found, suggest `/gh-profile:setup`
