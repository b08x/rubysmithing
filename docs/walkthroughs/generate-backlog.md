# Walkthrough: Generate a Task Backlog

Turn `rubysmithing-analyse` findings into a prioritized, actionable development backlog. This walkthrough covers the full flow from analysis through scratchpad to structured task list.

---

## Overview

The backlog generation flow is:

```
rubysmithing-analyse
     │
     ▼
.specs/scratchpad/<hex-id>.md    ← structured findings, keyed to refactor patterns
     │
     ▼
Backlog extraction                ← convert findings to tasks, assign priorities
     │
     ▼
GitHub issues / task file         ← output in your preferred format
```

There is no single "generate backlog" command — you combine `rubysmithing-analyse` with a follow-up request to extract tasks from the findings.

---

## Step 1: Run a Full Codebase Analysis

Target a directory to generate a scratchpad with findings across all files:

```
Muda analysis of lib/ — find all waste, dead code, and defects
```

For broader coverage combining multiple methods:

```
Gemba walk lib/ — document what's actually happening vs what's documented,
then flag waste and any recurring issues
```

`rubysmithing-analyse` selects the appropriate method (or combines them) and writes findings to `.specs/scratchpad/<hex-id>.md`.

At the end of the analysis, the agent reports the scratchpad path:

```
Analysis complete. Findings written to:
.specs/scratchpad/a3f9c1e2.md
```

---

## Step 2: Extract Tasks from the Scratchpad

Follow up immediately:

```
From those findings, generate a prioritized task backlog
```

Or with more specific framing:

```
From those findings, create a backlog of GitHub issues —
group by priority (critical/high/medium), include the file:line reference
for each issue
```

The agent reads the scratchpad and produces structured task output.

---

## Step 3: Task Output Formats

### Option A: Markdown Task List

```
Generate a backlog as a markdown checklist from those findings
```

Sample output:

```markdown
## Critical

- [ ] Fix silent rescue at lib/pipeline/processor.rb:89 — currently swallows all
      exceptions and returns nil, hiding failures from callers
      Pattern: error_hierarchy
- [ ] Add circuit_breaker to external API call at lib/pipeline/processor.rb:103
      Pattern: circuit_breaker

## High

- [ ] Remove dead method DataStore#legacy_fetch (lib/data/store.rb:34) — called nowhere
      Pattern: dead_code
- [ ] Fix N+1 query in lib/data/store.rb:78 — add .includes(:author)
      Pattern: query_optimization

## Medium

- [ ] Add frozen_string_literal to lib/pipeline/processor.rb, lib/data/store.rb (5 files)
      Pattern: frozen_string_literal
- [ ] Remove Gemfile dependency 'faraday' — not referenced in lib/
      Pattern: inventory_waste
```

### Option B: GitHub Issues

```
From those findings, generate GitHub issue bodies — one per critical or high item,
with reproduction steps and suggested fix
```

Sample issue body:

```markdown
**Title:** Fix silent rescue in Pipeline::Processor

**Description:**
`Pipeline::Processor#call` contains a bare rescue block at line 89 that swallows all
exceptions and returns nil. This hides failures from callers and makes debugging
extremely difficult.

**Location:** lib/pipeline/processor.rb:89

**Steps to reproduce:**
1. Trigger any exception inside the rescue block
2. Observe that nil is returned with no log output

**Suggested fix:**
Replace with explicit error hierarchy using `raise` after logging,
or rescue specific exception types and re-raise unhandled ones.

**Pattern:** error_hierarchy
```

### Option C: Structured YAML / JSON

```
From those findings, generate a YAML task list with fields:
id, file, line, priority, pattern, description
```

---

## Step 4: Prioritization Logic

When you ask for prioritization, the agent applies this logic derived from the analysis:

| Priority | Criteria |
|:---------|:---------|
| **Critical** | Silent failures (swallowed exceptions, nil returns), security issues, data integrity risks |
| **High** | Performance problems (N+1, missing indexes, sync I/O in hot paths), dead external API calls without circuit breaker |
| **Medium** | Dead code, unused dependencies, missing frozen_string_literal, logging conventions |
| **Low** | Documentation gaps, naming consistency, speculative abstractions that work but add complexity |

You can override: "treat all Zeitwerk compliance issues as high priority."

---

## Step 5: Connect to Refactoring

After generating the backlog, you can chain directly to refactoring for any task:

```
Fix the critical items from that backlog — start with the silent rescue
```

The orchestrator has access to the scratchpad path from the analysis and passes it to `rubysmithing-refactor`, which reads the findings directly rather than re-analysing.

For a single-file fix:

```
/rubysmithing:refactor lib/pipeline/processor.rb
```

---

## Full Session Example

```
User: Muda analysis of lib/ — find waste, defects, and dead code

[rubysmithing-analyse runs, writes .specs/scratchpad/a3f9c1e2.md]

User: From those findings, generate a prioritized task backlog as markdown

[Agent reads scratchpad, outputs markdown checklist]

User: Fix the two critical items

[rubysmithing-refactor reads scratchpad, applies fixes to the two flagged files]

User: /rubysmithing:report lib/

[rubysmithing-report runs SIFT Protocol assessment on the updated files]
```

---

## Tips

- **Run analysis on the whole directory**, not file-by-file, to get a complete scratchpad with cross-file patterns visible
- **Ask for priority grouping** explicitly — the agent doesn't group by default unless asked
- **Include file:line** in your task format request — it makes tickets self-contained
- **Chain immediately** to refactor or report after generating the backlog — the scratchpad is temporary and session-specific

---

## Related

- [Analyse a Codebase](analyse-codebase.md) — the analysis methods in detail
- [Architecture: SADD scratchpad persistence](../architecture.md#sadd-integration)
- [Glossary: scratchpad, Muda, SIFT Protocol](../glossary.md)
