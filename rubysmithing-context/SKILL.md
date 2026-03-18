---
name: rubysmithing-context
description: Context7 gem documentation lookup sub-skill for the rubysmithing suite. Automatically resolves current API syntax, method signatures, and usage examples for Ruby gems using the Context7 MCP tool. Fires automatically on first gem mention in a session and caches results. Use this skill whenever current gem documentation is needed before implementing library-specific code, especially for version-sensitive gems like ruby_llm, sequel, async, bubbletea, and dspy.rb.
---

# Rubysmithing — Context

Context7-powered gem documentation resolver. Prevents stale-syntax errors by querying
live documentation before any gem-specific code is written.

## Gem Registry

Load `references/gem-registry.md` before any lookup. It contains:
- Curated Context7 library IDs for the full project stack
- Architectural plane each gem belongs to (Runtime, TUI, AI, Storage, Async, Data)
- Cross-references between gem roles and common usage patterns

## Lookup Protocol

### Trigger Conditions
Fire a Context7 lookup when:
- A gem from `gem-registry.md` is mentioned for the first time in the session
- An unfamiliar gem not in the registry is referenced
- The request involves a specific method, configuration, or integration pattern

Do NOT fire a lookup for:
- Pure stdlib (Struct, Enumerable, File, etc.)
- Gems already resolved earlier in the same session (use cached result)
- Generic Ruby patterns with no external gem surface

### Resolution Steps

1. **Resolve library ID** — Use `Context7:resolve-library-id` with the gem name.
   Check `gem-registry.md` first; if listed, use the pre-mapped ID directly.

2. **Query documentation** — Use `Context7:query-docs` with a specific, targeted query.
   Write queries as: `"[gem] [specific pattern or method]"` not just the gem name.

   Good query examples:
   ```
   "ruby_llm chat with tool calling and streaming"
   "sequel dataset filter with pgvector similarity search"
   "async fiber scheduler with timeout"
   "bubbletea model update view lifecycle"
   "dspy.rb chain of thought module"
   ```

3. **Extract and apply** — Pull the relevant method signatures and code examples.
   Pass them as context to the generating skill (rubysmithing, rubysmithing-genai,
   rubysmithing-tui) before any code is written.

### Handling Unknown Gems

If a gem is not in `gem-registry.md`:
1. Attempt `Context7:resolve-library-id` anyway
2. If resolved: note the gem is not in the curated registry and suggest adding it
3. If unresolved: fall back to training knowledge and flag the uncertainty explicitly

## Session Cache

Track resolved gems within a conversation to avoid redundant lookups:
```
resolved_gems = {
  "ruby_llm" => { id: "/crmne/ruby_llm", queried_at: "turn 3" },
  "sequel"   => { id: "/jeremyevans/sequel", queried_at: "turn 5" }
}
```
Before any lookup, check if the gem is already in the session cache.

## Output

When returning resolved context to a generating skill:
- Gem name + Context7 ID used
- Relevant method signatures (verbatim from docs)
- Minimal working example from documentation
- Any breaking changes or deprecation warnings found
