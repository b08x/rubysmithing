# Rubysmithing

<div align="center">

**Convention-aware Ruby development plugin for Claude Code.**

Auto-activating skills, orchestrated agent suite, convention enforcement hooks, and slash commands — built on a hub-and-spoke architecture.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

</div>

---

## Features

- **Orchestrated agent suite** — Thin routing orchestrator dispatches to domain sub-agents with parallel/sequential awareness, avoiding the telephone-game problem
- **Auto-activating skills** — Nine skill modules activate on trigger phrases; complex requests escalate automatically from hub to sub-skill
- **Convention enforcement hooks** — PostToolUse hook validates `.rb` files against RuboCop, StandardRB, or community idioms on every write
- **Live gem API verification** — Context7 MCP integration with SQLite-backed cache; tiered degradation (cache → registry → warning) never silently fails
- **TUI scaffolding** — Charm/Bubble ecosystem scaffolder with verified API patterns and a copy-paste skeleton template
- **SIFT QA protocol** — V1.0 quality assessment engine with optional meta-judge verification footer for 3+ file reviews
- **SADD patterns** — Subagent-Driven Development infrastructure (meta-judge, do-and-judge retry loop, scratchpad persistence) built into refactor and report agents
- **Slash commands** — Five user-invocable commands cover context warming, QA assessment, project scaffolding, refactoring, and YARD documentation

---

## Prerequisites

Requires two external tools. The plugin degrades gracefully if either is absent, but functionality will be limited.

<details>
<summary>Context7 MCP (for live gem API resolution)</summary>

Add to Claude Code MCP settings:

```json
{ "context7": { "command": "npx", "args": ["-y", "@upstash/context7-mcp@latest"] } }
```

Without it, `rubysmithing-context` falls back to stale SQLite cache → pre-mapped gem-registry → `[WARNING: Unverified API Syntax]`.

</details>

<details>
<summary>jq (for convention enforcement hook)</summary>

```bash
# macOS
brew install jq

# Ubuntu/Debian
apt install jq
```

The PostToolUse hook runs `check-ruby-conventions.sh` on every `.rb` file write. It no-ops if `jq` is absent.

</details>

---

## Installation

Place the `skills/` directory in the Claude Code skills path:

```
skills/
```

All agents, commands, and hooks are co-located inside their respective skill directory. Reference `rubysmithing` as the primary hub. Sub-skills activate automatically on trigger phrases.

---

## Plugin Layout

Agents, commands, and hooks are co-located inside each skill directory.

```
skills/
  rubysmithing/                    # Hub — routes to sub-skills
    agents/
      rubysmithing-orchestrator.md # Thin router with parallel dispatch
      rubysmithing-main.md         # Hub for POROs, Rake, config wiring
    hooks/
      hooks.json                   # PostToolUse(Write|Edit) + Stop hooks
      scripts/check-ruby-conventions.sh  # RuboCop/StandardRB/community idiom validator
    references/
      convention-detection.md      # Canonical cascade (RuboCop → StandardRB → rubysmith → community)
      conventions.md               # Fallback community idiom patterns
  rubysmithing-context/            # Context7 + SQLite cache
    agents/rubysmithing-context.md
    commands/context.md
    references/
      gem-registry.md              # Context7 IDs × architectural roles (225 entries)
    scripts/
      context_cache.rb             # CLI: list, check, stale, evict
  rubysmithing-tui/                # Bubble/TUI scaffolding
    agents/rubysmithing-tui.md
    references/
      tui-patterns.md              # Context7-verified Bubble gem API patterns
      design-patterns.md           # Architecture decisions, layout paradigms, anti-patterns
    assets/skeleton/               # Bubble app template (rename app_name → your_app)
  rubysmithing-scaffold/           # rubysmith/gemsmith project init
    agents/rubysmithing-scaffold.md
    commands/scaffold.md
  rubysmithing-genai/              # LLM, RAG, DSPy, MCP, embeddings
    agents/rubysmithing-genai.md
  rubysmithing-refactor/           # Convention-targeted refactoring
    agents/rubysmithing-refactor.md
    commands/refactor.md
  rubysmithing-report/             # SIFT Protocol V1.0 QA
    agents/
      rubysmithing-report.md
      rubysmithing-meta-judge.md   # SADD: generates Ruby-calibrated YAML eval specs
      rubysmithing-judge.md        # SADD: applies eval specs with file:line evidence
    commands/report.md
  rubysmithing-yardoc/             # YARD docs with semantic AST analysis
    agents/rubysmithing-yardoc.md
    commands/yardoc.md
  rubysmithing-analyse/            # Gemba Walk, Muda, Root-Cause, Five Whys
    agents/rubysmithing-analyse.md
    commands/analyse.md
    references/
      analyse-methods.md           # Four methods with templates
    scripts/
      create-scratchpad.sh         # Persists findings to .specs/scratchpad/<hex-id>.md
```

