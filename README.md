# Rubysmithing

Convention-aware Ruby development plugin for Claude Code. Provides an orchestrated agent suite, auto-activating skills, convention enforcement hooks, and slash commands — all backed by a hub-and-spoke architecture.

## Prerequisites

- **Context7 MCP** must be configured in your Claude Code environment. The `rubysmithing-context` skill and agent use it for live gem API resolution. Without it, the tiered degradation protocol (stale SQLite cache → WARNING blocks) activates automatically.

  Add to your Claude Code MCP settings:
  ```json
  { "context7": { "command": "npx", "args": ["-y", "@upstash/context7-mcp@latest"] } }
  ```

- **jq** must be installed for the PostToolUse convention hook (`apt install jq` / `brew install jq`). The hook degrades gracefully (no-op) if absent.

## Plugin Layout

```text
.claude-plugin/
  plugin.json           # Plugin manifest
  marketplace.json      # Marketplace distribution
agents/                        # 1 orchestrator + 8 domain sub-agents
  rubysmithing-orchestrator.md  # Thin router with direct pass-through
  rubysmithing-context.md       # Gem API verification (SQLite source of truth)
  rubysmithing-main.md          # Hub for POROs, Rake, config
  rubysmithing-scaffold.md      # Project init (rubysmith/gemsmith)
  rubysmithing-genai.md         # LLM, RAG, DSPy, MCP
  rubysmithing-tui.md           # Charm/Bubble TUI
  rubysmithing-refactor.md      # Convention fixes
  rubysmithing-report.md        # SIFT Protocol QA
  rubysmithing-yardoc.md        # YARD docs
commands/                      # 5 slash commands (/rubysmithing:*)
hooks/
  hooks.json                   # PostToolUse(Write|Edit) + Stop hooks
  scripts/check-ruby-conventions.sh
skills/
  rubysmithing/                # Hub: routes to sub-agents with delegation pattern
    references/
      convention-detection.md  # Canonical convention cascade
      conventions.md          # Community idiom patterns
  rubysmithing-context/       # Gem API verification (Context7 + SQLite)
    references/
      gem-registry.md         # Context7 IDs × architectural roles
    scripts/
      context_cache.rb         # SQLite cache CLI (list/check/stale/evict)
  rubysmithing-scaffold/      # rubysmith / gemsmith project init
  rubysmithing-genai/          # LLM, RAG, DSPy, MCP, embeddings
  rubysmithing-tui/           # Charm/Bubble TUI scaffolder
    references/
      tui-patterns.md          # Context7-verified Bubble gem API patterns
      design-patterns.md       # TUI architecture decisions
    assets/
      skeleton/               # Bubble app skeleton template
  rubysmithing-refactor/      # Convention-targeted refactoring
  rubysmithing-report/        # SIFT Protocol V1.0 QA assessment
  rubysmithing-yardoc/        # YARD docs with type inference
```

## Orchestrator Architecture

The orchestrator uses a **supervisor pattern** with two key improvements to prevent the "telephone game" problem:

### Direct Pass-Through

For complete, self-contained outputs, the orchestrator signals that sub-agent responses flow through unchanged:

| Agent | Pass-Through | Rationale |
|:------|:-------------|:----------|
| `rubysmithing-report` | Always true | SIFT reports are complete assessments |
| `rubysmithing-yardoc` | Always true | YARD docs are complete |
| `rubysmithing-scaffold` | After CLI exec | Project structure is complete |
| All others | false | Code generation needs orchestration |

### Routing Weights

For compound requests (TUI + GenAI, Refactor + Report), the orchestrator assigns effort weights:

| Request Type | Primary | Weight | Secondary | Weight |
|:-------------|:--------|:-------:|:-----------|:-------:|
| TUI + GenAI | genai | 0.6 | tui | 0.4 |
| Refactor + GenAI | refactor | 0.5 | genai | 0.5 |
| Scaffold + TUI | scaffold | 0.7 | tui | 0.3 |
| Refactor + Report | refactor | 0.6 | report | 0.4 |

## Context Agent: SQLite Source of Truth

The `rubysmithing-context` agent now uses **SQLite as the single source of truth**, not mental session tracking. This ensures cache state survives agent restarts:

1. **Check SQLite** → if fresh, return immediately
2. **Miss/Stale** → resolve via Context7
3. **Query docs** → extract method signatures
4. **Cache result** → persist to SQLite

