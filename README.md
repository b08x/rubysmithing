# Ruby Agent Skills v1.0

A modular, convention-aware skill suite for Ruby development with AI assistance. These skills handle code generation, refactoring, quality assessment, terminal UI building, and GenAI orchestration.

## Architecture

```text
/
├── rubysmithing/              # Hub skill: routes tasks, handles simple Ruby gen
│   ├── SKILL.md
│   └── references/
│       ├── conventions.md          # Core Ruby/Stack idioms
│       └── convention-detection.md # Canonical convention cascade (single source of truth)
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

## Core Execution Modes

All skills in the suite support two primary execution modes:

- **Lite Mode:** For single-file output ≤ ~50 lines, quick utilities, or pure `stdlib` tasks. Omits architectural mandates (async, circuit_breaker, dry-schema) for proportional effort. **Multi-file scaffold requests always use Standard Mode** regardless of per-file line count.
- **Standard Mode:** The default for project-level code. Enforces full stack conventions: `async` fibers, `circuit_breaker`, `journald-logger`, `dry-schema` validation, and Zeitwerk compliance.

## Skill Dependency Declarations

Each `SKILL.md` frontmatter now includes a `requires:` field listing prerequisite skills that must run before code generation:

```yaml
---
name: rubysmithing-yardoc
requires: [rubysmithing-context]
---
```

Skills with `requires: []` have no prerequisites. This gives the executing agent a machine-readable dependency graph rather than relying on prose-only instructions.

## Skills Overview

### rubysmithing (The Hub)

The central entry point. Routes complex requests to sub-skills and handles direct generation for POROs, Rake tasks, and config wiring.

- **What's new:** Hub skill moved to `rubysmithing/`. Lite vs. Standard mode detection.
- **Use cases:** "Create a service object", "Write a one-off cleanup script (Lite)", "Add a gem to Gemfile".

### rubysmithing-context

Resolves live gem documentation using Context7. Fails loudly — never silently. Degrades gracefully when Context7 is unreachable.

- **What's new:** Tiered degradation protocol for Context7 unavailability and rate limits: (1) serve stale SQLite cache with warning, (2) retry using pre-mapped gem-registry ID, (3) inject `[WARNING: Unverified API Syntax]` as last resort. Cache schema fixed to include `ttl_days` column; `fetch_stale` enables Tier 1 fallback without blocking generation. `gem-registry.md` now tracks `last_verified` dates per entry.
- **Use cases:** "How do I use `ruby_llm` with tool calling?", "What is the latest `bubbletea` update syntax?".

**Cache CLI:**
```bash
ruby scripts/context_cache.rb list              # all cached gems + staleness status
ruby scripts/context_cache.rb check <gem>       # fresh fetch (respects TTL)
ruby scripts/context_cache.rb stale <gem>       # stale fetch + warning block
ruby scripts/context_cache.rb evict <gem>       # force re-resolution next use
```

### rubysmithing-report

QA assessment engine implementing the **SIFT Protocol V1.0**.

- **What's new:** Specialized "System Design Review" and "Tech Advisory" (700-char critical summary) modes.
- **Use cases:** "Assess this codebase for convention violations", "System design review for this RAG architecture".

### rubysmithing-tui

Terminal UI scaffolder for the Ruby Charm/Bubble ecosystem.

- **What's new:** Introduces a `Components::Base` adapter pattern in every scaffold to isolate UI code from Bubble gem API churn.
- **Use cases:** "Build a file browser TUI", "Scaffold a RAG configuration panel".

### rubysmithing-genai

Scaffolds AI/NLP components (Chat agents, RAG pipelines, DSPy modules, MCP servers).

- **Use cases:** "Build a chatbot with streaming responses", "Implement a DSPy chain-of-thought module".

### rubysmithing-refactor

Rewrites code to follow conventions.

- **What's new:** Now uses a "Pre-Refactor Audit" phase before generating code to ensure transparency.
- **Use cases:** "Convert Thread.new to Async fiber", "Fix Zeitwerk compliance issues".

### rubysmithing-yardoc

YARD documentation generator with semantic analysis and type inference.

- **What's new:** Now registered in the hub's companion skills table. Added `requires: [rubysmithing-context]` — when the target file uses non-stdlib gems, yardoc activates `rubysmithing-context` first to ensure type annotations reflect verified API shapes rather than training-data guesses. Step 0 prerequisite check added to `SKILL.md`.
- **Use cases:** "Generate YARD docs for this file", "Add comprehensive documentation", "Document this Ruby class with examples".

## Skill Routing & Workflow

The hub automatically determines the best path:

1. **rubysmithing-context** verifies gem APIs (checks session cache → SQLite cache → Context7 → tiered fallback).
2. **rubysmithing** (Hub) chooses **Lite** or **Standard** mode. Multi-file tasks always use Standard Mode.
3. Sub-skills generate or refactor components using verified API syntax.
4. **rubysmithing-report** provides the final QA validation.

Convention detection follows the canonical cascade in `rubysmithing/references/convention-detection.md` — all skills reference this single file rather than each defining the cascade independently.

## Project Stack Reference

The suite is optimized for a terminal-native, high-resilience Ruby stack:

| Layer | Gems |
|-------|------|
| **TUI** | bubbletea, lipgloss, bubbles, huh, gum, ntcharts |
| **AI** | ruby_llm, dspy.rb, ruby_llm-mcp |
| **Async** | async, circuit_breaker |
| **Storage** | sequel, pgvector, dry-types, dry-schema |
| **Logic** | zeitwerk, dotenv, tty-config |
| **Logging** | journald-logger |

## Installation

Place these directories in your skills path. Reference `rubysmithing` as the primary hub; it will escalate to sub-skills as needed.
