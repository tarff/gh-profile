#!/bin/bash
# GitHub Profile Auto-Switch Hook
# Runs on SessionStart to automatically configure git profile and gh auth based on directory

set -euo pipefail

#######################################
# UTILITY FUNCTIONS
#######################################

# Escape a string for safe JSON embedding
# Note: Backslash escaping in bash parameter expansion is unreliable across platforms.
# For git names/emails (our use case), backslashes are essentially never used.
# Quote escaping is the critical security measure and works reliably.
json_escape() {
  local str="$1"
  # Escape double quotes - the primary JSON injection vector
  str="${str//\"/\\\"}"
  printf '%s' "$str"
}

# Output JSON response and exit
output_json() {
  local continue_val="$1"
  local message="$2"
  local suppress="${3:-false}"

  # Escape message for JSON safety
  message=$(json_escape "$message")

  if [ "$suppress" = "true" ]; then
    echo "{\"continue\": $continue_val, \"suppressOutput\": true}"
  else
    echo "{\"continue\": $continue_val, \"systemMessage\": \"$message\"}"
  fi
}

# Escape all regex metacharacters in a string for safe use in grep -E
# This converts a glob pattern (with *) to a safe regex pattern
escape_for_regex() {
  local str="$1"
  # Define backslash as variable to avoid bash parsing issues with }}
  local bs='\\'
  # Escape all regex metacharacters: \ . [ ] ^ $ + ? { } | ( )
  # MUST escape backslash first
  str="${str//\\/${bs}${bs}}"
  str="${str//./${bs}.}"
  str="${str//\[/${bs}[}"
  str="${str//\]/${bs}]}"
  str="${str//^/${bs}^}"
  str="${str//\$/${bs}$}"
  str="${str//+/${bs}+}"
  str="${str//\?/${bs}?}"
  str="${str//\{/${bs}\{}"
  str="${str//\}/${bs}\}}"
  str="${str//|/${bs}|}"
  str="${str//(/${bs}(}"
  str="${str//)/${bs})}"
  # Convert glob * to regex .*
  str="${str//\*/.*}"
  printf '%s' "$str"
}

# Extract a field from a YAML section
# Usage: extract_field "section_start" "section_end" "field_name" "config_file"
extract_field() {
  local section_start="$1"
  local section_end="$2"
  local field="$3"
  local config_file="$4"

  local value
  value=$(sed -n "/^  ${section_start}:/,/^  ${section_end}/p" "$config_file" \
    | grep "${field}:" \
    | head -1 \
    | sed 's/.*'"${field}"': "//;s/"$//' 2>/dev/null) || true

  printf '%s' "$value"
}

# Extract paths array from a YAML section
# Returns paths separated by newlines (preserves spaces in paths)
extract_paths() {
  local section_start="$1"
  local section_end="$2"
  local config_file="$3"

  sed -n "/^  ${section_start}:/,/^  ${section_end}/p" "$config_file" \
    | grep -E '^\s+- "' \
    | sed 's/.*- "//;s/"$//' 2>/dev/null || true
}

#######################################
# MAIN SCRIPT
#######################################

# Exit silently if not in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  output_json "true" "" "true"
  exit 0
fi

# Find config file (project-local takes precedence over user-global)
CONFIG_FILE=""
PROJECT_CONFIG="$(pwd)/.claude/gh-profile.local.md"
USER_CONFIG="$HOME/.claude/gh-profile.local.md"

if [ -f "$PROJECT_CONFIG" ]; then
  CONFIG_FILE="$PROJECT_CONFIG"
elif [ -f "$USER_CONFIG" ]; then
  CONFIG_FILE="$USER_CONFIG"
fi

if [ -z "$CONFIG_FILE" ]; then
  output_json "true" "gh-profile: No profile config found. Run /gh-profile:setup to configure."
  exit 0
fi

# Validate config file is readable and has expected structure
if ! grep -q '^profiles:' "$CONFIG_FILE" 2>/dev/null; then
  output_json "true" "gh-profile: Invalid config file format. Run /gh-profile:setup to reconfigure."
  exit 0
fi

# Get current directory (normalize for Windows compatibility)
# Convert: /c/path -> C:/path (Git Bash to Windows format)
# Also normalize backslashes to forward slashes
CURRENT_DIR="$(pwd | sed 's|\\|/|g' | sed 's|^/\([a-zA-Z]\)/|\U\1:/|')"

# Initialize profile variables
MATCHED_PROFILE=""
PROFILE_NAME=""
PROFILE_EMAIL=""
PROFILE_GH_USER=""

# Check personal profile paths
# Use while-read loop to handle paths with spaces correctly
while IFS= read -r path_pattern || [ -n "$path_pattern" ]; do
  [ -z "$path_pattern" ] && continue
  # Escape regex metacharacters, then convert glob * to .*
  regex_pattern=$(escape_for_regex "$path_pattern")
  if printf '%s' "$CURRENT_DIR" | grep -qE "^${regex_pattern}$" 2>/dev/null; then
    MATCHED_PROFILE="personal"
    PROFILE_NAME=$(extract_field "personal" "work:" "name" "$CONFIG_FILE")
    PROFILE_EMAIL=$(extract_field "personal" "work:" "email" "$CONFIG_FILE")
    PROFILE_GH_USER=$(extract_field "personal" "work:" "gh_user" "$CONFIG_FILE")
    break
  fi
