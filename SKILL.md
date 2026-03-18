---
name: rubysmithing
description: Convention-aware Ruby code generation hub. Use this skill for any Ruby development task — generating classes, modules, scripts, or entire project components. Acts as a catch-all code generator with project conventions baked in, and escalates to specialized sub-skills when the request clearly involves GenAI/NLP pipelines (rubysmithing-genai), terminal UI components (rubysmithing-tui), code quality reporting (rubysmithing-report), or targeted refactoring (rubysmithing-refactor). Triggers on any Ruby coding request, Gemfile questions, architectural decisions, or requests to scaffold, extend, or fix Ruby code.
---

# Rubysmithing

Convention-aware Ruby code generation hub for a terminal-native AI orchestration stack.
Generates idiomatic Ruby, enforces project-detected conventions, and routes complex
requests to specialized sub-skills.

## Architecture

```
rubysmithing/SKILL.md              — This file: hub router + direct code gen
rubysmithing/references/
  conventions.md                   — Ruby conventions reference (community + stack-specific)
  routing-guide.md                 — Escalation heuristics and sub-skill capabilities

rubysmithing/rubysmithing-context/ — Context7 gem doc lookup sub-skill
rubysmithing/rubysmithing-refactor/— Convention-targeted refactoring sub-skill
rubysmithing/rubysmithing-report/  — Code quality assessment sub-skill
rubysmithing/rubysmithing-genai/   — AI/NLP component scaffolding/advising sub-skill
rubysmithing/rubysmithing-tui/     — Terminal UI scaffolding sub-skill
```

## Activation

### Step 1: Detect Project Convention Target

Before generating any code, scan for convention signals in this order:

1. `.rubocop.yml` present → use RuboCop config as source of truth
2. `standard` gem in Gemfile → use StandardRB rules
3. `rubysmith` gem or `.rubysmith` config → use Rubysmith defaults
4. None detected → default to Ruby community idioms (see `references/conventions.md`)

### Step 2: Check Gem Context

When the request involves any gem from the project stack, trigger **rubysmithing-context**
before writing implementation code. Context7 should resolve current API syntax for:
- Any gem in the curated registry (`rubysmithing-context/references/gem-registry.md`)
- Any unfamiliar gem not in the user's standard stack

Skip context lookup for: stdlib only, pure logic/algorithm code, well-known patterns
(Struct, Comparable, Enumerable) with no external gem surface.

### Step 3: Route or Generate

**Generate directly here** for:
- Single classes, modules, PORO objects
- Rake tasks, initializers, configuration wiring
- Data processing, algorithm, utility code
- Gemfile additions with rationale
- Boot/config layer: dotenv, tty-config, zeitwerk

**Escalate to rubysmithing-genai** for:
- LLM chat, agents, tool-calling, streaming responses
- RAG pipelines, embedding generation, pgvector search
- DSPy reasoning modules or pipelines
- MCP server implementation or client integration
- NLP processing (ruby-spacy, pragmatic_segmenter, informers)

**Escalate to rubysmithing-tui** for:
- BubbleTea app scaffolding or component addition
- TUI screens, panels, component trees
- Lipgloss styling and layout
- Huh forms, Gum prompts, NTCharts dashboards
- Any multi-panel interactive terminal interface

**Escalate to rubysmithing-refactor** for:
- "Refactor this to follow conventions"
- Anti-pattern removal across a file or module
- Zeitwerk compliance restructuring

**Escalate to rubysmithing-report** for:
- "Assess this project / codebase"
- "What conventions am I violating?"
- "Give me a code quality report"

## Code Generation Standards

### Style
- Frozen string literals on all files: `# frozen_string_literal: true`
- Two-space indentation, no tabs
- `snake_case` methods/variables, `CamelCase` classes/modules, `SCREAMING_SNAKE` constants
- Prefer `Struct.new(keyword_init: true)` for simple value objects
- Keyword arguments for methods with 3+ parameters
- Guard clauses over nested conditionals

### Architecture
- Zeitwerk-compliant naming: file path mirrors module/class hierarchy exactly
- `module_function` for pure utility modules — never `extend self`
- `Dry::Schema` or `Dry::Types` for input validation, not ad-hoc guard checks
- Config via `dotenv` → `tty-config` two-tier pattern; never hardcode credentials

### Async / Resilience
- Fiber-based concurrency via `async` gem for all I/O-bound work; no raw threads
- `breaker_machines` circuit breaker wrapping all external API calls
- `journald-logger` for structured logging; never `puts` or `STDOUT.puts`

### Error Handling
- Explicit error classes inheriting from `StandardError`, namespaced to module
- Return result objects or dry-monads over exception-as-flow-control

## Output Format

For every generated file:
1. **File path** — relative to project root
2. **Complete content** — no truncation, no `# ... rest of implementation` placeholders
3. **Rationale** — one sentence if a non-obvious architectural decision was made
4. **Gemfile additions** — listed if new gems are required
