---
description: Clone a GitHub repository using the appropriate profile
argument-hint: "<repo-url> [profile]"
allowed-tools: Bash, Read, AskUserQuestion
---

# Clone with Profile

Clone a GitHub repository and configure it with the specified profile, including both git config and gh CLI authentication.

**Arguments**: `$ARGUMENTS` contains:
- Repository URL (required) - full URL or `owner/repo` shorthand
- Profile name (optional) - `personal` or `work`

## Steps

### Phase 1: Setup

1. **Parse arguments** to extract repo URL and optional profile name

2. **Read profile settings** from `.claude/gh-profile.local.md` (check current directory, then `~/.claude/gh-profile.local.md`)

3. **If no profile configuration exists**, tell the user to run `/gh-profile:setup` first and stop.

4. **Determine which profile to use**:
   - If profile specified in arguments, use that
   - Otherwise, use AskUserQuestion to ask: "Which profile for this repo?" (personal / work)

### Phase 2: Switch gh auth (before cloning)

5. **Check if gh CLI is installed**:
   ```bash
   gh --version 2>/dev/null || echo "NOT_INSTALLED"
   ```

6. **If gh is installed AND profile has gh_user set**, switch to the correct account first:
   ```bash
   gh auth switch --user "[gh_user]" 2>&1
   ```
   - This ensures `gh repo clone` uses the correct authentication
   - If switch fails, warn but continue (user can authenticate manually)

### Phase 3: Clone

7. **Validate and normalize the repo URL**:
   - **Security check**: Verify URL matches expected patterns:
     - `owner/repo` format (alphanumeric, hyphens, underscores only)
     - `https://github.com/owner/repo` or `https://github.com/owner/repo.git`
     - `git@github.com:owner/repo.git`
   - Reject URLs with suspicious characters (`;`, `|`, `$`, backticks, etc.)
   - If `owner/repo` format, can use `gh repo clone owner/repo` if gh is available
   - Otherwise expand to `https://github.com/owner/repo.git`

8. **Clone the repository**:
   - **IMPORTANT**: Always quote the URL to prevent shell injection
   - If gh is installed: `gh repo clone "[owner/repo]"` (uses current gh auth)
   - Otherwise: `git clone "[repo-url]"`

9. **Extract repo name** from URL (last path segment without .git)

### Phase 4: Configure Cloned Repo

10. **Apply profile settings** to the cloned repo:
    ```bash
    cd [repo-name]
    git config user.name "[profile name]"
    git config user.email "[profile email]"
    ```
    - If profile has a signing_key: `git config user.signingkey "[key]"`
    - If profile has NO signing_key: `git config --unset user.signingkey 2>/dev/null || true`

### Phase 5: Confirmation

11. **Confirm success**:
    ```
    Cloned [repo] with [profile] profile
    =====================================
    Location: [full path]

    Git Config:
    - Name: [name]
    - Email: [email]
    - Signing Key: [key or "not set"]

    GitHub CLI:
    - Active Account: [gh_user or "not configured"]
    ```
