#!/bin/bash
# GitHub Profile Auto-Switch Hook
# Uses per-profile GH_CONFIG_DIR for true multi-terminal support

set -euo pipefail

json_escape() {
  local str="$1"
  str="${str//\/\\}"
  str="${str//\"/\\\"}"
  printf '%s' "$str"
}

output_json_with_env() {
  local continue_val="$1"
  local message="$2"
  local gh_config_dir="${3:-}"
  message=$(json_escape "$message")
  gh_config_dir=$(json_escape "$gh_config_dir")
  if [ -n "$gh_config_dir" ]; then
    echo "{\"continue\": $continue_val, \"systemMessage\": \"$message\", \"env\": {\"GH_CONFIG_DIR\": \"$gh_config_dir\"}}"
  else
    echo "{\"continue\": $continue_val, \"systemMessage\": \"$message\"}"
  fi
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

escape_for_regex() {
  local str="$1"
  local bs='\'
  str="${str//\/${bs}${bs}}"
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
  str="${str//\*/.*}"
  printf '%s' "$str"
}

extract_field() {
  local section_start="$1"
  local section_end="$2"
  local field="$3"
  local config_file="$4"
  local value
  value=$(sed -n "/^  ${section_start}:/,/^  ${section_end}/p" "$config_file" \
    | grep "${field}:" | head -1 \
    | sed "s/.*${field}: \"//;s/\"$//" 2>/dev/null) || true
  printf '%s' "$value"
}

extract_paths() {
  local section_start="$1"
  local section_end="$2"
  local config_file="$3"
  sed -n "/^  ${section_start}:/,/^  ${section_end}/p" "$config_file" \
    | grep -E '^\s+- "' | sed 's/.*- "//;s/"$//' 2>/dev/null || true
}

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
CURRENT_DIR_LOWER=$(echo "$CURRENT_DIR" | tr '[:upper:]' '[:lower:]')

MATCHED_PROFILE=""
PROFILE_NAME=""
PROFILE_EMAIL=""
PROFILE_GH_USER=""
PROFILE_SIGNING_KEY=""

# Check personal profile paths
while IFS= read -r path_pattern || [ -n "$path_pattern" ]; do
  [ -z "$path_pattern" ] && continue
  # Normalize path: convert backslashes to forward slashes and lowercase
  path_pattern_lower="${path_pattern//\\//}"
  path_pattern_lower=$(echo "$path_pattern_lower" | tr '[:upper:]' '[:lower:]')
  regex_pattern=$(escape_for_regex "$path_pattern_lower")
  if printf '%s' "$CURRENT_DIR_LOWER" | grep -qE "^${regex_pattern}$" 2>/dev/null; then
    MATCHED_PROFILE="personal"
    PROFILE_NAME=$(extract_field "personal" "work:" "name" "$CONFIG_FILE")
    PROFILE_EMAIL=$(extract_field "personal" "work:" "email" "$CONFIG_FILE")
    PROFILE_GH_USER=$(extract_field "personal" "work:" "gh_user" "$CONFIG_FILE")
    PROFILE_SIGNING_KEY=$(extract_field "personal" "work:" "signing_key" "$CONFIG_FILE")
    break
  fi
done <<< "$(extract_paths "personal" "work:" "$CONFIG_FILE")"

# Check work profile paths
if [ -z "$MATCHED_PROFILE" ]; then
  while IFS= read -r path_pattern || [ -n "$path_pattern" ]; do
    [ -z "$path_pattern" ] && continue
    # Normalize path: convert backslashes to forward slashes and lowercase
  path_pattern_lower="${path_pattern//\\//}"
  path_pattern_lower=$(echo "$path_pattern_lower" | tr '[:upper:]' '[:lower:]')
    regex_pattern=$(escape_for_regex "$path_pattern_lower")
    if printf '%s' "$CURRENT_DIR_LOWER" | grep -qE "^${regex_pattern}$" 2>/dev/null; then
      MATCHED_PROFILE="work"
      PROFILE_NAME=$(extract_field "work" "default:" "name" "$CONFIG_FILE")
      PROFILE_EMAIL=$(extract_field "work" "default:" "email" "$CONFIG_FILE")
      PROFILE_GH_USER=$(extract_field "work" "default:" "gh_user" "$CONFIG_FILE")
      PROFILE_SIGNING_KEY=$(extract_field "work" "default:" "signing_key" "$CONFIG_FILE")
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
    PROFILE_SIGNING_KEY=$(extract_field "personal" "work:" "signing_key" "$CONFIG_FILE")
  elif [ "$MATCHED_PROFILE" = "work" ]; then
    PROFILE_NAME=$(extract_field "work" "default:" "name" "$CONFIG_FILE")
    PROFILE_EMAIL=$(extract_field "work" "default:" "email" "$CONFIG_FILE")
    PROFILE_GH_USER=$(extract_field "work" "default:" "gh_user" "$CONFIG_FILE")
    PROFILE_SIGNING_KEY=$(extract_field "work" "default:" "signing_key" "$CONFIG_FILE")
  else
    output_json "true" "gh-profile: Invalid default profile"
    exit 0
  fi
fi

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
  if [ "$CURRENT_KEY" != "$PROFILE_SIGNING_KEY" ]; then
    git config user.signingkey "$PROFILE_SIGNING_KEY"
    git config commit.gpgsign true
    GIT_SWITCHED=true
  fi
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
    GH_STATUS="need auth: GH_CONFIG_DIR=$GH_CONFIG_DIR gh auth login"
  fi
else
  GH_STATUS="gh not installed"
fi

if [ "$GIT_SWITCHED" = true ]; then
  MESSAGE="gh-profile: Switched to $MATCHED_PROFILE ($PROFILE_EMAIL), gh: $GH_STATUS"
else
  MESSAGE="gh-profile: Using $MATCHED_PROFILE ($PROFILE_EMAIL), gh: $GH_STATUS"
fi

output_json_with_env "true" "$MESSAGE" "$GH_CONFIG_DIR_WIN"
exit 0
