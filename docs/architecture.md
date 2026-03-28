# Architecture

## System Overview

Rubysmithing uses a hub-and-spoke architecture with a thin routing orchestrator at the center. The orchestrator never implements — it routes. Domain sub-agents handle all code generation, analysis, and assessment.

```
User request
     │
     ▼
rubysmithing-orchestrator          ← Convention detection + routing
     │
     ├── rubysmithing-context?     ← Gem API verification (if non-stdlib gems)
     │        │
     ├────────┘
     │
     ├── rubysmithing-scaffold     ← New projects, rubysmith/gemsmith CLI
     ├── rubysmithing (main)       ← POROs, Rake, config, pipelines
     ├── rubysmithing-genai        ← LLM, RAG, DSPy, MCP, embeddings
     ├── rubysmithing-tui          ← Charm/Bubble TUI scaffolding
     ├── rubysmithing-refactor     ← Convention fixes, Pre-Refactor Audit
     ├── rubysmithing-report       ← SIFT Protocol V1.0 QA
     ├── rubysmithing-yardoc       ← YARD documentation
     └── rubysmithing-analyse      ← Gemba Walk, Muda, Root-Cause, Five Whys

[Internal — not user-invocable]
     ├── rubysmithing-meta-judge   ← Generates YAML evaluation specs (SADD)
     └── rubysmithing-judge        ← Applies eval specs with evidence (SADD)
```

---

## Component Descriptions

### Orchestrator

`skills/rubysmithing/agents/rubysmithing-orchestrator.md` — Entry point for all requests. Responsibilities:

1. **Convention scan** — checks for `.rubocop.yml`, `standard` in Gemfile, `.rubysmith` file
2. **Gem dependency detection** — flags non-stdlib gems to trigger `rubysmithing-context`
3. **Routing decision** — maps request to the appropriate sub-agent(s) via routing table
4. **Dispatch order** — determines parallel vs sequential execution
5. **Weight assignment** — for compound requests, dynamically allocates effort proportions

The orchestrator uses tools: Read, Grep, Glob. It does not write files.

### rubysmithing-context

Prerequisite for all gem-specific code generation. Resolves current API signatures via Context7 MCP and persists results to SQLite at `skills/rubysmithing-context/scripts/context_cache.rb`.

Tiered degradation when Context7 is unavailable:

```
Context7 MCP request
       │
  Success? ── yes ──▶ Serve live docs + cache result
       │
      no
       │
  Stale cache? ── yes ──▶ Serve stale docs + inject WARNING block
       │
      no
       │
  Gem-registry ID? ── yes ──▶ Retry Context7 with mapped ID
       │
      no
       ▼
  Inject [WARNING: Unverified API Syntax]
  Never silently proceed
```

Cache CLI (run from within this repo):

```bash
ruby skills/rubysmithing-context/scripts/context_cache.rb list         # all cached gems + staleness
ruby skills/rubysmithing-context/scripts/context_cache.rb check <gem>  # fresh fetch (TTL-aware)
ruby skills/rubysmithing-context/scripts/context_cache.rb stale <gem>  # force stale + warning
ruby skills/rubysmithing-context/scripts/context_cache.rb evict <gem>  # force re-resolution
```

### Domain Agents

| Agent | Scope | Context needed? |
|:------|:------|:----------------|
| `rubysmithing-scaffold` | `rubysmith`/`gemsmith` CLI execution + post-scaffold hardening | No |
| `rubysmithing` (main) | POROs, Rake tasks, config wiring, data pipelines, boot layer | If gem-specific code |
| `rubysmithing-genai` | LLM clients, RAG pipelines, DSPy modules, MCP servers, embeddings | Yes |
| `rubysmithing-tui` | Charm/Bubble TUI scaffolding, screen + component generation | Yes |
| `rubysmithing-refactor` | Convention fixes, Zeitwerk compliance, Pre-Refactor Audit | No |
| `rubysmithing-report` | SIFT Protocol V1.0 assessment, System Design Review, Tech Advisory | No |
| `rubysmithing-yardoc` | YARD docs with AST analysis and type inference | If non-stdlib gems |
| `rubysmithing-analyse` | Gemba Walk, Muda, Root-Cause Tracing, Five Whys | No |

### Evaluation Agents (Internal)

`rubysmithing-meta-judge` and `rubysmithing-judge` are infrastructure agents called internally by `rubysmithing-refactor` and `rubysmithing-report`. They are never routed to directly and cannot be invoked by users.

- **meta-judge** — generates a Ruby-calibrated YAML evaluation spec: 5 rubric dimensions, 10 checklist items, two modes (`sift_report`, `refactor_judge`)
- **judge** — applies the spec to artifacts with file:line evidence citations; default score 2, pass threshold 3.5/5.0

---

## Routing Logic

### Routing Table

| Request Signal | Primary Sub-Agent |
|:---------------|:-----------------|
| New project, scaffold, rubysmith, gemsmith | `rubysmithing-scaffold` |
| LLM, RAG, chatbot, DSPy, MCP, embeddings, NLP | `rubysmithing-genai` |
| TUI, BubbleTea, Lipgloss, Huh, Gum, Bubbles | `rubysmithing-tui` |
| Refactor, fix conventions, RuboCop violations | `rubysmithing-refactor` |
| Debug, trace, root cause, waste, dead code, muda, gemba | `rubysmithing-analyse` |
| Assess, SIFT, QA, review, code quality | `rubysmithing-report` |
| YARD, @param, @return, yardoc, document | `rubysmithing-yardoc` |
| Classes, modules, Rake, config, POROs, pipelines | `rubysmithing` (main) |

