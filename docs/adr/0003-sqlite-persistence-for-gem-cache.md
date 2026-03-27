# ADR 0003: SQLite for Gem API Cache Persistence

**Status:** Accepted

---

## Context

`rubysmithing-context` resolves gem API documentation via Context7 (ADR 0002). Without caching, every generation session that involves non-stdlib gems must re-fetch documentation, incurring Context7 round-trips and degrading if the service is unavailable.

Cache options considered:

1. **Session memory only** — cache expires when the Claude Code session ends
2. **Flat files** — one `.json` or `.md` file per gem in a cache directory
3. **SQLite** — structured database with TTL, staleness tracking, and CLI tooling

Session memory is lost between conversations. Flat files work but require custom parsing and provide no TTL management. SQLite provides structured queries, a `last_verified` timestamp per entry, and a clean CLI interface for cache inspection and management.

The Gemfile already includes `sqlite3` and `sequel` as dependencies.

---

## Decision

Use SQLite (via the `sequel` gem) as the persistence layer for gem API cache entries. Entries include:

- Gem name
- Resolved Context7 library ID
- Cached documentation content
- `last_verified` timestamp
- TTL (entries older than 3 months trigger a re-verification warning)

Cache management is exposed via a CLI script:

```bash
ruby skills/rubysmithing-context/scripts/context_cache.rb list     # all cached entries + staleness
ruby skills/rubysmithing-context/scripts/context_cache.rb check    # fresh fetch (TTL-aware)
ruby skills/rubysmithing-context/scripts/context_cache.rb stale    # force stale + warning block
ruby skills/rubysmithing-context/scripts/context_cache.rb evict    # force re-resolution
```

SQLite is declared the source of truth, not session memory. The agent reads from SQLite first; Context7 is queried only on cache miss or explicit eviction.

---

## Consequences

**Benefits:**
- Warmed cache entries serve instantly from disk in subsequent sessions
- `last_verified` timestamps make staleness visible and auditable
- The CLI makes cache state inspectable without reading raw database files
- `sequel` is already in the stack, so no new dependencies are introduced

**Trade-offs:**
- SQLite adds a file-system dependency (the `.db` file must exist and be writable)
- TTL management is currently manual (`evict` command) — no automatic background expiration
- Entries verified against one gem version may be stale if the gem releases a breaking change within the TTL window

**Mitigation:** Gem registry entries carry `last_verified` dates; the CLI `list` command surfaces stale entries. The 3-month TTL is conservative enough to catch most breaking changes in active gems.

---

## Sources

- `skills/rubysmithing-context/scripts/context_cache.rb` — SQLite cache implementation
- `Gemfile` — `sqlite3`, `sequel`, `yajl-ruby` dependencies
- `CLAUDE.md` — "SQLite cache: rubysmithing-context uses SQLite as source of truth, not session memory"
- `CHANGELOG.md` — "Promote context_cache CLI to model-callable tool" (feature entry)
