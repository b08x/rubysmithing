# Overview

## What Is Rubysmithing?

Rubysmithing is a Claude Code plugin providing a convention-aware Ruby development suite. It turns natural-language requests into idiomatic Ruby code calibrated to your project's existing style conventions — without requiring you to repeat yourself about RuboCop, Zeitwerk compliance, or gem API signatures.

The plugin is optimized for a specific, opinionated Ruby stack:

| Layer | Gems |
|:------|:-----|
| **TUI** | bubbletea, lipgloss, bubbles, huh, gum, ntcharts, bubblezone, glamour, harmonica |
| **AI** | ruby_llm, dspy.rb, ruby_llm-mcp |
| **Async** | async, circuit_breaker |
| **Storage** | sequel, pgvector, dry-types, dry-schema |
| **Logic** | zeitwerk, dotenv, tty-config |
| **Logging** | journald-logger |

It works on any Ruby project but delivers the most value when you're building within this stack.

---

## Why It Exists

Generating Ruby code with an AI assistant that doesn't know your project's conventions produces code that fails RuboCop, breaks Zeitwerk autoloading, uses deprecated gem APIs, or adopts patterns inconsistent with your codebase. Fixing that output costs more time than writing it manually.

Rubysmithing addresses this in three ways:

1. **Convention detection** — reads `.rubocop.yml`, `standard` in Gemfile, or `.rubysmith` config at the start of every task, so generated code matches your project's style target without being told
2. **Live gem API verification** — fetches current documentation via Context7 MCP before generating any library-specific code, preventing generation against stale or imagined APIs
3. **Specialized agents** — routes each task to the agent best suited for it (scaffolding, TUI, GenAI, refactoring, analysis) rather than using one general-purpose agent for everything

---

## Features

### Auto-activating Skills

Nine skill modules trigger automatically on natural-language phrases. Say "scaffold a new gem" and `rubysmithing-scaffold` activates. Say "analyse this for dead code" and `rubysmithing-analyse` runs Muda analysis. No slash command required for most tasks.

### Orchestrated Agent Suite

A thin routing orchestrator (`rubysmithing-orchestrator`) analyzes your request, detects conventions, determines which agents to invoke and in what order, and dispatches them — sequentially for dependent sub-tasks, in parallel for independent ones.

### Convention Enforcement Hooks

A PostToolUse hook runs `check-ruby-conventions.sh` after every `.rb` file write. It validates frozen_string_literal, module/class naming, and style conventions, injecting correction prompts inline when violations are found.

### Gem API Verification with Tiered Degradation

`rubysmithing-context` resolves live gem documentation via Context7 MCP and caches results to SQLite. When Context7 is unavailable, it falls through a tiered protocol: stale cache → pre-mapped gem-registry ID → explicit WARNING block injected into output. It never silently generates against unverified APIs.

### TUI Scaffolding

`rubysmithing-tui` generates full terminal UI skeletons for the Charm/Bubble Ruby ecosystem using verified API patterns. Includes a copy-paste skeleton template (`assets/skeleton/`) and architectural decision guides for layout paradigms, keyboard management, and focus handling.

### SIFT QA Protocol

`rubysmithing-report` implements SIFT Protocol V1.0 — a structured quality assessment with System Design Review and Tech Advisory modes. For 3+ file reviews, a meta-judge agent appends a scored verification footer (pass threshold: 3.5/5.0).

### SADD Integration

Four Subagent-Driven Development patterns are built into the plugin: the meta-judge → judge evaluation pipeline, the do-and-judge retry loop in `rubysmithing-refactor`, SIFT + meta-judge in `rubysmithing-report`, and scratchpad persistence in `rubysmithing-analyse`.

---

## Execution Modes

Two modes govern code generation. The right mode prevents over-engineering.

| Mode | When | What It Applies |
|:-----|:-----|:----------------|
| **Lite** | Single-file ≤ ~50 lines, pure stdlib | Minimal stdlib code, no async/circuit_breaker/dry-schema |
| **Standard** | All other tasks (default) | Full stack: async, circuit_breaker, dry-schema, journald-logger, Zeitwerk, frozen_string_literal |

Multi-file scaffold requests always use Standard Mode regardless of individual file line count.

---

## Scope

Rubysmithing handles:

- Generating Ruby classes, modules, Rake tasks, config wiring, data pipelines, POROs, error hierarchies, workers
- Scaffolding new Ruby projects and publishable gems
- Building terminal UI applications with the Charm/Bubble ecosystem
- Generating LLM, RAG, DSPy, MCP server, and embedding components
- Refactoring toward convention compliance
- Analysing codebases for waste, root causes, and design problems
- Generating YARD documentation with semantic type inference
- Running SIFT QA assessments

It does **not** handle: non-Ruby code, web frontend, deployment infrastructure, or general project management.

---

## Next Steps

- [Getting Started](getting-started.md) — install prerequisites and make your first request
- [Architecture](architecture.md) — how the hub-and-spoke system works
- [Walkthroughs](walkthroughs/README.md) — step-by-step examples for common scenarios
