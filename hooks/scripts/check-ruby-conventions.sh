#!/usr/bin/env bash
# check-ruby-conventions.sh
#
# PostToolUse hook: checks .rb files written by Claude for the frozen_string_literal pragma.
# Exits 0 (silent pass) or 2 (feedback fed back to Claude) per hook protocol.

set -euo pipefail

# Degrade gracefully if jq is not installed
command -v jq &>/dev/null || exit 0

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Only check .rb files
[[ "$file_path" == *.rb ]] || exit 0

# Only check if the file actually exists on disk
[[ -f "$file_path" ]] || exit 0

# Check for frozen_string_literal pragma on line 1
first_line=$(head -n1 "$file_path" 2>/dev/null || echo "")

if [[ "$first_line" != "# frozen_string_literal: true" ]]; then
  echo "CONVENTION: ${file_path} is missing '# frozen_string_literal: true' on line 1." >&2
  echo "Prepend it now, or run /rubysmithing:refactor to apply full Standard Mode convention hardening." >&2
  exit 2
fi

exit 0