---

## Architecture

### Routing Workflow

1. **Convention detection** — `.rubocop.yml` → `standard` in Gemfile → `.rubysmith` → community idioms
2. **rubysmithing-context** verifies gem APIs if non-stdlib gems are in scope
3. **Dispatch** — independent sub-tasks launch in parallel; dependent sub-tasks sequence explicitly
4. Sub-agents generate/refactor using verified API syntax
5. **rubysmithing-report** provides final QA validation (optional meta-judge footer for 3+ file reviews)

### Direct Pass-Through

Some agents produce complete, self-contained outputs — the orchestrator passes these through unchanged rather than re-processing:

| Agent | Pass-Through |
|:------|:-------------|
| `rubysmithing-report` | Always |
| `rubysmithing-yardoc` | Always |
| `rubysmithing-scaffold` | After CLI execution |

### Routing Weights

For compound requests, the orchestrator allocates effort by weight:

| Request | Primary | Weight | Secondary | Weight |
|:--------|:--------|-------:|:-----------|-------:|
| TUI + GenAI | genai | 0.6 | tui | 0.4 |
| Refactor + GenAI | refactor | 0.5 | genai | 0.5 |
| Scaffold + TUI | scaffold | 0.7 | tui | 0.3 |
| Refactor + Report | refactor | 0.6 | report | 0.4 |

### Parallel vs. Sequential Dispatch

| Request | Dispatch | Reason |
|:--------|:---------|:-------|
| GenAI module + TUI dashboard | Parallel | Different file trees, different gem APIs |
| Analyse + Refactor | Sequential | Refactor depends on analyse findings |
| Refactor + Report | Sequential | Report evaluates refactored output |
| Context + any code-gen | Sequential | Context must complete first |

---

## Commands

| Command | Purpose |
|:--------|:--------|
| `/rubysmithing:context <gem>` | Check or warm the gem API cache |
| `/rubysmithing:report [path]` | Run SIFT QA assessment |
| `/rubysmithing:scaffold [name]` | Initialize new Ruby project |
| `/rubysmithing:refactor <file>` | Audit and refactor a file |
| `/rubysmithing:yardoc <file>` | Generate YARD documentation |

---

## Execution Modes

Two modes govern skill behavior. Selecting appropriately prevents over-engineering.

- **Lite** — Single-file output ≤ ~50 lines, pure `stdlib`, quick utilities. Skips async, circuit_breaker, and dry-schema for proportional effort.
- **Standard** — Default for project-level code. Enforces async fibers, circuit_breaker, journald-logger, dry-schema validation, Zeitwerk compliance. Multi-file scaffold requests always trigger Standard Mode regardless of per-file line count.

---

## Skill Dependencies

Each skill frontmatter declares a `requires:` field, giving the executing agent a machine-readable dependency graph. Empty `requires: []` means no prerequisites. Context prerequisites are documented in the skill body text, not frontmatter fields.

### rubysmithing (The Hub)

Central entry point. Routes complex requests to sub-skills; handles POROs, Rake tasks, and config wiring directly.

### rubysmithing-context

Resolves live gem documentation via Context7. Degrades through a tiered protocol when Context7 is unreachable: stale SQLite cache with warning → pre-mapped gem-registry ID → `[WARNING: Unverified API Syntax]`.

```bash
ruby skills/rubysmithing-context/scripts/context_cache.rb list              # all cached gems + staleness
ruby skills/rubysmithing-context/scripts/context_cache.rb check <gem>       # fresh fetch (respects TTL)
ruby skills/rubysmithing-context/scripts/context_cache.rb stale <gem>        # stale fetch + warning
ruby skills/rubysmithing-context/scripts/context_cache.rb evict <gem>        # force re-resolution
```

### rubysmithing-tui

Terminal UI scaffolder for the Ruby Charm/Bubble ecosystem. Includes verified API patterns, architectural decisions, and a Bubble app skeleton template.

