---
name: rubysmithing-context
description: Gem API verification sub-skill for Ruby development. Automatically activates on first mention of any Ruby gem — especially ruby_llm, sequel, async, bubbletea, dspy.rb, pgvector, huh, dry-schema, breaker_machines, fast-mcp, or informers — and resolves current method signatures and usage examples via Context7 MCP before code is generated. Results are cached for the session. If Context7 resolution fails, injects an explicit [WARNING: Unverified API Syntax] block rather than silently guessing. Pairs with rubysmithing, rubysmithing-genai, and rubysmithing-tui as a prerequisite step.
---

# Rubysmithing — Context

Context7-powered gem API resolver. Fires before any library-specific code is written.
Caches results for the session. Fails loudly — never silently.

## When This Skill Activates

Activate on first mention of any gem not in Ruby stdlib. Priority gems that always
warrant a fresh lookup (API surface changes frequently):

- `ruby_llm`, `ruby_llm-mcp`, `ruby_llm-schema`
- `bubbletea`, `lipgloss`, `huh`, `gum`, `ntcharts`, `bubblezone`
- `dspy.rb`, `dspy-ruby_llm`
- `sequel` (plugin API especially)
- `async`, `falcon`
- `breaker_machines`
- `fast-mcp`
- `informers`
- `dry-schema`, `dry-types`

Skip lookup for: stdlib, gems already resolved this session, Lite Mode tasks.

## Step 1: Check Session Cache

Before any Context7 call, check if the gem has been resolved in this session.
Track resolved gems mentally as:

```
session_cache = {
  "ruby_llm" => { context7_id: "/crmne/ruby_llm", resolved: true },
  "sequel"   => { context7_id: "/jeremyevans/sequel", resolved: true }
}
```

If cached → use cached result directly, skip Steps 2–3.

## Step 2: Resolve Library ID

Use `Context7:resolve-library-id` with the gem name.
Check `references/gem-registry.md` first — if the gem is listed, use the pre-mapped
Context7 ID directly without a resolve call.

## Step 3: Query Documentation

Use `Context7:query-docs` with a targeted query — not just the gem name.

Query format: `"[gem] [specific pattern]"`

Examples:
```
"ruby_llm chat streaming tool calling"
"sequel dataset filter pgvector similarity"
"async fiber barrier timeout"
"bubbletea model update view lifecycle"
"huh form group select input validation"
"breaker_machines circuit breaker threshold reset"
"dspy.rb chain of thought signature module"
```

Extract: method signatures, parameter names, minimal working example,
deprecation warnings or breaking changes noted in docs.

## Step 4: Cache and Return

Add resolved gem to session cache. Return to the requesting skill:
- Gem name + Context7 ID used
- Relevant method signatures (verbatim from docs)
- Minimal working example
- Any deprecation or breaking change warnings

## Failure Protocol

If Context7 resolution fails for any reason (timeout, no match, empty result):

**Do not silently fall back to training data.**

Inject this block at the top of any generated code that uses the unverified gem:

```ruby
# [WARNING: Unverified API Syntax]
# Context7 could not resolve documentation for: [gem_name]
# The following code is based on training data and MAY be outdated or incorrect.
# Verify against: https://rubygems.org/gems/[gem_name] before use.
# Run: bundle exec ruby -e "require '[gem_name]'; puts [GemClass].instance_methods"
# to inspect the actual available API.
```

Then proceed with best-effort generation, flagging every method call from the
unverified gem with an inline `# unverified` comment.

## Gem Registry

Load `references/gem-registry.md` for the full curated gem → Context7 ID mapping,
architectural plane assignments, and project archetype → gem set lookup.

## SQLite Cache (Persistent Across Sessions)

For frequently used gems, a local SQLite cache via Sequel prevents repeated
Context7 lookups across separate sessions. The cache lives at:
`~/.rubysmithing/context_cache.db`

Schema:
```ruby
# migrations/001_create_gem_cache.rb
Sequel.migration do
  change do
    create_table(:gem_cache) do
      String  :gem_name,      null: false, unique: true
      String  :context7_id,   null: false
      Text    :method_sigs    # JSON-serialized method signatures
      Text    :example        # minimal working example
      Time    :resolved_at,   null: false
      Integer :ttl_days,      default: 7
    end
  end
end
```

Cache invalidation: TTL of 7 days per gem. Stale entries trigger a fresh Context7 lookup.

Check the persistent cache before any Context7 MCP call.
If the cache file doesn't exist, create it on first use — do not error.
