# ADR 0002: Context7 MCP for Live Gem API Verification

**Status:** Accepted

---

## Context

Generating Ruby code that uses specific gems (sequel, bubbletea, dry-schema, etc.) requires accurate knowledge of current method signatures, constructor options, and usage patterns. The alternatives were:

1. **Rely on training data** — use the model's knowledge of gem APIs
2. **Hardcoded reference files** — maintain static `.md` files with API examples
3. **Context7 MCP** — fetch live documentation from library sources at generation time

Training data has a knowledge cutoff and does not reflect gem releases after that date. Gems in active development (bubbletea-ruby, lipgloss-ruby, huh-ruby) change APIs frequently. Hardcoded reference files require manual updates and drift silently.

Context7 fetches documentation at query time from authoritative sources. The `rubysmithing-context` agent calls `mcp__plugin_context7_context7__resolve-library-id` then `mcp__plugin_context7_context7__query-docs` to get current signatures with code examples.

---

## Decision

Use Context7 MCP as the primary source of gem API documentation. All code-generating skills that touch non-stdlib gems must run `rubysmithing-context` first and block on the result before generating.

A gem registry (`skills/rubysmithing-context/references/gem-registry.md`) maps ~225 gem names to their Context7 library IDs, providing a pre-mapped fallback for the tiered degradation protocol (see ADR 0004).

---

## Consequences

**Benefits:**
- Generated code uses verified current API syntax, not stale training data
- The `[WARNING: Unverified API Syntax]` block is injected explicitly when verification fails — callers know what they're getting
- The gem registry serves as a machine-readable dependency map of the entire stack

**Trade-offs:**
- Context7 is an external MCP service dependency. If it's unavailable, code generation degrades (see ADR 0004 for how)
- Every code-gen session involving non-stdlib gems incurs a Context7 round-trip unless the cache is warm
- Users must configure Context7 MCP in their Claude Code settings; the plugin cannot do this for them

**Mitigation:** SQLite caching (ADR 0003) and tiered degradation (ADR 0004) ensure the plugin remains usable when Context7 is slow or unavailable.

---

## Sources

- `skills/rubysmithing-context/SKILL.md` — Context7 integration steps
- `skills/rubysmithing-context/references/gem-registry.md` — Context7 library ID registry
- `CLAUDE.md` — Context7 MCP Integration section
- `CHANGELOG.md` — "Implement SIFT mitigations and Context7 resilience" (feature entry)