### Routing Order

```
orchestrator → rubysmithing-context (if gems) → domain agent(s) → [optional] rubysmithing-report
```

### Direct Pass-Through

Three agents produce self-contained outputs. The orchestrator passes these through unchanged:

| Agent | Condition |
|:------|:----------|
| `rubysmithing-report` | Always |
| `rubysmithing-yardoc` | Always |
| `rubysmithing-scaffold` | After CLI execution |

### Parallel vs Sequential Dispatch

| Request | Dispatch | Reason |
|:--------|:---------|:-------|
| GenAI module + TUI dashboard | Parallel | Different file trees, different gem APIs |
| Analyse + Refactor | Sequential | Refactor depends on analyse findings |
| Refactor + Report | Sequential | Report evaluates refactored output |
| Context + any code-gen | Sequential | Context must complete first |

---

## Skills System

Skills live in `skills/{name}/SKILL.md`. They define activation triggers and execution instructions for the corresponding agent. The system discovers skills via frontmatter parsing — only `name:` and `description:` are loaded at discovery time; full content loads on activation.

### Supported Frontmatter Fields

```yaml
---
name: skill-name
description: One-line activation trigger and scope description
color: red    # optional UI hint
---
```

`requires:` is **not** a supported field — context prerequisites are documented in the skill body text.

### Skill Layout

```
skills/{name}/
├── SKILL.md          # Frontmatter + execution instructions
├── references/       # Reference documents, patterns, registries
├── scripts/          # Executable scripts (Ruby, shell)
└── assets/           # Static files, templates, skeletons
```

---

## Convention Detection

All skills use a single canonical cascade (documented in `skills/rubysmithing/references/convention-detection.md`):

```
1. .rubocop.yml present          → RuboCop config
2. 'standard' in Gemfile         → StandardRB
3. .rubysmith / rubysmith gem    → Rubysmith defaults
4. None                          → Community idioms (conventions.md)
```

This detection runs at the start of every session. The detected target is passed to all domain agents in the routing message.

---

## Hooks

### PostToolUse Hook

Fires on every Write or Edit tool call on `.rb` files:

```
.rb file written/edited
        │
        ▼
check-ruby-conventions.sh
        │
  Requires jq? ── absent ──▶ No-op (graceful degradation)
        │
  Violations? ── yes ──▶ Inject correction prompt
        │
       no
        ▼
  Pass
```

Validates: `frozen_string_literal`, module/class naming, `module_function` vs `extend self`, `Async { }` vs `Thread.new`, `journald-logger` vs `puts`.

### Stop Hook

After any session that produced `.rb` files, injects a prompt suggesting the user run `/rubysmithing:report` for SIFT QA assessment. Omitted for explanation-only or research sessions.

---

## SADD Integration

Four patterns from the Subagent-Driven Development framework are built into existing agents:

| Pattern | Location | Trigger |
|:--------|:---------|:--------|
| **Meta-judge → Judge pipeline** | `rubysmithing-report` | 3+ file SIFT or explicit score request |
| **Do-and-judge retry loop** | `rubysmithing-refactor` | 1+ CRITICAL audit items, 3+ files, or user request |
| **Scratchpad persistence** | `rubysmithing-analyse` | Directory/multi-file targets, downstream handoff |
| **Parallel dispatch** | `rubysmithing-orchestrator` | Independent compound sub-tasks |

---

## File Layout

```
.claude-plugin/
  plugin.json            # Manifest: metadata + explicit agent paths
skills/
  rubysmithing/          # Hub
    agents/              # rubysmithing-orchestrator.md, rubysmithing-main.md
    hooks/               # Convention enforcement (plugin-wide)
      hooks.json         # PostToolUse(Write|Edit) + Stop hooks
      scripts/
        check-ruby-conventions.sh
    references/
      convention-detection.md   # Canonical detection cascade
      conventions.md            # Community idiom fallback patterns
  rubysmithing-context/
    agents/              # rubysmithing-context.md
    commands/            # context.md
    references/
      gem-registry.md           # Context7 IDs × architectural roles (225 entries)
    scripts/
      context_cache.rb          # CLI: list/check/stale/evict
  rubysmithing-tui/
    agents/              # rubysmithing-tui.md
    references/
      tui-patterns.md           # Context7-verified Bubble gem API patterns
      design-patterns.md        # Layout paradigms, anti-patterns, keyboard arch
    assets/skeleton/            # Bubble app template
  rubysmithing-scaffold/
  rubysmithing-genai/
  rubysmithing-refactor/
  rubysmithing-report/
  rubysmithing-yardoc/
  rubysmithing-analyse/
    references/
      analyse-methods.md        # Method templates, Ruby instrumentation idioms
    scripts/
      create-scratchpad.sh      # Persists findings to .specs/scratchpad/<hex-id>.md
docker/                  # Routing test harness (dev artifact)
Gemfile                  # Plugin's own dependencies (RSpec, RuboCop, Zeitwerk, etc.)
```

---

## Related

- [Overview](overview.md) — what the plugin does and why
- [Getting Started](getting-started.md) — prerequisites and installation
- [ADR Index](adr/README.md) — architecture decisions
- [Glossary](glossary.md) — term definitions
