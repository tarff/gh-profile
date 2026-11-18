#!/bin/bash
# GitHub Profile Auto-Switch Hook
# Uses per-profile GH_CONFIG_DIR for true multi-terminal support

set -euo pipefail

json_escape() {
  local str="$1"
  local bs='\'
  str="${str//"$bs"/"$bs$bs"}"
  str="${str//\"/\\\"}"
  printf '%s' "$str"
}

output_json_with_env() {
  local continue_val="$1"
  local message="$2"
  local gh_config_dir="${3:-}"
  # Persist for later Bash tool calls (hook JSON has no env field)
  if [ -n "$gh_config_dir" ] && [ -n "${CLAUDE_ENV_FILE:-}" ]; then
    printf 'export GH_CONFIG_DIR=%q\n' "$gh_config_dir" >> "$CLAUDE_ENV_FILE"
  fi
  message=$(json_escape "$message")
  # systemMessage is shown to the user; additionalContext reaches Claude
  echo "{\"continue\": $continue_val, \"systemMessage\": \"$message\", \"hookSpecificOutput\": {\"hookEventName\": \"SessionStart\", \"additionalContext\": \"$message\"}}"
}

output_json() {
  local continue_val="$1"
  local message="$2"
  local suppress="${3:-false}"
  message=$(json_escape "$message")
  if [ "$suppress" = "true" ]; then
    echo "{\"continue\": $continue_val, \"suppressOutput\": true}"
  else
    echo "{\"continue\": $continue_val, \"systemMessage\": \"$message\"}"
  fi
}

source "$(dirname "${BASH_SOURCE[0]}")/profile-lib.sh"

# Exit silently if not in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  output_json "true" "" "true"
  exit 0
fi

# Find config file
CONFIG_FILE=""
PROJECT_CONFIG="$(pwd)/.claude/gh-profile.local.md"
USER_CONFIG="$HOME/.claude/gh-profile.local.md"

if [ -f "$PROJECT_CONFIG" ]; then
  CONFIG_FILE="$PROJECT_CONFIG"
elif [ -f "$USER_CONFIG" ]; then
  CONFIG_FILE="$USER_CONFIG"
fi

if [ -z "$CONFIG_FILE" ]; then
  output_json "true" "gh-profile: No config found. Run /gh-profile:setup"
  exit 0
fi

if ! grep -q '^profiles:' "$CONFIG_FILE" 2>/dev/null; then
  output_json "true" "gh-profile: Invalid config format"
  exit 0
fi

# Convert Git Bash path /c/foo to C:/foo format
RAW_PWD="$(pwd)"
if [[ "$RAW_PWD" =~ ^/([a-zA-Z])/ ]]; then
  DRIVE_LETTER="${BASH_REMATCH[1]}"
  DRIVE_LETTER="${DRIVE_LETTER^^}"  # uppercase
  CURRENT_DIR="${DRIVE_LETTER}:${RAW_PWD:2}"
else
  CURRENT_DIR="$RAW_PWD"
fi

MATCHED_PROFILE=$(match_profile "$CURRENT_DIR" "$CONFIG_FILE")

# Use default profile if no path matched
if [ -z "$MATCHED_PROFILE" ]; then
  MATCHED_PROFILE=$(default_profile "$CONFIG_FILE")
  if [ "$MATCHED_PROFILE" != "personal" ] && [ "$MATCHED_PROFILE" != "work" ]; then
    output_json "true" "gh-profile: Invalid default profile"
    exit 0
  fi
fi

SECTION_END=$(section_end "$MATCHED_PROFILE")
PROFILE_NAME=$(extract_field "$MATCHED_PROFILE" "$SECTION_END" "name" "$CONFIG_FILE")
PROFILE_EMAIL=$(extract_field "$MATCHED_PROFILE" "$SECTION_END" "email" "$CONFIG_FILE")
PROFILE_GH_USER=$(extract_field "$MATCHED_PROFILE" "$SECTION_END" "gh_user" "$CONFIG_FILE")
PROFILE_SIGNING_KEY=$(extract_field "$MATCHED_PROFILE" "$SECTION_END" "signing_key" "$CONFIG_FILE")

if [ -z "$PROFILE_NAME" ] || [ -z "$PROFILE_EMAIL" ]; then
  output_json "true" "gh-profile: Missing name/email in config"
  exit 0
fi

