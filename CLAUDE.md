# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Rubysmithing v1.0 is a Claude Code plugin providing a convention-aware Ruby development suite. It uses an orchestrator/sub-agent architecture backed by a hub-and-spoke skill system. The plugin manifest lives at `.claude-plugin/plugin.json`.

## Plugin Layout

```
.claude-plugin/plugin.json   # Plugin manifest (12 agents registered)
agents/                      # Orchestrator + 9 domain agents + 2 evaluation agents
commands/                    # 5 user-invocable slash commands
hooks/                       # Convention enforcement hooks
  hooks.json                 # PostToolUse(.rb) + Stop hooks
  scripts/                   # check-ruby-conventions.sh
skills/                      # 9 auto-discovering skill definitions
  rubysmithing/              # Hub: POROs, Rake, config, pipelines
  rubysmithing-context/      # Gem API verification (Context7 + SQLite)
  rubysmithing-scaffold/     # rubysmith / gemsmith project init
  rubysmithing-genai/        # LLM, RAG, DSPy, MCP, embeddings
  rubysmithing-tui/          # Charm/Bubble TUI scaffolder
  rubysmithing-refactor/     # Convention-targeted refactoring
  rubysmithing-report/       # SIFT Protocol V1.0 QA assessment
  rubysmithing-yardoc/       # YARD docs with type inference
  rubysmithing-analyse/      # Gemba Walk, Muda, Root-Cause, Five Whys
```

## Prerequisites

- **Context7 MCP** — required by `rubysmithing-context` for live gem API resolution. Add to Claude Code MCP settings:
  ```json
  { "context7": { "command": "npx", "args": ["-y", "@upstash/context7-mcp@latest"] } }
  ```
  Without it, tiered degradation activates automatically (stale cache → WARNING blocks).

- **jq** — required by the PostToolUse convention hook. Install via `apt install jq` or `brew install jq`. The hook degrades gracefully (no-op) if absent.

## No Build System

This repository contains skill and agent definitions, not executable code. No tests, build scripts, Rakefiles, or CI pipelines. Specs are only generated on explicit request (TUI Update functions only). The two executable artifacts are:

```bash
# Gem API cache management
ruby skills/rubysmithing-context/scripts/context_cache.rb list         # cached gems + staleness
ruby skills/rubysmithing-context/scripts/context_cache.rb check <gem>  # fresh fetch (TTL-aware)
ruby skills/rubysmithing-context/scripts/context_cache.rb stale <gem>  # stale fetch + warning block
ruby skills/rubysmithing-context/scripts/context_cache.rb evict <gem>  # force re-resolution

# SADD scratchpad (run from within the user's project repo, not this repo)
bash skills/rubysmithing-analyse/scripts/create-scratchpad.sh          # creates .specs/scratchpad/<hex-id>.md
```

## Hooks Behavior

- **PostToolUse (Write|Edit)** — fires `check-ruby-conventions.sh` on every file write/edit. The script filters to `.rb` files and validates conventions against the detected target (RuboCop / StandardRB / community idioms). Requires `jq`.
- **Stop** — after any session that produced `.rb` files, injects a prompt suggesting the user run `/rubysmithing:report` for SIFT QA assessment. Omitted for explanation-only or research sessions.

## Orchestrator / Sub-Agent Architecture

The plugin uses a thin routing orchestrator (`agents/rubysmithing-orchestrator.md`) that delegates to domain sub-agents. Each sub-agent loads its corresponding SKILL.md as its primary reference.

