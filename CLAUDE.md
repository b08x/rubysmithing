# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ruby Agent Skills v1.0 is a modular, convention-aware skill suite for Ruby development with AI assistance. It uses a hub-and-spoke architecture where the central `rubysmithing` skill routes requests to specialized sub-skills.

## No Build System

This repository contains skill definitions, not executable code. There are no tests, build scripts, Rakefiles, or CI pipelines. Specs are only generated on explicit request (TUI Update functions only). The one executable artifact is:

```bash
ruby rubysmithing-context/scripts/context_cache.rb list       # cached gems + staleness
ruby rubysmithing-context/scripts/context_cache.rb check <gem>  # fresh fetch (TTL-aware)
ruby rubysmithing-context/scripts/context_cache.rb stale <gem>  # stale fetch + warning block
ruby rubysmithing-context/scripts/context_cache.rb evict <gem>  # force re-resolution
```

## Hub-and-Spoke Skill Architecture

| Skill | Role |
|:---|:---|
| **rubysmithing** | Hub: routes tasks, handles POROs/Rake tasks/config wiring directly |
| **rubysmithing-context** | Prerequisite for all code-generating skills; verifies gem APIs via Context7 |
| **rubysmithing-scaffold** | Project initialization; generates full Rubysmith/Gemsmith skeletons |
| **rubysmithing-genai** | AI/NLP components: chatbots, RAG pipelines, DSPy modules, MCP servers |
| **rubysmithing-tui** | Terminal UI scaffolding with Charm/Bubble ecosystem |
| **rubysmithing-refactor** | Convention-targeted code fixes; runs Pre-Refactor Audit phase first |
| **rubysmithing-report** | QA assessment via SIFT Protocol V1.0 |
| **rubysmithing-yardoc** | YARD docs with semantic AST analysis and type inference |

**Routing order:** rubysmithing-context → rubysmithing (hub, Lite/Standard mode) → sub-skill → rubysmithing-report (QA).

Skills declare prerequisites in frontmatter:
```yaml
---
name: rubysmithing-yardoc
requires: [rubysmithing-context]
---
```

## Execution Modes

**Lite** — single-file ≤50 lines, pure stdlib, no architectural mandates. Triggered by: "quick script", "simple utility", "one-off", "stdlib only".

**Standard** (default) — full stack: async fibers, circuit_breaker, journald-logger, dry-schema, Zeitwerk compliance, `# frozen_string_literal: true` on every file. **Multi-file scaffold requests always use Standard Mode** regardless of per-file line count.

## Convention Detection

Canonical cascade lives in `rubysmithing/references/convention-detection.md` — all skills reference that file, never duplicate it.

1. `.rubocop.yml` present → RuboCop config
2. `standard` in Gemfile → StandardRB
3. `.rubysmith` / `rubysmith` gem → Rubysmith defaults
4. None → community idioms from `rubysmithing/references/conventions.md`

## Key Conventions (Standard Mode)

- Zeitwerk: file paths mirror module/class hierarchy exactly (`lib/app_name/data/processor.rb` → `AppName::Data::Processor`)
- `Struct.new(keyword_init: true)` for value objects
- Keyword args for 3+ parameter methods; guard clauses over nested conditionals
- `module_function` not `extend self`
- `Async { }` not `Thread.new`; `circuit_breaker` wrapping all external calls
- `journald-logger` for structured logging — never `puts`

## TUI Architecture (rubysmithing-tui)

The skill has two reference layers — keep them separate:

- **`references/tui-patterns.md`** — Bubble gem API syntax and component code examples. **Known debt:** contains stale `Lipgloss::Align::LEFT`, `BubbleTea::Program`, and `Lipgloss::Color.new` patterns that conflict with verified Context7 API. Do not use these as authoritative syntax; run rubysmithing-context for live verification.
- **`references/design-patterns.md`** — Architectural decisions: layout paradigm selector (7 paradigms), semantic color tokens, four-layer keyboard architecture (L0–L3), three-tier help system, focus management, command palette pattern, anti-pattern checklist, compatibility checklist.

**Skeleton** lives in `assets/skeleton/`. Copy and rename `app_name` → snake_case, `AppName` → CamelCase, `APP_NAME` → SCREAMING_SNAKE.

Verified Bubble gem API conventions (confirmed via Context7):
- Entry point: `Bubbletea.run(App.new)` — not `BubbleTea::Program.new`
- Quit: `Bubbletea.quit` — not `BubbleTea::Quit`
- Resize: `Bubbletea::WindowSizeMessage` — not `WindowSizeMsg`
- Key events: `message.to_s` returns `"up"`, `"j"`, `"ctrl+c"` etc. — match as strings
- Lipgloss colors: `.foreground("#HEXSTR")` — no `Lipgloss::Color.new` wrapper
- Lipgloss alignment: `:left`, `:top` symbols — not `Lipgloss::Align::LEFT`
- Bubbles::Help: `Bubbles::Key.binding(keys:, help:)` + `help.short_help_view(bindings)`

The `Components::Base` adapter module isolates all Bubble API calls. Screens and components never call Lipgloss/Bubbles directly — always through `Components::Base`.

## rubysmithing-context: Tiered Degradation

When Context7 is unavailable or rate-limited:
1. Serve stale SQLite cache with warning block injected into output
2. Retry using pre-mapped ID from `references/gem-registry.md`
3. Inject `[WARNING: Unverified API Syntax]` as last resort — never silently proceed

## Context7 MCP Integration

Use `mcp__plugin_context7_context7__resolve-library-id` then `mcp__plugin_context7_context7__query-docs`.

**Confirmed library IDs for this stack:**

| Gem | Library ID |
|:---|:---|
| bubbletea-ruby | `/marcoroth/bubbletea-ruby` |
| lipgloss-ruby | `/marcoroth/lipgloss-ruby` |
| bubbles-ruby | `/marcoroth/bubbles-ruby` |
| huh-ruby | `/marcoroth/huh-ruby` |
| harmonica-ruby | `/marcoroth/harmonica-ruby` |
| ntcharts-ruby | `/marcoroth/ntcharts-ruby` |
| glamour-ruby | `/marcoroth/glamour-ruby` |
| gum-ruby | `/marcoroth/gum-ruby` |
| bubblezone-ruby | `/marcoroth/bubblezone-ruby` |
| Rubysmith CLI | `/websites/alchemists_io_projects_rubysmith` |
| Gemsmith | `/bkuhlmann/gemsmith` |
| ClaudeBox | `/rchgrav/claudebox` |

## Creating or Modifying Skills

Each skill requires a `SKILL.md` with YAML frontmatter (`name`, `description`, optional `requires`), a `references/` directory, and clear activation triggers. Never use `README.md` for skill definitions. SKILL.md should stay under 500 lines; use `references/` files for anything larger and cite them by section from SKILL.md.

## Technology Stack

| Layer | Gems |
|:---|:---|
| **TUI** | bubbletea, lipgloss, bubbles, huh, gum, ntcharts, harmonica, glamour, bubblezone |
| **AI** | ruby_llm, dspy.rb, ruby_llm-mcp |
| **Async** | async, circuit_breaker |
| **Storage** | sequel, pgvector, dry-types, dry-schema |
| **Logic** | zeitwerk, dotenv, tty-config |
| **Logging** | journald-logger |
