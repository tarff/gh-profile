#!/bin/bash
# GitHub Profile Auto-Switch Hook
# Runs on SessionStart to automatically configure git profile based on directory

set -euo pipefail

# Exit silently if not in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo '{"continue": true, "suppressOutput": true}'
  exit 0
fi

# Find config file
CONFIG_FILE=""
if [ -f "$(pwd)/.claude/gh-profile.local.md" ]; then
  CONFIG_FILE="$(pwd)/.claude/gh-profile.local.md"
elif [ -f "$HOME/.claude/gh-profile.local.md" ]; then
  CONFIG_FILE="$HOME/.claude/gh-profile.local.md"
fi

if [ -z "$CONFIG_FILE" ]; then
  echo '{"continue": true, "systemMessage": "gh-profile: No profile config found. Run /gh-profile:setup to configure."}'
  exit 0
fi

# Get current directory (normalize path separators for Windows compatibility)
CURRENT_DIR="$(pwd | sed 's|\\|/|g')"

# Parse YAML and match paths to determine profile
# Extract profiles section and find matching profile based on paths
MATCHED_PROFILE=""
PROFILE_NAME=""
PROFILE_EMAIL=""

# Check personal profile paths
PERSONAL_PATHS=$(sed -n '/^  personal:/,/^  work:/p' "$CONFIG_FILE" | grep -E '^\s+- "' | sed 's/.*- "//;s/"$//')
for path_pattern in $PERSONAL_PATHS; do
  # Convert glob pattern to regex (replace * with .*)
  regex_pattern=$(echo "$path_pattern" | sed 's|\*|.*|g')
  if echo "$CURRENT_DIR" | grep -qE "^${regex_pattern}$"; then
    MATCHED_PROFILE="personal"
    PROFILE_NAME=$(sed -n '/^  personal:/,/^  work:/p' "$CONFIG_FILE" | grep 'name:' | head -1 | sed 's/.*name: "//;s/"$//')
    PROFILE_EMAIL=$(sed -n '/^  personal:/,/^  work:/p' "$CONFIG_FILE" | grep 'email:' | head -1 | sed 's/.*email: "//;s/"$//')
    break
  fi
done

# Check work profile paths if no match yet
if [ -z "$MATCHED_PROFILE" ]; then
  WORK_PATHS=$(sed -n '/^  work:/,/^default:/p' "$CONFIG_FILE" | grep -E '^\s+- "' | sed 's/.*- "//;s/"$//')
  for path_pattern in $WORK_PATHS; do
    regex_pattern=$(echo "$path_pattern" | sed 's|\*|.*|g')
    if echo "$CURRENT_DIR" | grep -qE "^${regex_pattern}$"; then
      MATCHED_PROFILE="work"
      PROFILE_NAME=$(sed -n '/^  work:/,/^default:/p' "$CONFIG_FILE" | grep 'name:' | head -1 | sed 's/.*name: "//;s/"$//')
      PROFILE_EMAIL=$(sed -n '/^  work:/,/^default:/p' "$CONFIG_FILE" | grep 'email:' | head -1 | sed 's/.*email: "//;s/"$//')
      break
    fi
  done
fi

# Use default profile if no path matched
if [ -z "$MATCHED_PROFILE" ]; then
  MATCHED_PROFILE=$(grep '^default:' "$CONFIG_FILE" | sed 's/default: //')
  if [ "$MATCHED_PROFILE" = "personal" ]; then
    PROFILE_NAME=$(sed -n '/^  personal:/,/^  work:/p' "$CONFIG_FILE" | grep 'name:' | head -1 | sed 's/.*name: "//;s/"$//')
    PROFILE_EMAIL=$(sed -n '/^  personal:/,/^  work:/p' "$CONFIG_FILE" | grep 'email:' | head -1 | sed 's/.*email: "//;s/"$//')
  else
    PROFILE_NAME=$(sed -n '/^  work:/,/^default:/p' "$CONFIG_FILE" | grep 'name:' | head -1 | sed 's/.*name: "//;s/"$//')
    PROFILE_EMAIL=$(sed -n '/^  work:/,/^default:/p' "$CONFIG_FILE" | grep 'email:' | head -1 | sed 's/.*email: "//;s/"$//')
  fi
fi

# Get current git config
CURRENT_NAME=$(git config user.name 2>/dev/null || echo "")
CURRENT_EMAIL=$(git config user.email 2>/dev/null || echo "")

# Check if switch is needed
if [ "$CURRENT_NAME" = "$PROFILE_NAME" ] && [ "$CURRENT_EMAIL" = "$PROFILE_EMAIL" ]; then
  echo "{\"continue\": true, \"systemMessage\": \"gh-profile: Using $MATCHED_PROFILE profile ($PROFILE_EMAIL)\"}"
  exit 0
fi

# Apply the profile
git config user.name "$PROFILE_NAME"
git config user.email "$PROFILE_EMAIL"

echo "{\"continue\": true, \"systemMessage\": \"gh-profile: Auto-switched to $MATCHED_PROFILE profile ($PROFILE_NAME <$PROFILE_EMAIL>)\"}"
exit 0
