---
name: rubysmithing-context
requires: []
description: Gem API verification sub-skill for Ruby development. Automatically activates on first mention of any Ruby gem — especially ruby_llm, sequel, async, bubbletea, dspy.rb, pgvector, huh, dry-schema, circuit_breaker, fast-mcp, or informers — and resolves current method signatures and usage examples via Context7 MCP before code is generated. Results are cached for the session and persisted to SQLite across sessions. If Context7 resolution fails or is rate-limited, falls back to the tiered degradation protocol (stale cache → gem-registry ID → WARNING block) rather than silently guessing. Pairs with rubysmithing, rubysmithing-genai, and rubysmithing-tui as a prerequisite step.
---

# Rubysmithing — Context

Context7-powered gem API resolver. Fires before any library-specific code is written.
Caches results for the session and persists them to SQLite across sessions.
Fails loudly — never silently. Degrades gracefully when Context7 is unreachable.

## When This Skill Activates

Activate on first mention of any gem not in Ruby stdlib. Priority gems that always
warrant a fresh lookup (API surface changes frequently):

- `ruby_llm`, `ruby_llm-mcp`, `ruby_llm-schema`
- `bubbletea`, `lipgloss`, `huh`, `gum`, `ntcharts`, `bubblezone`
- `dspy.rb`, `dspy-ruby_llm`
- `sequel` (plugin API especially)
- `async`, `falcon`
- `circuit_breaker`
- `fast-mcp`
- `informers`
- `dry-schema`, `dry-types`

Skip lookup for: stdlib, gems already resolved this session, Lite Mode tasks.

## Step 1: Check Session Cache

Before any Context7 or SQLite call, check if the gem has been resolved in this session.
Track resolved gems mentally as:

```
session_cache = {
  "ruby_llm" => { context7_id: "/crmne/ruby_llm", resolved: true },
  "sequel"   => { context7_id: "/jeremyevans/sequel", resolved: true }
}
```

If cached → use cached result directly, skip Steps 2–4.

## Step 2: Check Persistent SQLite Cache

Before calling Context7, check `~/.rubysmithing/context_cache.db` via
`scripts/context_cache.rb`.

```
cache = Rubysmithing::ContextCache.new
entry = cache.fetch(gem_name)   # returns nil if missing or past TTL (7 days)
```

If a fresh entry is found → use it, add to session cache, skip Steps 3–4.

## Step 3: Resolve Library ID

Use `Context7:resolve-library-id` with the gem name.
Check `references/gem-registry.md` first — if the gem is listed, use the pre-mapped
Context7 ID directly without a resolve call.

## Step 4: Query Documentation

Use `Context7:query-docs` with a targeted query — not just the gem name.

Query format: `"[gem] [specific pattern]"`

Examples:

```
"ruby_llm chat streaming tool calling"
"sequel dataset filter pgvector similarity"
"async fiber barrier timeout"
"bubbletea model update view lifecycle"
"huh form group select input validation"
"circuit_breaker circuit breaker threshold reset"
"dspy.rb chain of thought signature module"
```

Extract: method signatures, parameter names, minimal working example,
deprecation warnings or breaking changes noted in docs.

## Step 5: Cache and Return

Store the resolved result in both session cache and SQLite persistent cache:

```
cache.store(gem_name, context7_id: id, method_sigs: [...], example: "...")
```

Return to the requesting skill:

- Gem name + Context7 ID used
- Relevant method signatures (verbatim from docs)
- Minimal working example
- Any deprecation or breaking change warnings

---

## Context7 Unavailability & Rate Limit Protocol

When Context7 is unreachable (network timeout, 5xx error) or rate-limited (429),
apply the following tiered degradation — do not block code generation.

### Tier 1 — Stale SQLite Cache (preferred fallback)

```ruby
entry = cache.fetch_stale(gem_name)
```

If a stale entry exists (any age), use it and inject a staleness warning block:

```ruby
# [WARNING: Stale API Syntax — Context7 Unavailable]
# Could not reach Context7 to refresh documentation for: [gem_name]
# Falling back to cached data last verified: [date] ([N] days ago)
# This code MAY be outdated. Verify against: https://rubygems.org/gems/[gem_name]
# Re-run after Context7 is reachable to refresh: cache.evict("[gem_name]")
```

Flag every method call from the stale gem with `# stale-cache` inline comment.
Add to session cache with `stale: true` flag so downstream skills know.

### Tier 2 — Gem Registry ID + Retry

If no SQLite entry at all, check `references/gem-registry.md` for a pre-mapped
Context7 ID and attempt a single retry with that ID directly, bypassing resolve step.

If retry succeeds → cache result, proceed normally.
If retry fails → continue to Tier 3.

### Tier 3 — Unverified Training Data (last resort)

No stale cache, no registry retry success. Inject the full unverified block:

```ruby
# [WARNING: Unverified API Syntax]
# Context7 could not resolve documentation for: [gem_name]
# The following code is based on training data and MAY be outdated or incorrect.
# Verify against: https://rubygems.org/gems/[gem_name] before use.
# Run: bundle exec ruby -e "require '[gem_name]'; puts [GemClass].instance_methods"
# to inspect the actual available API.
```

Flag every method call from the unverified gem with `# unverified` inline comment.

### Rate Limit Backoff Note

If Context7 returns a rate limit signal: note it to the user, apply Tier 1 or Tier 2
immediately, and do not retry Context7 again within the same session for the
rate-limited gem. Let the session cache serve subsequent requests.

---

## Failure Protocol (No Match / Empty Result)

If Context7 resolves but returns no documentation match for the gem:

**Do not silently fall back to training data.**

Apply Tier 3 (Unverified block) and proceed with best-effort generation,
flagging every method call from the unverified gem with `# unverified`.

---

## Gem Registry

Load `references/gem-registry.md` for the full curated gem → Context7 ID mapping,
architectural plane assignments, project archetype → gem set lookup, and
`last_verified` dates for registry staleness detection.

---

## SQLite Cache (Persistent Across Sessions)

For frequently used gems, a local SQLite cache via Sequel prevents repeated
Context7 lookups across separate sessions. The cache lives at:
`~/.rubysmithing/context_cache.db`

Schema (managed by `scripts/context_cache.rb`):

```ruby
create_table(:gem_cache) do
  String  :gem_name,    null: false, unique: true
  String  :context7_id, null: false
  Text    :method_sigs  # JSON array of signature strings
  Text    :example      # minimal working code example
  Time    :resolved_at, null: false
  Integer :ttl_days,    default: 7
end
```

Cache invalidation: TTL of 7 days per gem (configurable per-entry).
Stale entries are not evicted automatically — they serve as Tier 1 fallback data
when Context7 is unavailable. Evict manually with `cache.evict(gem_name)` after
a successful refresh.

Check the persistent cache before any Context7 MCP call.
If the cache file doesn't exist, create it on first use — do not error.

### Cache CLI

```bash
ruby scripts/context_cache.rb list              # all cached gems with age + status
ruby scripts/context_cache.rb check <gem>       # fresh fetch (respects TTL)
ruby scripts/context_cache.rb stale <gem>       # stale fetch + warning block
ruby scripts/context_cache.rb evict <gem>       # remove entry to force refresh
```
