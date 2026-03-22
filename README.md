# Ruby Agent Skills v1.0

A modular, convention-aware skill suite for Ruby development with AI assistance. Code generation, refactoring, quality assessment, terminal UI building, and GenAI orchestration... all orchestrated through a hub-and-spoke model.

## Architecture

```text
/
├── rubysmithing/              # Hub: routes tasks, handles simple Ruby gen
│   ├── SKILL.md
│   └── references/
│       ├── conventions.md          # Core Ruby/Stack idioms
│       └── convention-detection.md # Single source of truth for convention cascade
├── rubysmithing-context/      # Gem API verification (Context7)
│   ├── SKILL.md
│   ├── scripts/
│   │   └── context_cache.rb   # Persistent gem resolution + stale-cache fallback
│   └── references/
│       └── gem-registry.md    # Context7 IDs + last_verified dates
├── rubysmithing-genai/        # AI/NLP scaffolding & patterns
├── rubysmithing-refactor/     # Targeted convention fixes
├── rubysmithing-report/       # SIFT Protocol V1.0 QA assessments
├── rubysmithing-tui/          # Terminal UI building with adapter pattern
│   └── assets/skeleton/       # Standardized TUI project structure
└── rubysmithing-yardoc/       # YARD documentation generation with semantic analysis
```

## Execution Modes

Two modes govern how skills operate... selecting appropriately prevents over-engineering.

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
ruby scripts/context_cache.rb list              # all cached gems + staleness status
ruby scripts/context_cache.rb check <gem>       # fresh fetch (respects TTL)
ruby scripts/context_cache.rb stale <gem>       # stale fetch + warning block
ruby scripts/context_cache.rb evict <gem>       # force re-resolution next use
```

### rubysmithing-report

QA assessment engine implementing SIFT Protocol V1.0. Includes "System Design Review" and "Tech Advisory" modes (700-char critical summary).

### rubysmithing-tui

Terminal UI scaffolder for the Ruby Charm/Bubble ecosystem. Introduces a `Components::Base` adapter pattern to isolate UI code from Bubble gem API churn.

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
| **TUI** | bubbletea, lipgloss, bubbles, huh, gum, ntcharts |
| **AI** | ruby_llm, dspy.rb, ruby_llm-mcp |
| **Async** | async, circuit_breaker |
| **Storage** | sequel, pgvector, dry-types, dry-schema |
| **Logic** | zeitwerk, dotenv, tty-config |
| **Logging** | journald-logger |

## Installation

Place these directories in the skills path. Reference `rubysmithing` as the primary hub; escalation to sub-skills happens automatically.
