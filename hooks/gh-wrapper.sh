#!/bin/bash
# gh wrapper that automatically uses the correct GH_CONFIG_DIR based on current directory
# This script should be called instead of 'gh' directly

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/profile-lib.sh"

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

  local profile
  profile=$(match_profile "$current_dir" "$config_file")

  # Fall back to default
  if [ -z "$profile" ]; then
    profile=$(default_profile "$config_file")
  fi
  echo "$profile"
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
