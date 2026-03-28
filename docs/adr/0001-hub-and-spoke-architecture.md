# ADR 0001: Hub-and-Spoke Agent Architecture

**Status:** Accepted

---

## Context

The rubysmithing plugin needs to handle eight distinct Ruby development domains: project scaffolding, code generation (main), TUI development, GenAI components, refactoring, quality assessment, YARD documentation, and code analysis. Each domain has different tool requirements, different reference files, and different context prerequisites.

The alternatives considered were:

1. **Single general-purpose agent** — one agent handles all requests, loads all reference material, uses if/else routing internally
2. **Flat agent pool** — eight agents of equal status, user selects the right one
3. **Hub-and-spoke** — thin orchestrator routes to specialized domain agents

A single general-purpose agent accumulates all reference material in one context window, which leads to the "telephone game problem": each piece of routing reasoning dilutes the domain-specific instructions. A flat pool puts routing responsibility on the user, who shouldn't need to know which agent handles Zeitwerk errors vs. Muda analysis.

---

## Decision

Use a hub-and-spoke architecture:

- `rubysmithing-orchestrator` is the thin routing hub — it analyzes requests, detects conventions, and dispatches. It never generates code.
- Eight domain agents are the spokes — each loads only its domain-specific references.
- Two evaluation agents (`rubysmithing-meta-judge`, `rubysmithing-judge`) are infrastructure called internally by refactor and report agents.

The orchestrator uses a routing table, convention detection, and dynamic effort weighting for compound requests. Pass-through agents (report, yardoc, scaffold) return their output unchanged without orchestrator post-processing.

---

## Consequences

**Benefits:**
- Each agent's context window contains only what's relevant to its domain
- Parallel dispatch is trivially expressible: independent sub-tasks run simultaneously
- Adding a new domain (e.g., `rubysmithing-migrations`) requires adding one agent and one routing table entry
- The orchestrator's routing table is a single, readable source of truth for dispatch logic

**Trade-offs:**
- Two-hop latency for most requests (orchestrator → domain agent)
- Routing mistakes send requests to the wrong agent; requires accurate routing table maintenance
- Compound requests (e.g., TUI + GenAI) require the orchestrator to reason about effort weights and dispatch order

**Mitigation:** The routing test harness (`docker/test-routing.sh`) validates that routing table entries correctly map to the expected agent after any prompt engineering change.

---

## Sources

- `skills/rubysmithing/agents/rubysmithing-orchestrator.md` — routing table and dispatch logic
- `CLAUDE.md` — orchestrator/sub-agent architecture section
- `CHANGELOG.md` — "Reorganize and refine rubysmithing suite to v1.0" (refactor entry)
