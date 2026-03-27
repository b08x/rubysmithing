# Walkthrough: Analyse a Codebase

Use `rubysmithing-analyse` to understand what a codebase actually does, find waste, trace root causes, or prepare for a refactor. This is the step that happens *before* you change anything.

---

## When to Analyse First

| Situation | Method |
|:----------|:-------|
| You're about to refactor an unfamiliar area | Gemba Walk |
| Code is slow, bloated, or has dead methods | Muda Analysis |
| An exception or error is occurring | Root-Cause Tracing |
| The same bug keeps coming back | Five Whys |
| You don't know which method to use | Default: Gemba Walk |

---

## Method Auto-Selection

`rubysmithing-analyse` picks the method from context signals. You can always override with an explicit flag.

| Signal in your request | Method selected |
|:----------------------|:----------------|
| Error, stack trace, "why is this failing" | Root-Cause Tracing |
| "what's slow", "dead code", "wasting", "over-engineered" | Muda Analysis |
| "how does this actually work", "pre-refactor", unfamiliar code | Gemba Walk |
| "why did this happen", recurring issue | Five Whys |
| `--trace`, `--muda`, `--gemba`, `--why` | Explicit override |

---

## Walkthrough A: Gemba Walk Before Refactoring

You've been asked to refactor `lib/pipeline/processor.rb` but you've never read it.

### 1. Trigger the analysis

```
Gemba walk lib/pipeline/processor.rb before I refactor it
```

`rubysmithing-analyse` activates with `--gemba`.

### 2. What the agent does

1. **States scope** — `lib/pipeline/processor.rb`
2. **States assumptions** — what the file is documented or expected to do based on name and any comments
3. **Observes reality** — reads the actual code: entry points, data flow, require/autoload chain, Zeitwerk config vs. file structure
4. **Documents surprises** — undocumented behavior, hidden dependencies, stale comments, debug `puts` left in, methods that shadow stdlib
5. **Identifies gaps** — docs vs. reality mismatches, missing `frozen_string_literal`, config that should use `tty-config`
6. **Recommends** — update docs, route to refactor, or accept as intentional

### 3. Sample output

```
## Gemba Walk — lib/pipeline/processor.rb

### Scope
Single file: lib/pipeline/processor.rb (142 lines)

### Assumed Behavior
Based on name and README: processes ingestion pipeline records, applies
transformations, writes to Sequel-backed store.

### Observed Reality
- Entry: Processor.new(config:).call(records) — correct
- Data flow: records → validate → transform → persist → return Result struct
- Hidden dependency: calls ContentParser directly (not injected) — tight coupling
- Zeitwerk: file is at lib/pipeline/processor.rb → maps to Pipeline::Processor ✓

### Surprises
- Line 47: `puts "DEBUG: record count = #{records.size}"` — debug line left in
- Line 89: rescue block swallows all exceptions and returns nil — silent failure
- Line 103: calls external API without circuit_breaker wrapping
- No frozen_string_literal header

### Gaps
- ContentParser dependency is implicit — not visible from public interface
- Silent nil return on exception hides errors from callers

### Recommendations
1. Route to rubysmithing-refactor: add frozen_string_literal, circuit_breaker,
   explicit error handling (refactor-patterns: circuit_breaker, error_hierarchy)
2. Remove debug puts (refactor-patterns: logging_standard)
3. Inject ContentParser via constructor for testability
```

### 4. Hand off to refactor

The analysis output is keyed to `rubysmithing-refactor` pattern names. Follow up immediately:

```
Apply those recommendations — refactor lib/pipeline/processor.rb
```

---

## Walkthrough B: Muda Waste Analysis

Your project has grown and you suspect there's dead code and inefficient patterns.

### 1. Trigger the analysis

```
Muda analysis of lib/ — what's wasting cycles or dead weight?
```

Or for a specific concern:

```
Are there any N+1 queries or unused methods in lib/data/?
```

### 2. What the agent does

Maps 7 waste types to your Ruby artifacts:

