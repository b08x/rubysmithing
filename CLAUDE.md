# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ruby Agent Skills v1.0 is a modular, convention-aware skill suite for Ruby development with AI assistance. It uses a hub-and-spoke architecture where the central `rubysmithing` skill routes requests to specialized sub-skills for code generation, refactoring, quality assessment, TUI building, and GenAI orchestration.

## Architecture

### Hub-and-Spoke Skill System

- **rubysmithing** (Hub): Central router for Ruby code generation, POROs, Rake tasks, and config wiring
- **rubysmithing-context**: Gem API verification using Context7 MCP server
- **rubysmithing-genai**: AI/NLP components (chatbots, RAG pipelines, DSPy modules, MCP servers)
- **rubysmithing-tui**: Terminal UI scaffolding with Charm/Bubble ecosystem
- **rubysmithing-refactor**: Convention-targeted code fixes and anti-pattern removal
- **rubysmithing-report**: QA assessment using SIFT Protocol V1.0

### Skill Workflow

1. **rubysmithing-context** verifies gem APIs before any library-specific code
2. **rubysmithing** (Hub) detects Lite vs Standard mode based on task scope
3. Sub-skills generate or refactor components independently
4. **rubysmithing-report** provides final QA validation

## Execution Modes

### Lite Mode (≤50 lines or simple scripts)
- Pure Ruby stdlib only
- No `dry-schema`, `async`, `breaker_machines`
- No architectural mandates
- Triggered by: "quick script", "simple utility", "one-off", "stdlib only"

### Standard Mode (default)
- Full stack conventions enforced
- Async fibers, circuit breakers, structured logging
- Zeitwerk compliance required
- All files start with `# frozen_string_literal: true`

## Technology Stack Reference

| Layer | Gems |
|-------|------|
| **TUI** | bubbletea, lipgloss, bubbles, huh, gum, ntcharts |
| **AI** | ruby_llm, dspy.rb, ruby_llm-mcp |
| **Async** | async, breaker_machines |
| **Storage** | sequel, pgvector, dry-types, dry-schema |
| **Logic** | zeitwerk, dotenv, tty-config |
| **Logging** | journald-logger |

## Convention Detection Priority

1. `.rubocop.yml` present → use RuboCop config
2. `standard` in Gemfile → use StandardRB
3. `.rubysmith` / `rubysmith` gem → use Rubysmith defaults
4. None → apply community idioms from `rubysmithing/references/conventions.md`

## Key Conventions (Standard Mode)

### File Structure
- Zeitwerk compliance: file paths must mirror module/class hierarchy exactly
- `lib/app_name/data/processor.rb` → `AppName::Data::Processor`

### Code Style
- Two-space indent, no tabs
- `snake_case` methods/vars, `CamelCase` classes, `SCREAMING_SNAKE` constants
- `Struct.new(keyword_init: true)` for value objects
- Keyword args for 3+ parameter methods
- Guard clauses over nested conditionals
- `module_function` not `extend self`

### Async & Reliability
- `Async { }` blocks instead of `Thread.new` for I/O
- `breaker_machines` wrapping all external API calls
- `journald-logger` for structured logging, never `puts`

## TUI Architecture Pattern

TUI applications use an adapter pattern to isolate from Bubble ecosystem API changes:

```ruby
# lib/app_name/components/base.rb
module Components::Base
  def self.panel(content, style: Styles::PANEL)
    # Internal adapter - if APIs change, update here only
  end
end
```

All screens call `Components::Base.panel(...)` instead of Bubble APIs directly.

## Development Workflow

### Creating New Skills
Each skill requires:
- `SKILL.md` with name, description, triggers, and step-by-step workflow
- `references/` directory with domain-specific patterns and conventions
- Clear activation triggers and delegation rules to other skills

### Generating Code
- Always run `rubysmithing-context` first for gem API verification
- Generate complete files - no truncation or stubs
- Include file path, complete content, rationale, and Gemfile additions
- Specify which mode was applied (Lite/Standard + convention target)

### Working with Skeletons
TUI applications copy from `rubysmithing-tui/assets/skeleton/` and rename throughout:
- `app_name` → actual snake_case name
- `AppName` → actual CamelCase module
- `APP_NAME` → actual SCREAMING_SNAKE constant

## No Build System

This repository contains skill definitions, not executable code. There are no:
- Test suites (specs only generated on explicit request for TUI Update functions)
- Build scripts or Rakefile
- Package managers beyond individual skill Gemfiles
- CI/CD pipelines

Skills are designed to be loaded into a larger agent system that handles the execution environment.