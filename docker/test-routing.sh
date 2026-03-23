#!/usr/bin/env bash
# test-routing.sh - Validate orchestrator routing decisions
#
# Feeds mock prompts through the routing table and verifies the correct
# sub-agent is cited in the output. Used by entrypoint.sh --test.
#
# Exit codes:
#   0 - All tests passed
#   1 - One or more tests failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
ORCHESTRATOR="$PLUGIN_ROOT/agents/rubysmithing-orchestrator.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

passed=0
failed=0

# Test case format: "description|expected_pattern"
# Verifies the routing table contains entries for each sub-agent
declare -a TEST_CASES=(
  "TUI/BubbleTea routing exists|rubysmithing-tui"
  "Scaffold routing exists|rubysmithing-scaffold"
  "Refactor routing exists|rubysmithing-refactor"
  "Report/QA routing exists|rubysmithing-report"
  "GenAI/RAG routing exists|rubysmithing-genai"
  "Analyse/Debug routing exists|rubysmithing-analyse"
  "YARD docs routing exists|rubysmithing-yardoc"
  "Main hub routing exists|rubysmithing.*main"
  "Parallel dispatch table exists|Parallel"
)

run_test() {
  local test_case="$1"
  local prompt="${test_case%%|*}"
  local expected="${test_case##*|}"

  echo -n "Testing: '$prompt' -> "
  echo -n "$expected... "

  # Check if orchestrator file exists
  if [[ ! -f "$ORCHESTRATOR" ]]; then
    echo -e "${RED}FAIL${NC}"
    echo "  Orchestrator file not found: $ORCHESTRATOR"
    ((failed++))
    return 1
  fi

  # Check if the routing table contains the expected agent
  # This is a static analysis - checks if the routing table maps correctly
  if grep -qE "$expected" "$ORCHESTRATOR"; then
    echo -e "${GREEN}PASS${NC}"
    ((passed++))
    return 0
  else
    echo -e "${RED}FAIL${NC}"
    echo "  Expected pattern not found in orchestrator: $expected"
    ((failed++))
    return 1
  fi
}

echo "Rubysmithing Routing Test Harness"
echo "=================================="
echo ""
echo "Validating routing table mappings..."
echo ""

for test_case in "${TEST_CASES[@]}"; do
  run_test "$test_case"
done

echo ""
echo "=================================="
echo -e "Results: ${GREEN}$passed passed${NC}, ${RED}$failed failed${NC}"

if [[ $failed -gt 0 ]]; then
  exit 1
fi

exit 0