| Waste | What It Finds |
|:------|:-------------|
| **Overproduction** | Dead methods, unused public API, speculative abstractions |
| **Waiting** | N+1 queries, sync I/O that could be async, unbatched loops |
| **Transport** | Data passed through layers unused, over-serialization |
| **Over-processing** | Validation repeated at multiple layers, unnecessary transforms |
| **Inventory** | Unused gems in Gemfile, obsolete initializer args |
| **Motion** | Too many object allocations per request, repeated lookups |
| **Defects** | Silent rescue blocks, missing type validation, no circuit breakers |

### 3. Sample output (excerpt)

```
## Muda Analysis — lib/data/

### Overproduction
- DataStore#legacy_fetch (line 34): called nowhere in codebase — dead method
- Transformer#with_metadata: always returns nil — speculative abstraction

### Waiting
- Line 78: N+1 — record.author called inside loop without eager loading
  Fix: .includes(:author) on query, or batch with sequel's eager_graph

### Defects
- 3 rescue blocks swallowing all exceptions (lines 34, 67, 122)
- No circuit_breaker on external API call at line 89

### Inventory
- Gemfile includes 'faraday' — not referenced anywhere in lib/

Priority: HIGH — Defects (3 silent rescues) + Waiting (N+1)
```

### 4. Proceed based on findings

For a targeted fix: `/rubysmithing:refactor lib/data/store.rb`

For a full audit report: `/rubysmithing:report lib/data/`

---

## Walkthrough C: Root-Cause Tracing

You have a Zeitwerk `NameError` or a recurring exception.

### 1. Paste the error

```
Getting this error:
NameError: uninitialized constant Pipeline::ContentParser

Stack trace:
  lib/pipeline/processor.rb:23:in `initialize'
  lib/pipeline/processor.rb:45:in `call'
  spec/pipeline/processor_spec.rb:12

How do I fix this?
```

`rubysmithing-analyse` activates with Root-Cause Tracing because of the stack trace.

### 2. What the agent does

1. **Reads the error** — identifies `Pipeline::ContentParser` as the unresolved constant
2. **Walks backward** — from `processor.rb:23` to the require/autoload chain
3. **Checks Zeitwerk** — verifies file path → constant mapping: `lib/pipeline/content_parser.rb` should map to `Pipeline::ContentParser`
4. **Finds origin** — either the file is missing, in the wrong path, or the loader is misconfigured
5. **Returns diagnosis with fix**

### 3. Sample output

```
## Root-Cause Tracing — NameError: Pipeline::ContentParser

### Call Chain (backward)
processor.rb:23 → references ContentParser
  → Zeitwerk expects: lib/pipeline/content_parser.rb → Pipeline::ContentParser

### Observed
File exists at: lib/pipeline/parsers/content_parser.rb
Zeitwerk mapping: lib/pipeline/parsers/content_parser.rb → Pipeline::Parsers::ContentParser

### Root Cause
File is in a subdirectory (parsers/) that creates a Parsers namespace, but the
code references ContentParser directly in the Pipeline namespace.

### Fix Options
1. Move file: lib/pipeline/parsers/content_parser.rb → lib/pipeline/content_parser.rb
2. Update reference: ContentParser → Pipeline::Parsers::ContentParser
3. Add explicit require (non-Zeitwerk projects only)
```

---

## Scratchpad Persistence

For multi-file analyses (directory targets), findings are written to a scratchpad:

```
.specs/scratchpad/<hex-id>.md
```

This file is automatically added to `.gitignore`. It contains structured findings keyed to `rubysmithing-refactor` pattern names, which downstream agents can reference directly.

The scratchpad path is passed automatically when you chain to `/rubysmithing:refactor` after an analysis.

---

## Related

- [Generate a Task Backlog](generate-backlog.md) — turn analysis findings into actionable tasks
- [Architecture: rubysmithing-analyse](../architecture.md)
- [Glossary: Gemba Walk, Muda, scratchpad](../glossary.md)
