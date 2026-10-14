---
description: Switch to a different GitHub profile (personal or work)
argument-hint: "<profile>"
allowed-tools: Bash, Read, AskUserQuestion
---

# Switch GitHub Profile

Switch the current repository to use a specific GitHub profile, including both git config and gh CLI authentication.

**Arguments**: `$ARGUMENTS` contains the profile name (personal or work)

## Steps

### Phase 1: Load Configuration

1. **Read profile settings** from `.claude/gh-profile.local.md` (check project directory first, then user home `~/.claude/gh-profile.local.md`)

2. **Parse the YAML frontmatter** to get profile configurations including:
   - `name`, `email`, `signing_key` (git config)
   - `gh_user` (GitHub CLI account)

3. **If no profile configuration exists**, tell the user to run `/gh-profile:setup` first and stop.

### Phase 2: Select Profile

4. **If no argument provided or invalid profile**:
   - Use AskUserQuestion to ask which profile to switch to
   - Options: personal, work

### Phase 3: Apply Git Configuration

5. **Apply the selected profile's git configuration**:
   ```bash
   git config user.name "[profile name]"
   git config user.email "[profile email]"
   ```
   - **IMPORTANT**: Always use double quotes around values to prevent shell injection
   - If profile has a signing_key: `git config user.signingkey "[key]"`
   - If profile has NO signing_key: `git config --unset user.signingkey 2>/dev/null || true`

### Phase 4: Point gh CLI at the Profile's Config

Each profile has its own isolated gh config folder at `~/.claude/gh-configs/[profile]` (created by the SessionStart hook). Switching profiles means using that folder, not `gh auth switch`.

6. **Check if gh CLI is installed**:
   ```bash
   gh --version 2>/dev/null || echo "NOT_INSTALLED"
   ```

7. **If gh is installed**, check the profile's gh login:
   ```bash
   GH_CONFIG_DIR="$HOME/.claude/gh-configs/[profile]" command gh auth status 2>&1
   ```

   Handle the result:
   - **Logged in**: Note the account. If `gh_user` is set and differs from the logged-in account, warn about the mismatch
   - **Not logged in**: Warn the user to log in to that profile's folder (see Phase 5)
   - **Other error**: Warn but don't fail the operation

8. **If gh is NOT installed**: Skip gh checks silently (git config is still applied)

9. **For the rest of this session**, run every gh command with the profile's folder:
   ```bash
   GH_CONFIG_DIR="$HOME/.claude/gh-configs/[profile]" command gh <command>
   ```
   This overrides the GH_CONFIG_DIR set at session start. A new session will auto-detect from the folder again.
   `command gh` skips any shell function or alias named `gh` that would pick the profile from the folder instead.

### Phase 5: Confirmation

10. **Display results**:
    ```
    Switched to [profile] profile
    =============================

    Git Config:
    ✓ Name: [name]
    ✓ Email: [email]
    ✓ Signing Key: [key or "not set"]

    GitHub CLI:
    ✓ Account: [logged-in account]
    ✓ Config: ~/.claude/gh-configs/[profile]
    ```

    Or if gh auth had issues:
    ```
    Switched to [profile] profile
    =============================

    Git Config:
    ✓ Name: [name]
    ✓ Email: [email]
    ✓ Signing Key: [key or "not set"]

    GitHub CLI:
    ⚠ Not logged in for [profile]: [reason]
      Run: GH_CONFIG_DIR="$HOME/.claude/gh-configs/[profile]" command gh auth login
    ```

11. **Verify the switch worked** by running:
    ```bash
    echo "GIT_NAME=$(git config user.name)" && echo "GIT_EMAIL=$(git config user.email)" && GH_CONFIG_DIR="$HOME/.claude/gh-configs/[profile]" command gh auth status 2>&1 | head -3
    ```