Verified Bubble gem API conventions (via Context7):
- Entry point: `Bubbletea.run(App.new)` — not `BubbleTea::Program.new`
- Quit: `Bubbletea.quit` — not `BubbleTea::Quit`
- Lipgloss colors: `.foreground("#HEXSTR")` — no `Lipgloss::Color.new` wrapper
- Lipgloss alignment: `:left`, `:top` symbols — not `Lipgloss::Align::LEFT`

### rubysmithing-analyse

Diagnoses *why* problems exist before fixing begins. Four auto-selected methods adapted from Kaizen (Context Engineering Kit):

- **Gemba Walk** — observe actual code vs. assumed behavior; document surprises
- **Muda Analysis** — map 7 lean waste types to Ruby artifacts
- **Root-Cause Tracing** — backward call-chain from symptom to origin (classic: Zeitwerk NameError)
- **Five Whys** — iterative causal drilling for recurring issues

Findings persist to `.specs/scratchpad/<hex-id>.md` for downstream agent handoff.

### rubysmithing-refactor

Rewrites code to follow conventions. Uses a Pre-Refactor Audit phase before generating changes. For 1+ CRITICAL audit items or 3+ files, optionally runs the do-and-judge retry loop: meta-judge generates an evaluation spec in parallel with refactoring; judge verifies output; one retry on FAIL.

### rubysmithing-report

QA assessment engine implementing SIFT Protocol V1.0. Includes System Design Review and Tech Advisory modes. For 3+ file reviews, meta-judge appends a scored verification footer (pass threshold: 3.5/5.0).

### rubysmithing-yardoc

YARD documentation generator with semantic analysis and type inference. Activates rubysmithing-context for non-stdlib gems before generating.

---

## Stack Reference

Optimized for a terminal-native, high-resilience Ruby stack:

| Layer | Gems |
|:------|:-----|
| **TUI** | bubbletea, lipgloss, bubbles, huh, gum, ntcharts, bubblezone, glamour, harmonica |
| **AI** | ruby_llm, dspy.rb, ruby_llm-mcp |
| **Async** | async, circuit_breaker |
| **Storage** | sequel, pgvector |
| **Logic** | zeitwerk, dotenv, tty-config, dry-types, dry-schema |
| **Logging** | journald-logger |

---

## SADD Integration

The plugin incorporates patterns from SADD (Subagent-Driven Development), part of the Context Engineering Kit:

| Pattern | Where | Trigger |
|:--------|:------|:--------|
| **Meta-judge → Judge** | `rubysmithing-report` | 3+ file SIFT or explicit score request |
| **Do-and-judge retry loop** | `rubysmithing-refactor` | 1+ CRITICAL audit items, 3+ files, or user verification request |
| **Scratchpad persistence** | `rubysmithing-analyse` | Directory/multi-file targets, downstream handoff |
| **Parallel dispatch** | `rubysmithing-orchestrator` | Independent compound sub-tasks |

Evaluation agents (`rubysmithing-meta-judge`, `rubysmithing-judge`) are infrastructure — called internally by report and refactor, not user-invocable directly.

---

## Testing

The plugin includes a routing test harness to validate that orchestrator routing decisions remain correct after prompt engineering changes.

### Running Tests Locally

```bash
# From the plugin root directory
./docker/entrypoint.sh --test

# Or directly:
./docker/test-routing.sh
```

### What It Tests

The test harness validates that the orchestrator routing table correctly maps user intent patterns to the appropriate sub-agent:

| Prompt Pattern | Expected Agent |
|:---------------|:---------------|
| "Build a TUI dashboard" | `rubysmithing-tui` |
| "Scaffold a new project" | `rubysmithing-scaffold` |
| "Refactor this file" | `rubysmithing-refactor` |
| "Review code quality" | `rubysmithing-report` |
| "Write a RAG pipeline" | `rubysmithing-genai` |
| "Debug Zeitwerk error" | `rubysmithing-analyse` |
| "Generate YARD docs" | `rubysmithing-yardoc` |
| "Create a Sequel model" | `rubysmithing` (main) |
| "Build chatbot AND TUI" | Both `genai` and `tui` |

### Exit Codes

- `0` — All routing tests passed
- `1` — One or more tests failed

---

## Contributing

Bug reports and pull requests are welcome on GitHub. Substantive changes to agent or skill definitions should include updated inline documentation.

---

## License

[MIT License](https://opensource.org/licenses/MIT)
