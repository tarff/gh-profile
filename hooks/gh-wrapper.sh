#!/bin/bash
# gh wrapper that automatically uses the correct GH_CONFIG_DIR based on current directory
# This script should be called instead of 'gh' directly

set -euo pipefail

# Determine profile based on current directory
determine_profile() {
  local current_dir="$1"
  local config_file=""

  # Check for config files
  if [ -f "$(pwd)/.claude/gh-profile.local.md" ]; then
    config_file="$(pwd)/.claude/gh-profile.local.md"
  elif [ -f "$HOME/.claude/gh-profile.local.md" ]; then
    config_file="$HOME/.claude/gh-profile.local.md"
  else
    echo ""
    return
  fi

  # Convert current dir to lowercase for matching
  local current_lower=$(echo "$current_dir" | tr '[:upper:]' '[:lower:]')

  # Extract personal paths and check
  local personal_paths=$(sed -n '/^  personal:/,/^  work:/p' "$config_file" | grep -E '^\s+- "' | sed 's/.*- "//;s/"$//' 2>/dev/null || true)
  while IFS= read -r path; do
    [ -z "$path" ] && continue
    local path_lower=$(echo "$path" | tr '[:upper:]' '[:lower:]')
    # Convert glob * to regex .*
    local pattern="${path_lower//\*/.*}"
    if echo "$current_lower" | grep -qE "^${pattern}$" 2>/dev/null; then
      echo "personal"
      return
    fi
  done <<< "$personal_paths"

  # Extract work paths and check
  local work_paths=$(sed -n '/^  work:/,/^default:/p' "$config_file" | grep -E '^\s+- "' | sed 's/.*- "//;s/"$//' 2>/dev/null || true)
  while IFS= read -r path; do
    [ -z "$path" ] && continue
    local path_lower=$(echo "$path" | tr '[:upper:]' '[:lower:]')
    local pattern="${path_lower//\*/.*}"
    if echo "$current_lower" | grep -qE "^${pattern}$" 2>/dev/null; then
      echo "work"
      return
    fi
  done <<< "$work_paths"

  # Fall back to default
  local default_profile=$(grep '^default:' "$config_file" | sed 's/default: //' | tr -d '[:space:]')
  echo "$default_profile"
}

# Get current directory in Windows format
RAW_PWD="$(pwd)"
if [[ "$RAW_PWD" =~ ^/([a-zA-Z])/ ]]; then
  DRIVE="${BASH_REMATCH[1]^^}"
  CURRENT_DIR="${DRIVE}:${RAW_PWD:2}"
else
  CURRENT_DIR="$RAW_PWD"
fi

# Determine which profile to use
PROFILE=$(determine_profile "$CURRENT_DIR")

if [ -n "$PROFILE" ]; then
  GH_CONFIG_DIR="$HOME/.claude/gh-configs/$PROFILE"
  # Convert to Windows path
  if [[ "$GH_CONFIG_DIR" =~ ^/([a-zA-Z])/ ]]; then
    DRIVE="${BASH_REMATCH[1]^^}"
    GH_CONFIG_DIR="${DRIVE}:${GH_CONFIG_DIR:2}"
  fi
  export GH_CONFIG_DIR
fi

# Run gh with all arguments
exec gh "$@"
