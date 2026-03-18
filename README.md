# Ruby Agent Skills v1.0

A modular, convention-aware skill suite for Ruby development with AI assistance. These skills handle code generation, refactoring, quality assessment, terminal UI building, and GenAI orchestration.

## Architecture

```text
/
├── rubysmithing/              # Hub skill: routes tasks, handles simple Ruby gen
│   ├── SKILL.md
│   └── references/
│       └── conventions.md     # Core Ruby/Stack idioms
├── rubysmithing-context/      # Gem API verification (Context7)
│   ├── SKILL.md
│   ├── scripts/
│   │   └── context_cache.rb   # Persistent gem resolution
│   └── references/
│       └── gem-registry.md
├── rubysmithing-genai/        # AI/NLP scaffolding & patterns
├── rubysmithing-refactor/     # Targeted convention fixes
├── rubysmithing-report/       # SIFT Protocol V1.0 QA assessments
└── rubysmithing-tui/          # Terminal UI building with adapter pattern
    └── assets/skeleton/       # Standardized TUI project structure
```

## Core Execution Modes

All skills in the suite now support two primary execution modes:

- **Lite Mode:** For scripts ≤ ~50 lines, quick utilities, or pure `stdlib` tasks. Omits architectural mandates (async, circuit breakers, dry-schema) for proportional effort.
- **Standard Mode:** The default for project-level code. Enforces full stack conventions: `async` fibers, `breaker_machines`, `journald-logger`, `dry-schema` validation, and Zeitwerk compliance.

## Skills Overview

### rubysmithing (The Hub)
The central entry point. Routes complex requests to sub-skills and handles direct generation for POROs, Rake tasks, and config wiring.
- **What's new:** Hub skill moved to `rubysmithing/`. Lite vs. Standard mode detection.
- **Use cases:** "Create a service object", "Write a one-off cleanup script (Lite)", "Add a gem to Gemfile".

### rubysmithing-context
Resolves live gem documentation using Context7.
- **What's new:** Added `context_cache.rb` to persist gem resolution data, preventing redundant API calls.
- **Use cases:** "How do I use `ruby_llm` with tool calling?", "What is the latest `bubbletea` update syntax?".

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

## Skill Routing & Workflow

The hub automatically determines the best path:

1. **rubysmithing-context** verifies gem APIs.
2. **rubysmithing** (Hub) chooses **Lite** or **Standard** mode.
3. Sub-skills generate or refactor components.
4. **rubysmithing-report** provides the final QA validation.

## Project Stack Reference

The suite is optimized for a terminal-native, high-resilience Ruby stack:

| Layer | Gems |
|-------|------|
| **TUI** | bubbletea, lipgloss, bubbles, huh, gum, ntcharts |
| **AI** | ruby_llm, dspy.rb, ruby_llm-mcp |
| **Async** | async, breaker_machines |
| **Storage** | sequel, pgvector, dry-types, dry-schema |
| **Logic** | zeitwerk, dotenv, tty-config |
| **Logging** | journald-logger |

## Installation

Place these directories in your skills path. Reference `rubysmithing` as the primary hub; it will escalate to sub-skills as needed.