This replaces the previous "track mentally" approach that lost state on agent restart.

## Slash Commands

| Command | Purpose |
|:--------|:--------|
| `/rubysmithing:context <gem>` | Check or warm the gem API cache |
| `/rubysmithing:report [path]` | Run SIFT QA assessment |
| `/rubysmithing:scaffold [name]` | Initialize new Ruby project |
| `/rubysmithing:refactor <file>` | Audit and refactor a file |
| `/rubysmithing:yardoc <file>` | Generate YARD documentation |

## Execution Modes

Two modes govern how skills operate. Selecting appropriately prevents over-engineering.

- **Lite Mode:** Single-file output ≤ ~50 lines, quick utilities, pure `stdlib`. Skips async, circuit_breaker, dry-schema for proportional effort. Note: multi-file scaffold requests always trigger Standard Mode.
- **Standard Mode:** Default for project-level code. Enforces async fibers, circuit_breaker, journald-logger, dry-schema validation, Zeitwerk compliance.

## Skill Dependencies

Each `SKILL.md` frontmatter declares a `requires:` field. This gives the executing agent a machine-readable dependency graph:

```yaml
---
name: rubysmithing-yardoc
requires: [rubysmithing-context]
---
```

Empty `requires: []` indicates no prerequisites.

## Skills Overview

### rubysmithing (The Hub)

Central entry point. Routes complex requests to sub-skills; handles POROs, Rake tasks, config wiring directly.

### rubysmithing-context

Resolves live gem documentation via Context7. Fails loudly—never silently. Degrades through a tiered protocol when Context7 becomes unreachable: stale SQLite cache with warning → pre-mapped gem-registry ID → `[WARNING: Unverified API Syntax]`.

**Cache CLI:**

```bash
ruby skills/rubysmithing-context/scripts/context_cache.rb list              # all cached gems + staleness status
ruby skills/rubysmithing-context/scripts/context_cache.rb check <gem>       # fresh fetch (respects TTL)
ruby skills/rubysmithing-context/scripts/context_cache.rb stale <gem>       # stale fetch + warning block
ruby skills/rubysmithing-context/scripts/context_cache.rb evict <gem>       # force re-resolution next use
```

### rubysmithing-report

QA assessment engine implementing SIFT Protocol V1.0. Includes "System Design Review" and "Tech Advisory" modes (700-char critical summary).

### rubysmithing-tui

Terminal UI scaffolder for the Ruby Charm/Bubble ecosystem. Includes verified API patterns (`references/tui-patterns.md`), architectural decisions (`references/design-patterns.md`), and a Bubble app skeleton template (`assets/skeleton/`).

### rubysmithing-genai

Scaffolds AI/NLP components—chat agents, RAG pipelines, DSPy modules, MCP servers.

### rubysmithing-refactor

Rewrites code to follow conventions. Uses a "Pre-Refactor Audit" phase before generating changes... ensuring transparency.

### rubysmithing-yardoc

YARD documentation generator with semantic analysis and type inference. When target files use non-stdlib gems, yardoc first activates rubysmithing-context to verify API shapes.

## Routing Workflow

The hub determines the execution path:

1. rubysmithing-context verifies gem APIs (session cache → SQLite cache → Context7 → tiered fallback).
2. Hub selects Lite or Standard mode. Multi-file tasks always use Standard Mode.
3. Sub-skills generate/refactor using verified API syntax.
4. rubysmithing-report provides final QA validation.

Convention detection follows the canonical cascade defined in `rubysmithing/references/convention-detection.md`... all skills reference this single source rather than duplicating logic.

## Stack Reference

Optimized for a terminal-native, high-resilience Ruby stack:

| Layer | Gems |
|-------|------|
| **TUI** | bubbletea, lipgloss, bubbles, huh, gum, ntcharts, bubblezone, glamour, harmonica |
| **AI** | ruby_llm, dspy.rb, ruby_llm-mcp |
| **Async** | async, circuit_breaker |
| **Storage** | sequel, pgvector |
| **Logic** | zeitwerk, dotenv, tty-config, dry-types, dry-schema |
| **Validation** | dry-schema, dry-types |
| **Logging** | journald-logger |
| **CLI** | drydock, highline (fallback) |

## Installation

Place these directories in the skills path. Reference `rubysmithing` as the primary hub; escalation to sub-skills happens automatically.
