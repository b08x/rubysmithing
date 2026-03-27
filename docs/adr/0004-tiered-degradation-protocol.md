# ADR 0004: Tiered Degradation When Context7 Is Unavailable

**Status:** Accepted

---

## Context

`rubysmithing-context` depends on Context7 MCP (ADR 0002) for live gem API verification. Context7 can be unavailable due to: network issues, rate limiting, service downtime, or the user not having configured the MCP server.

The options for handling unavailability were:

1. **Hard fail** — block code generation with an error until Context7 is available
2. **Silent fallback** — proceed with training data, no warning to the user
3. **Tiered degradation** — try progressively less reliable sources, always annotating confidence level

Hard fail blocks productive work for issues outside the user's control. Silent fallback is worse — it produces code that might be wrong without telling the user. The user has no way to know whether the API signatures in the output are verified or guessed.

---

## Decision

Implement a tiered degradation protocol with explicit confidence annotation at each tier:

```
Tier 1: Context7 MCP (live)
  └─ Success → serve docs, cache result, no annotation needed

Tier 2: SQLite cache (stale)
  └─ Hit → serve stale docs + inject WARNING block in output:
            "[Cache: stale — verify before using, last verified: DATE]"

Tier 3: Gem registry pre-mapped ID
  └─ ID found → retry Context7 with mapped ID
     └─ Success → serve docs, note source
     └─ Fail → fall to Tier 4

Tier 4: Last resort
  └─ Inject: [WARNING: Unverified API Syntax — verify against gem source before using]
     Never silently proceed.
```

The key invariant: **never silently proceed with unverified API syntax.** Every tier below Tier 1 must annotate its output with the confidence level. The user always knows what they're getting.

---

## Consequences

**Benefits:**
- The plugin remains usable when Context7 is unavailable — productivity is not blocked
- Users always know the confidence level of API signatures in generated code
- The WARNING block pattern is machine-readable: downstream agents can detect and flag it
- Tier 3 (gem registry retry) recovers many cases that would otherwise reach Tier 4

**Trade-offs:**
- Stale cache entries (Tier 2) may reference outdated API signatures without the user noticing the WARNING block
- WARNING blocks in generated code require the user to manually verify before using
- The protocol adds complexity to `rubysmithing-context` — three different code paths must be maintained

**Mitigation:** The WARNING block is visually distinct and impossible to miss in output. The `list` command surfaces stale entries for proactive cleanup. Users who warm the cache before sessions (pre-run `/rubysmithing:context <gem>`) will rarely encounter Tiers 2-4.

---

## Sources

- `skills/rubysmithing-context/SKILL.md` — tiered degradation steps
- `CLAUDE.md` — "Tiered Degradation" section
- `CHANGELOG.md` — "Implement SIFT mitigations and Context7 resilience" (feature entry)
