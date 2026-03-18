---
name: rubysmithing-refactor
description: Convention-targeted Ruby refactoring sub-skill. Use when the task is to rewrite existing Ruby code to comply with detected project conventions (RuboCop, StandardRB, or Rubysmith), eliminate anti-patterns, restructure for Zeitwerk compliance, or apply architectural patterns from the rubysmithing stack (Dry::Types, async fibers, circuit breakers). Accepts pasted code snippets, uploaded files, or filesystem paths. Always detects convention target from project config before applying changes.
---

# Rubysmithing — Refactor

Targeted refactoring of existing Ruby code toward project-detected conventions
and stack-specific architectural patterns.

## Inputs Accepted

- **Pasted snippet** — inline code in the conversation
- **Uploaded file** — read from `/mnt/user-data/uploads/`
- **Filesystem path** — read via bash tools from a project directory
- **Multiple files** — accepted; process each in dependency order (base classes first)

## Refactor Workflow

### Step 1: Detect Convention Target

Scan project root for (in priority order):
1. `.rubocop.yml` → parse enabled cops, custom rules, target Ruby version
2. `Gemfile` containing `gem "standard"` → apply StandardRB rules
3. `.rubysmith` or `Gemfile` containing `gem "rubysmith"` → apply Rubysmith defaults
4. Nothing found → apply community idioms from `references/refactor-patterns.md`

### Step 2: Audit Before Changing

Before rewriting, produce a brief pre-refactor audit:
```
FILE: lib/my_app/processor.rb
Convention target: RuboCop (.rubocop.yml detected)
Issues found:
  [CRITICAL] No frozen_string_literal magic comment
  [CRITICAL] Thread usage — should be Async fiber
  [WARNING]  extend self on utility module — use module_function
  [WARNING]  Nested conditionals (depth 3) — use guard clauses
  [INFO]     File/class name mismatch — Zeitwerk will fail to autoload
```

### Step 3: Refactor

Apply changes from `references/refactor-patterns.md`. For each change:
- Show the before/after diff for non-trivial transformations
- Add an inline comment if the refactored pattern is non-obvious
- Never silently drop functionality — flag if a change alters behavior

### Step 4: Verify Zeitwerk Compliance

After refactoring, confirm:
- Module/class name matches file path exactly (e.g. `MyApp::DataProcessor` → `lib/my_app/data_processor.rb`)
- No `require` statements for files that Zeitwerk should autoload
- `loader.collapse` or `loader.push_dir` used correctly for non-standard paths

## Common Refactor Patterns

See `references/refactor-patterns.md` for full catalog. Key patterns:

| Anti-pattern | Target pattern |
|---|---|
| `extend self` on utility module | `module_function` |
| Raw `Thread.new` | `Async { }` fiber block |
| `puts` / `STDOUT` logging | `Journald::Logger` |
| Hardcoded config values | `tty-config` + `.env` |
| Bare `rescue Exception` | Named error class rescue |
| `rescue => e; nil` | Explicit handling or re-raise |
| 3+ positional args | Keyword arguments |
| Deep nested `if/elsif` | Guard clauses |
| Ad-hoc hash validation | `Dry::Schema.Params` |

## Output Format

For each refactored file:
1. Pre-refactor audit summary (issues found, severity)
2. Complete refactored file — no diffs only, always provide the full file
3. Change log: bullet list of what changed and why
4. Any behavior changes flagged explicitly
