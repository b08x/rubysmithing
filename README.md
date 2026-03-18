# Ruby Agent Skills

A modular skill suite for Ruby development with AI assistance. These skills handle code generation, refactoring, quality assessment, documentation lookup, terminal UI building, and AI/NLP integration.

## Skills Overview

### rubysmithing

The central hub skill. Acts as a convention-aware Ruby code generator that routes requests to specialized sub-skills or generates code directly.

**What it does:**
- Generates idiomatic Ruby classes, modules, scripts, and project components
- Detects project conventions (RuboCop, StandardRB, Rubysmith)
- Escalates complex requests to appropriate sub-skills

**Use cases:**
- "Create a service object for user authentication"
- "Generate a Rake task for database cleanup"
- "Add a new gem to the Gemfile with rationale"
- "Scaffold a config layer with dotenv and tty-config"

### rubysmithing-context

Automatically resolves current API syntax for Ruby gems using Context7 MCP. Fires on first gem mention and caches results.

**What it does:**
- Queries Context7 for live gem documentation
- Provides method signatures and working examples
- Prevents stale-syntax errors in generated code

**Use cases:**
- Any request involving gems like ruby_llm, sequel, async, bubbletea
- "How do I use ruby_llm with tool calling?"
- "What's the current syntax for BubbleTea model update?"
- Before implementing any gem-specific code

### rubysmithing-genai

Scaffolds AI/NLP components and advises on integration patterns.

**What it does:**
- Generates LLM chat agents, RAG pipelines, DSPy modules
- Creates embedding generators and NLP processors
- Provides architectural guidance for AI integration

**Use cases:**
- "Build a chatbot with streaming responses"
- "Create a RAG pipeline with pgvector"
- "Implement a DSPy chain-of-thought module"
- "How do I connect MCP tools to ruby_llm?"

### rubysmithing-refactor

Rewrites existing Ruby code to comply with project conventions and architectural patterns.

**What it does:**
- Detects convention target from project config
- Applies anti-pattern corrections
- Restructures for Zeitwerk compliance

**Use cases:**
- "Refactor this to use module_function instead of extend self"
- "Convert Thread.new to Async fiber"
- "Fix Zeitwerk autoload issues in this module"
- "Apply Dry::Schema to these params"

### rubysmithing-report

Code quality assessment engine implementing the SIFT (Software & Systems QA Protocol).

**What it does:**
- Produces structured 8-section SIFT reports
- Identifies architectural violations and anti-patterns
- Provides feasibility ratings and recommendations

**Use cases:**
- "Assess this codebase for convention violations"
- "Give me a code quality report on these files"
- "What's wrong with this Ruby code?"
- "System design review for this architecture"

### rubysmithing-tui

Scaffolds terminal UI applications using the Charm/Bubble ecosystem.

**What it does:**
- Generates BubbleTea apps with Model/Update/View pattern
- Creates Lipgloss layouts and component trees
- Produces full skeleton structure for TUI projects

**Use cases:**
- "Build a file browser TUI"
- "Create a RAG configuration panel"
- "Scaffold an agent control panel dashboard"
- "Add a form to my existing BubbleTea app"

## Skill Routing

The hub skill (`rubysmithing`) automatically routes requests:

```
Request → rubysmithing (hub)
           │
           ├─→ Direct generation (simple Ruby code)
           │
           ├─→ rubysmithing-genai (AI/NLP tasks)
           │
           ├─→ rubysmithing-tui (terminal UI)
           │
           ├─→ rubysmithing-refactor (rewriting existing code)
           │
           ├─→ rubysmithing-report (assessment/audit)
           │
           └─→ rubysmithing-context (gem lookup — always fires first when needed)
```

## Combining Skills

Skills work together in sequence. The typical flow:

1. **rubysmithing-context** resolves gem APIs
2. **rubysmithing-genai** or **rubysmithing-tui** generates implementation
3. **rubysmithing-refactor** cleans up if needed
4. **rubysmithing-report** validates quality

### Example: Building an AI-Powered TUI

```
User: "Create a terminal app that lets me chat with a RAG system"

rubysmithing (hub)
  → rubysmithing-context (resolve ruby_llm, bubbletea, sequel APIs)
  → rubysmithing-tui (scaffold BubbleTea app structure)
  → rubysmithing-genai (generate RAG pipeline + chat component)
```

### Example: Improving Existing Code

```
User: "This Ruby file has Zeitwerk issues and uses threads"

rubysmithing (hub)
  → rubysmithing-refactor (audit + fix)
  → rubysmithing-report (validate quality after refactor)
```

### Example: Full Stack Assessment

```
User: "Audit my Ruby project and tell me what's wrong"

rubysmithing (hub)
  → rubysmithing-report (full SIFT assessment)
  → rubysmithing-refactor (apply fixes for critical issues)
  → rubysmithing-report (re-verify)
```

## Project Stack Reference

These skills assume a terminal-native Ruby stack:

| Layer | Gems |
|-------|------|
| TUI | bubbletea, lipgloss, bubbles, huh, gum, ntcharts |
| AI | ruby_llm, dspy.rb, ruby_llm-mcp |
| Async | async, circuit_breaker |
| Storage | sequel, pgvector, dry-types, dry-schema |
| NLP | ruby-spacy, pragmatic_segmenter |
| Config | tty-config, dotenv |
| Logging | journald-logger |

## Installation

These skills integrate with Claude Code or OpenCode. Place the skill files in your skills directory and reference them by name in your prompts.
