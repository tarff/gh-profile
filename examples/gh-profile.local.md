---
profiles:
  personal:
    name: "Your Name"
    email: "your.personal@email.com"
    signing_key: "ABCD1234EFGH5678"
    paths:
      - "C:\\Personal\\*"
      - "C:\\Users\\YourName\\personal-projects\\*"
      - "D:\\hobby-projects\\*"
  work:
    name: "Your Name"
    email: "your.name@company.com"
    signing_key: "WXYZ9876STUV5432"
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
- **signing_key**: Your GPG key ID for signing commits (optional)
- **paths**: Array of path patterns that should use this profile (supports * wildcard)

## Path Patterns

Use `*` as a wildcard:
- `C:\\Work\\*` matches `C:\Work\project1`, `C:\Work\project2`, etc.
- `C:\\Users\\YourName\\repos\\client-*` matches client-specific folders

## Commands

- `/gh-profile:status` - See current profile and git config
- `/gh-profile:switch personal` - Switch to personal profile
- `/gh-profile:switch work` - Switch to work profile
- `/gh-profile:clone owner/repo` - Clone with correct profile
- `/gh-profile:setup` - Run setup wizard