| Agent | Role |
|:---|:---|
| **rubysmithing-orchestrator** | Thin router: convention detection + parallel/sequential dispatch |
| **rubysmithing-context** | Prerequisite: gem API verification via Context7 + SQLite cache |
| **rubysmithing-main** | POROs, Rake tasks, config wiring, data pipelines |
| **rubysmithing-scaffold** | Project initialization via rubysmith / gemsmith CLI |
| **rubysmithing-genai** | LLM, RAG, DSPy, MCP servers, embeddings, NLP |
| **rubysmithing-tui** | Charm/Bubble TUI scaffolding |
| **rubysmithing-refactor** | Convention-targeted refactoring + Pre-Refactor Audit + do-and-judge loop |
| **rubysmithing-report** | SIFT Protocol V1.0 QA assessment + meta-judge verification |
| **rubysmithing-yardoc** | YARD docs with semantic AST analysis and type inference |
| **rubysmithing-analyse** | Gemba Walk, Muda, Root-Cause Tracing, Five Whys — diagnose before fixing |
| **rubysmithing-meta-judge** | SADD: generates Ruby-calibrated YAML evaluation specs (infrastructure only) |
| **rubysmithing-judge** | SADD: applies eval specs with file:line evidence citations (infrastructure only) |

**Routing table (from orchestrator):**

| User Intent | Sub-Agent | Context needed? |
|:---|:---|:---|
| New project, scaffold, rubysmith, gemsmith | `rubysmithing-scaffold` | No |
| LLM, RAG, chatbot, DSPy, MCP, embeddings, NLP | `rubysmithing-genai` | Yes |
| TUI, BubbleTea, Lipgloss, Huh, Gum, Bubbles | `rubysmithing-tui` | Yes |
| Refactor, fix conventions, RuboCop violations | `rubysmithing-refactor` | No |
| Debug, root cause, waste analysis, dead code, muda, gemba | `rubysmithing-analyse` | No |
| Assess, SIFT, QA, review, code quality | `rubysmithing-report` | No |
| YARD, documentation, @param, @return | `rubysmithing-yardoc` | If non-stdlib gems present |
| Classes, modules, Rake, config, POROs, pipelines | `rubysmithing` (main) | If gem-specific code |

**Routing order:** orchestrator → rubysmithing-context (if gems) → domain agent(s) → (optional) rubysmithing-report

**Parallel dispatch:** When compound sub-tasks are independent (no shared files, no dependency order), the orchestrator dispatches them simultaneously. `rubysmithing-meta-judge` and `rubysmithing-judge` are never routed to directly — they are called internally by `rubysmithing-refactor` and `rubysmithing-report`.

## Slash Commands

| Command | Purpose |
|:---|:---|
| `/rubysmithing:context <gem>` | Check/warm the gem API cache |
| `/rubysmithing:report [path]` | Run SIFT QA assessment |
| `/rubysmithing:scaffold [name]` | Initialize new Ruby project |
| `/rubysmithing:refactor <file>` | Audit and refactor a file |
| `/rubysmithing:yardoc <file>` | Generate YARD documentation |

## Hub-and-Spoke Skill Architecture

Skills auto-activate on trigger phrases. Each skill is paired with a corresponding agent for autonomous multi-step execution.

| Skill | Role |
|:---|:---|
| **rubysmithing** | Hub: routes tasks, handles POROs/Rake tasks/config wiring directly |
| **rubysmithing-context** | Prerequisite for all code-generating skills; verifies gem APIs via Context7 |
| **rubysmithing-scaffold** | Project initialization; generates full Rubysmith/Gemsmith skeletons |
| **rubysmithing-genai** | AI/NLP components: chatbots, RAG pipelines, DSPy modules, MCP servers |
| **rubysmithing-tui** | Terminal UI scaffolding with Charm/Bubble ecosystem |
| **rubysmithing-refactor** | Convention-targeted code fixes; Pre-Refactor Audit + do-and-judge verification |
| **rubysmithing-report** | QA assessment via SIFT Protocol V1.0; optional meta-judge verification footer |
| **rubysmithing-yardoc** | YARD docs with semantic AST analysis and type inference |
| **rubysmithing-analyse** | Gemba Walk, Muda, Root-Cause Tracing, Five Whys; findings keyed to refactor-patterns |

Context prerequisites are described in each skill's body text, not frontmatter. The `requires:` field is not part of the supported skill schema.

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

