#!/bin/bash
# Config parsing and path matching shared by detect-profile.sh and gh-wrapper.sh

# Value from the text after "key:" or "- ": inside "double quotes" (with \\
# and \" decoded), inside 'single quotes' (with '' decoded to '), or the bare
# value with any trailing "# comment" removed.
yaml_value() {
  local rest="$1"
  rest="${rest#"${rest%%[![:space:]]*}"}"
  if [[ "$rest" == \"* ]]; then
    # Read up to the closing quote, decoding \\ and \" (other backslashes kept,
    # so "C:\Work\*" still works)
    local out="" c n i=1
    while [ "$i" -lt "${#rest}" ]; do
      c="${rest:i:1}"
      n="${rest:i+1:1}"
      if [ "$c" = '\' ] && { [ "$n" = '\' ] || [ "$n" = '"' ]; }; then
        c="$n"
        i=$((i + 1))
      elif [ "$c" = '"' ]; then
        break
      fi
      out+="$c"
      i=$((i + 1))
    done
    printf '%s' "$out"
  elif [[ "$rest" == \'* ]]; then
    printf '%s' "$rest" | sed -E "s/^'(([^']|'')*)'.*/\1/; s/''/'/g"
  else
    rest="${rest%%[[:space:]]#*}"
    printf '%s' "${rest%"${rest##*[![:space:]]}"}"
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
  local line
  line=$(sed -n "/^  ${section_start}:/,/^  ${section_end}/p" "$config_file" \
    | grep "${field}:" | head -1) || true
  yaml_value "${line#*${field}:}"
}

extract_paths() {
  local section_start="$1"
  local section_end="$2"
  local config_file="$3"
  local line
  sed -n "/^  ${section_start}:/,/^  ${section_end}/p" "$config_file" \
    | grep -E '^\s+- ' | while IFS= read -r line; do
      yaml_value "${line#*- }"
      echo
    done || true
}

# Section that ends a profile's block in the config
section_end() {
  if [ "$1" = "personal" ]; then echo "work:"; else echo "default:"; fi
}

# Print "personal" or "work" if one of its path patterns matches the
# directory (C:/... or /... form), otherwise print nothing.
match_profile() {
  local dir_lower profile pattern
  dir_lower=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  for profile in personal work; do
    while IFS= read -r pattern || [ -n "$pattern" ]; do
      [ -z "$pattern" ] && continue
      pattern="${pattern//\\//}"     # "\" -> "/"
      pattern=$(printf '%s' "$pattern" | tr '[:upper:]' '[:lower:]')
      if printf '%s' "$dir_lower" | grep -qE "^$(escape_for_regex "$pattern")$" 2>/dev/null; then
        echo "$profile"
        return
      fi
    done <<< "$(extract_paths "$profile" "$(section_end "$profile")" "$2")"
  done
}

default_profile() {
  local line
  line=$(grep '^default:' "$1" | head -1) || true
  yaml_value "${line#default:}"
}
