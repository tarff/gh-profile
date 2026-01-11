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

### Phase 4: Apply gh CLI Authentication

6. **Check if gh CLI is installed**:
   ```bash
   gh --version 2>/dev/null || echo "NOT_INSTALLED"
   ```

7. **If gh is installed AND profile has gh_user set**:
   ```bash
   gh auth switch --user "[gh_user]" 2>&1
   ```

   Handle the result:
   - **Success**: Note that gh auth was switched
   - **"account not found" error**: Warn user they need to run `gh auth login` for this account
   - **"only one account" message**: This is fine, user only has one gh account logged in
   - **Other error**: Warn but don't fail the operation

8. **If gh is NOT installed**: Skip gh auth switch silently (git config is still applied)

9. **If profile has NO gh_user set**: Skip gh auth switch, note that gh_user is not configured

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
    ✓ Active account: [gh_user]
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
    ⚠ Could not switch to [gh_user]: [reason]
      Run: gh auth login
      Then: gh auth switch --user [gh_user]
    ```

11. **Verify the switch worked** by running:
    ```bash
    echo "GIT_NAME=$(git config user.name)" && echo "GIT_EMAIL=$(git config user.email)" && gh auth status 2>&1 | head -3
    ```