- **`references/tui-patterns.md`** — Bubble gem API syntax and component code examples. Includes Migration Guide (lines 9-16) mapping deprecated patterns to verified Context7 equivalents. All code examples use verified syntax.
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

## SADD Integration

The plugin integrates four patterns from the SADD (Subagent-Driven Development) framework. These are built into existing agents — no separate SADD skill or command exists.

**Meta-judge → Judge pipeline** (`rubysmithing-meta-judge` + `rubysmithing-judge`):
- `rubysmithing-meta-judge` generates a Ruby-calibrated YAML evaluation spec (5 rubric dimensions + 10 checklist items). Two modes: `sift_report` and `refactor_judge`.
- `rubysmithing-judge` applies the spec to artifacts with file:line evidence. Default score is 2; scores above 2 require cited evidence. Pass threshold: 3.5/5.0.
- Neither agent is user-invocable; they are called internally by `rubysmithing-refactor` and `rubysmithing-report`.

**Do-and-judge retry loop** (in `rubysmithing-refactor`): Activates when the pre-refactor audit has 1+ CRITICAL items, the refactor spans 3+ files, or the user requests verification. Meta-judge and refactor run in parallel; judge evaluates the output; one retry allowed on FAIL.

**SIFT + meta-judge** (in `rubysmithing-report`): For Full SIFT Report on 3+ files, meta-judge and SIFT analysis run in parallel, then judge appends a scored verification footer. SIFT is always the primary output.

**Scratchpad persistence** (in `rubysmithing-analyse`): Multi-file analyses write findings to `.specs/scratchpad/<hex-id>.md` in the user's project git root (not this repo). The scratchpad path is passed to downstream agents (`rubysmithing-refactor`, `rubysmithing-report`) for direct reference. `.specs/scratchpad/` is auto-registered in the project's `.gitignore`.

## Security

### Prompt Injection Hardening

Agent `description:` fields in frontmatter use `<example>` XML tags — this is the Claude Code platform convention for routing examples and is acceptable for **developer-authored static content**.

The following rules apply when dynamic content is involved:

- **Never embed user-controlled input** in agent `description:` fields or system prompt sections. Agent descriptions are loaded at routing time; injected content here can alter agent selection behavior.
- **Never write user-provided strings directly to `.md` agent files** without stripping angle brackets (`<`, `>`). If any workflow generates or modifies agent files programmatically, sanitize before write.
- **Skill YAML frontmatter** (`name:`, `description:`) must never contain angle brackets sourced from user input. The `description:` field is parsed as YAML and injected into context — an unescaped `<` can begin a rogue XML instruction.
- **The convention hook** (`hooks/scripts/check-ruby-conventions.sh`) validates `.rb` files only. It does not validate agent or skill `.md` files. Do not rely on it for injection prevention in non-Ruby artifacts.

When in doubt: static developer-authored XML tags in frontmatter are safe; user-derived content in any frontmatter field is not.

### Error Contract

All sub-agents use the shared error schema at `skills/rubysmithing/references/error-contract.md`. The orchestrator uses `[AGENT ERROR]` blocks to make intelligent recovery decisions. Never return bare failure strings from sub-agents.

## Creating or Modifying Skills

Each skill requires a `SKILL.md` with YAML frontmatter (`name` and `description` — the only supported fields), a `references/` directory, and clear activation triggers. Never use `README.md` for skill definitions. SKILL.md should stay under 500 lines; use `references/` files for anything larger and cite them by section from SKILL.md. Context prerequisites are documented in the skill body text, not in frontmatter fields.

## Technology Stack

| Layer | Gems |
|:---|:---|
| **TUI** | bubbletea, lipgloss, bubbles, huh, gum, ntcharts, harmonica, glamour, bubblezone |
| **AI** | ruby_llm, dspy.rb, ruby_llm-mcp |
| **Async** | async, circuit_breaker |
| **Storage** | sequel, pgvector, dry-types, dry-schema |
| **Logic** | zeitwerk, dotenv, tty-config |
| **Logging** | journald-logger |