# Apply git config
CURRENT_NAME=$(git config user.name 2>/dev/null || echo "")
CURRENT_EMAIL=$(git config user.email 2>/dev/null || echo "")
GIT_SWITCHED=false

if [ "$CURRENT_NAME" != "$PROFILE_NAME" ] || [ "$CURRENT_EMAIL" != "$PROFILE_EMAIL" ]; then
  git config user.name "$PROFILE_NAME"
  git config user.email "$PROFILE_EMAIL"
  GIT_SWITCHED=true
fi

if [ -n "$PROFILE_SIGNING_KEY" ]; then
  CURRENT_KEY=$(git config user.signingkey 2>/dev/null || echo "")
  CURRENT_SIGN=$(git config --bool commit.gpgsign 2>/dev/null || echo "false")
  if [ "$CURRENT_KEY" != "$PROFILE_SIGNING_KEY" ] || [ "$CURRENT_SIGN" != "true" ]; then
    git config user.signingkey "$PROFILE_SIGNING_KEY"
    git config commit.gpgsign true
    git config gh-profile.signing true  # label: this hook set the signing settings
    GIT_SWITCHED=true
  fi
else
  # Remove signing settings only if this hook set them; leave the user's own alone
  if [ "$(git config --local --bool gh-profile.signing 2>/dev/null || true)" = "true" ]; then
    git config --local --unset user.signingkey || true
    if [ "$(git config --local --bool commit.gpgsign 2>/dev/null || true)" = "true" ]; then
      git config --local --unset commit.gpgsign  # keep an explicit false
    fi
    git config --local --unset gh-profile.signing
    GIT_SWITCHED=true
  fi
fi

# Warn if commits will still be signed with a key that isn't this profile's
SIGN_WARNING=""
if [ -z "$PROFILE_SIGNING_KEY" ] && [ "$(git config --bool commit.gpgsign 2>/dev/null || true)" = "true" ]; then
  SIGN_KEY=$(git config user.signingkey 2>/dev/null || true)
  SIGN_WARNING=" WARNING: this profile has no signing key, but commits here will be signed with ${SIGN_KEY:+key $SIGN_KEY}${SIGN_KEY:-your default key}. To stop: git config commit.gpgsign false"
fi

# Set up per-profile GH_CONFIG_DIR
GH_CONFIG_DIR="$HOME/.claude/gh-configs/$MATCHED_PROFILE"
mkdir -p "$GH_CONFIG_DIR"

# Convert to Windows path format for Claude Code (C:/Users/... instead of /c/Users/...)
if [[ "$GH_CONFIG_DIR" =~ ^/([a-zA-Z])/ ]]; then
  DRIVE="${BASH_REMATCH[1]}"
  DRIVE="${DRIVE^^}"
  GH_CONFIG_DIR_WIN="${DRIVE}:${GH_CONFIG_DIR:2}"
else
  GH_CONFIG_DIR_WIN="$GH_CONFIG_DIR"
fi
GH_STATUS=""

if command -v gh &> /dev/null; then
  if [ -f "$GH_CONFIG_DIR/hosts.yml" ]; then
    GH_USER=$(grep -A5 "github.com:" "$GH_CONFIG_DIR/hosts.yml" 2>/dev/null | grep "user:" | sed 's/.*user: //' | head -1 || echo "")
    if [ -n "$GH_USER" ]; then
      GH_STATUS="isolated ($GH_USER)"
    else
      GH_STATUS="config exists, no user"
    fi
  else
    GH_STATUS=$(printf 'need auth: GH_CONFIG_DIR=%q gh auth login' "$GH_CONFIG_DIR")
  fi
else
  GH_STATUS="gh not installed"
fi

GH_INSTRUCTION=$(printf 'CRITICAL: For ALL gh CLI commands, you MUST use: GH_CONFIG_DIR=%q gh <command>' "$GH_CONFIG_DIR_WIN")
if [ "$GIT_SWITCHED" = true ]; then
  MESSAGE="gh-profile: Switched to $MATCHED_PROFILE ($PROFILE_EMAIL), gh: $GH_STATUS. $GH_INSTRUCTION$SIGN_WARNING"
else
  MESSAGE="gh-profile: Using $MATCHED_PROFILE ($PROFILE_EMAIL), gh: $GH_STATUS. $GH_INSTRUCTION$SIGN_WARNING"
fi

output_json_with_env "true" "$MESSAGE" "$GH_CONFIG_DIR_WIN"
exit 0
