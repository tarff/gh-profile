#!/bin/bash
# GitHub Profile Detection Hook
# Runs on SessionStart to detect git repo and config status

set -euo pipefail

# Exit silently if not in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo '{"continue": true, "suppressOutput": true}'
  exit 0
fi

# Check for profile configuration
CONFIG_FILE=""
if [ -f "$(pwd)/.claude/gh-profile.local.md" ]; then
  CONFIG_FILE="$(pwd)/.claude/gh-profile.local.md"
elif [ -f "$HOME/.claude/gh-profile.local.md" ]; then
  CONFIG_FILE="$HOME/.claude/gh-profile.local.md"
fi

# Output appropriate message
if [ -z "$CONFIG_FILE" ]; then
  echo '{"continue": true, "systemMessage": "gh-profile: Git repo detected but no profile config. Suggest /gh-profile:setup if needed."}'
else
  echo '{"continue": true, "systemMessage": "gh-profile: Git repo with config detected. Run /gh-profile:status to check profile."}'
fi

exit 0
