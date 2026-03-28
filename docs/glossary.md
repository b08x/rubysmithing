# Glossary

Domain terms, acronyms, and project-specific vocabulary used throughout the rubysmithing documentation.

---

## A

**Agent** — A `.md` file in `skills/{name}/agents/` that defines an autonomous sub-process with a specific role. Agents receive routing decisions from the orchestrator and execute multi-step tasks using tools (Read, Grep, Glob, Write, Edit, Agent).

**async** — The `async` gem providing fiber-based concurrency in Ruby. Standard Mode requires `Async { }` blocks instead of `Thread.new` for all concurrent work. See: [async gem](https://github.com/socketry/async).

---

## C

**circuit_breaker** — The `circuit_breaker` gem that wraps external calls (network, database, APIs) to fail fast and prevent cascade failures. Standard Mode requires circuit breaker wrapping on all external calls.

**Convention detection cascade** — The ordered rules the plugin uses to determine which code style to enforce: `.rubocop.yml` → `standard` in Gemfile → `.rubysmith` file → community idioms. Documented in `skills/rubysmithing/references/convention-detection.md`.

**Context7 MCP** — An MCP server that fetches live documentation from library sources. `rubysmithing-context` uses it to resolve current gem API signatures before generating code. Without it, tiered degradation activates.

---

## D

**do-and-judge loop** — A SADD pattern in `rubysmithing-refactor`: meta-judge generates an evaluation spec in parallel with refactoring; judge verifies the output; one retry allowed on FAIL. Activates on 1+ CRITICAL audit items, 3+ files, or explicit user request.

**dry-schema** — The `dry-schema` gem for input validation. Standard Mode requires schema validation at system boundaries (user input, external API responses).

---

## F

**Five Whys** — An analysis method in `rubysmithing-analyse` that drills into a recurring issue through iterative causal questioning: "Why did this fail? → Why? → Why?" until root cause is isolated.

**frozen_string_literal** — The magic comment `# frozen_string_literal: true` that makes Ruby string literals immutable. Required on every `.rb` file in Standard Mode; enforced by the PostToolUse convention hook.

---

## G

**Gemba Walk** — An analysis method from Lean manufacturing, adapted in `rubysmithing-analyse` to mean "go read the actual code." Bridges the gap between documented/assumed behavior and what the code actually does. The default method when no specific signal is present.

**gemsmith** — CLI tool for scaffolding publishable Ruby gems (for rubygems.org). Counterpart to rubysmith for local tools. Requires `~/.config/gemsmith/configuration.yml` with author info.

---

## H

**Hub-and-spoke architecture** — The plugin's structural pattern: `rubysmithing` (hub) routes requests to specialized domain sub-agents (spokes). Each spoke handles one domain — scaffolding, TUI, GenAI, refactoring, etc.

---

## J

**journald-logger** — The structured logging gem. Standard Mode requires it instead of `puts` for all logging output. Writes structured entries to systemd journal.

---

## L

**Lite Mode** — Execution mode for single-file output ≤ ~50 lines using pure stdlib. Skips async, circuit_breaker, dry-schema, and enforced frozen_string_literal. Triggered by: "quick script", "simple utility", "one-off", "stdlib only".

---

## M

**meta-judge** — The `rubysmithing-meta-judge` agent that generates a Ruby-calibrated YAML evaluation spec (5 rubric dimensions + 10 checklist items). Called internally by `rubysmithing-refactor` and `rubysmithing-report`. Not user-invocable.

**Muda** — Lean term for waste. `rubysmithing-analyse` maps 7 Muda waste types to Ruby artifacts: dead methods, N+1 queries, unused gems, over-engineering, speculative abstractions, debug `puts` left in, unused initializer args.

---

## O

**Orchestrator** — The thin routing agent (`skills/rubysmithing/agents/rubysmithing-orchestrator.md`) that analyzes requests, performs convention detection, determines parallel vs sequential dispatch, and delegates to domain sub-agents. Never implements anything itself.

---

## P

**PORO** — Plain Old Ruby Object. A class that relies only on Ruby's core features and loaded libraries, without framework magic. The default code shape for `rubysmithing-main`.

**PostToolUse hook** — A Claude Code hook that fires `check-ruby-conventions.sh` after every Write or Edit tool call on `.rb` files. Validates frozen_string_literal, module/class naming, and style targets.

---

## R

**Root-Cause Tracing** — An analysis method in `rubysmithing-analyse` that walks backward from an error symptom through the call chain to the origin. Used for exceptions, Zeitwerk NameErrors, circuit_breaker trips, and slow queries.

**rubysmith** — CLI tool for scaffolding local Ruby applications, tools, and scripts. Counterpart to gemsmith for non-gem projects.

---

## S

**SADD** — Subagent-Driven Development. A multi-agent framework pattern. Rubysmithing integrates four SADD patterns: meta-judge → judge pipeline, do-and-judge retry loop, SIFT + meta-judge, and scratchpad persistence.

**scratchpad** — A temporary findings file written to `.specs/scratchpad/<hex-id>.md` in the user's project root during multi-file analysis. Contains structured `rubysmithing-analyse` output keyed to refactor pattern names for downstream agent handoff.

**SIFT Protocol V1.0** — The quality assessment framework in `rubysmithing-report`. Evaluates Ruby artifacts across 5 rubric dimensions. Pass threshold: 3.5/5.0. Has two modes: System Design Review and Tech Advisory.

**Skill** — A `SKILL.md` file in `skills/{name}/` that defines triggers, activation conditions, and step-by-step execution instructions for an agent. Frontmatter contains only `name:` and `description:` — the only supported fields.

**Standard Mode** — The default execution mode. Applies the full terminal-native stack: async fibers, circuit_breaker, journald-logger, dry-schema validation, Zeitwerk compliance, frozen_string_literal on every file. Always used for multi-file scaffolds.

---

## T

**tiered degradation** — The fallback protocol in `rubysmithing-context` when Context7 is unavailable: (1) serve stale SQLite cache with warning block, (2) retry with pre-mapped gem-registry ID, (3) inject `[WARNING: Unverified API Syntax]` as last resort. Never silently proceeds.

---

## W

**WARNING block** — An output block injected by `rubysmithing-context` when API verification falls back to unverified data: `[WARNING: Unverified API Syntax — verify against gem source before using]`. Appears in generated code output, not silently swallowed.

---

## Z

**Zeitwerk** — The code loader gem used by Rails and standalone Ruby projects. Requires that file paths mirror module/class hierarchy exactly: `lib/app_name/data/processor.rb` → `AppName::Data::Processor`. Standard Mode enforces Zeitwerk compliance.