done <<< "$(extract_paths "personal" "work:" "$CONFIG_FILE")"

# Check work profile paths if no match yet
if [ -z "$MATCHED_PROFILE" ]; then
  while IFS= read -r path_pattern || [ -n "$path_pattern" ]; do
    [ -z "$path_pattern" ] && continue
    regex_pattern=$(escape_for_regex "$path_pattern")
    if printf '%s' "$CURRENT_DIR" | grep -qE "^${regex_pattern}$" 2>/dev/null; then
      MATCHED_PROFILE="work"
      PROFILE_NAME=$(extract_field "work" "default:" "name" "$CONFIG_FILE")
      PROFILE_EMAIL=$(extract_field "work" "default:" "email" "$CONFIG_FILE")
      PROFILE_GH_USER=$(extract_field "work" "default:" "gh_user" "$CONFIG_FILE")
      break
    fi
  done <<< "$(extract_paths "work" "default:" "$CONFIG_FILE")"
fi

# Use default profile if no path matched
if [ -z "$MATCHED_PROFILE" ]; then
  MATCHED_PROFILE=$(grep '^default:' "$CONFIG_FILE" | sed 's/default: //' | tr -d '[:space:]')

  if [ "$MATCHED_PROFILE" = "personal" ]; then
    PROFILE_NAME=$(extract_field "personal" "work:" "name" "$CONFIG_FILE")
    PROFILE_EMAIL=$(extract_field "personal" "work:" "email" "$CONFIG_FILE")
    PROFILE_GH_USER=$(extract_field "personal" "work:" "gh_user" "$CONFIG_FILE")
  elif [ "$MATCHED_PROFILE" = "work" ]; then
    PROFILE_NAME=$(extract_field "work" "default:" "name" "$CONFIG_FILE")
    PROFILE_EMAIL=$(extract_field "work" "default:" "email" "$CONFIG_FILE")
    PROFILE_GH_USER=$(extract_field "work" "default:" "gh_user" "$CONFIG_FILE")
  else
    output_json "true" "gh-profile: Invalid default profile. Expected 'personal' or 'work'."
    exit 0
  fi
fi

# Validate extracted values
if [ -z "$PROFILE_NAME" ] || [ -z "$PROFILE_EMAIL" ]; then
  output_json "true" "gh-profile: Profile is missing required fields (name/email). Run /gh-profile:setup."
  exit 0
fi

# Validate email format (basic check - contains @)
if [[ ! "$PROFILE_EMAIL" =~ @ ]]; then
  output_json "true" "gh-profile: Invalid email format. Run /gh-profile:setup."
  exit 0
fi

# Get current git config
CURRENT_NAME=$(git config user.name 2>/dev/null || echo "")
CURRENT_EMAIL=$(git config user.email 2>/dev/null || echo "")

# Track what we changed
GIT_SWITCHED=false
GH_SWITCHED=false
GH_STATUS=""

# Check if git config switch is needed
if [ "$CURRENT_NAME" != "$PROFILE_NAME" ] || [ "$CURRENT_EMAIL" != "$PROFILE_EMAIL" ]; then
  # Apply git config (values are properly quoted to prevent shell expansion)
  git config user.name "$PROFILE_NAME"
  git config user.email "$PROFILE_EMAIL"
  GIT_SWITCHED=true
fi

# Check if gh CLI is installed and handle gh auth switch
if command -v gh &> /dev/null; then
  # Get current active gh account (portable grep without -P flag)
  CURRENT_GH_USER=$(gh auth status 2>&1 | grep "Logged in to" | sed 's/.*account \([^ ]*\).*/\1/' | head -1 || echo "")

  # If profile has gh_user configured and it's different from current
  if [ -n "$PROFILE_GH_USER" ] && [ "$CURRENT_GH_USER" != "$PROFILE_GH_USER" ]; then
    # Try to switch gh auth
    if gh auth switch --user "$PROFILE_GH_USER" 2>/dev/null; then
      GH_SWITCHED=true
      GH_STATUS="switched to $PROFILE_GH_USER"
    else
      # Switch failed - user may not have this account logged in
      GH_STATUS="could not switch to $PROFILE_GH_USER (run: gh auth login)"
    fi
  elif [ -n "$PROFILE_GH_USER" ]; then
    GH_STATUS="using $PROFILE_GH_USER"
  else
    GH_STATUS="gh_user not configured"
  fi
else
  GH_STATUS="gh CLI not installed"
fi

# Build status message
MESSAGE=""
if [ "$GIT_SWITCHED" = true ] && [ "$GH_SWITCHED" = true ]; then
  MESSAGE="gh-profile: Auto-switched to $MATCHED_PROFILE profile - Git: $PROFILE_NAME <$PROFILE_EMAIL>, gh: $GH_STATUS"
elif [ "$GIT_SWITCHED" = true ]; then
  MESSAGE="gh-profile: Auto-switched git config to $MATCHED_PROFILE profile ($PROFILE_NAME <$PROFILE_EMAIL>), gh: $GH_STATUS"
elif [ "$GH_SWITCHED" = true ]; then
  MESSAGE="gh-profile: Using $MATCHED_PROFILE profile, gh auth $GH_STATUS"
else
  MESSAGE="gh-profile: Using $MATCHED_PROFILE profile ($PROFILE_EMAIL), gh: $GH_STATUS"
fi

output_json "true" "$MESSAGE"
exit 0
