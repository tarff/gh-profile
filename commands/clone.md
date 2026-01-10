---
name: clone
description: Clone a GitHub repository using the appropriate profile
argument-hint: "<repo-url> [profile]"
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

# Clone with Profile

Clone a GitHub repository and configure it with the specified profile.

**Arguments**: `$ARGUMENTS` contains:
- Repository URL (required) - full URL or `owner/repo` shorthand
- Profile name (optional) - `personal` or `work`

## Steps

1. **Parse arguments** to extract repo URL and optional profile name

2. **Read profile settings** from `.claude/gh-profile.local.md` (check current directory, then `~/.claude/gh-profile.local.md`)

3. **Determine which profile to use**:
   - If profile specified in arguments, use that
   - Otherwise, use AskUserQuestion to ask: "Which profile for this repo?" (personal / work)

4. **Normalize the repo URL**:
   - If `owner/repo` format, expand to `https://github.com/owner/repo.git`

5. **Clone the repository**:
   ```bash
   git clone [repo-url]
   ```

6. **Extract repo name** from URL (last path segment without .git)

7. **Apply profile settings** to the cloned repo:
   ```bash
   cd [repo-name]
   git config user.name "[profile name]"
   git config user.email "[profile email]"
   ```
   - If profile has a signing_key: `git config user.signingkey "[key]"`
   - If profile has NO signing_key: `git config --unset user.signingkey 2>/dev/null || true`

8. **Confirm success**:
   ```
   Cloned [repo] with [profile] profile
   - Location: [full path]
   - Name: [name]
   - Email: [email]
   - Signing Key: [key]
   ```

9. If no profile configuration exists, tell the user to run `/gh-profile:setup` first
