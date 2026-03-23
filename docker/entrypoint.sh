#!/usr/bin/env bash
# rubysmithing Docker entrypoint
#
# Usage:
#   ./entrypoint.sh              # Start Claude Code with plugin
#   ./entrypoint.sh --test       # Run routing test harness
#   ./entrypoint.sh --help       # Show this help

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"

show_help() {
  cat <<EOF
Rubysmithing Docker Entrypoint

Usage:
  ./entrypoint.sh              Start Claude Code with plugin
  ./entrypoint.sh --test       Run routing test harness
  ./entrypoint.sh --help       Show this help

Test Harness:
  Validates that the orchestrator routes mock prompts to the correct sub-agents.
  Returns exit code 0 if all tests pass, 1 if any fail.

EOF
}

run_tests() {
  echo "Running Rubysmithing routing test harness..."
  echo "============================================="
  echo ""

  local failed=0
  local passed=0

  bash "$PLUGIN_ROOT/docker/test-routing.sh"
  local result=$?

  if [[ $result -eq 0 ]]; then
    echo ""
    echo "All routing tests passed."
    exit 0
  else
    echo ""
    echo "Some routing tests failed."
    exit 1
  fi
}

# Parse arguments
case "${1:-}" in
  --test|-t)
    run_tests
    ;;
  --help|-h)
    show_help
    exit 0
    ;;
  *)
    exec claude "$@"
    ;;
esac
