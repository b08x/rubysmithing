# Walkthrough: New Project

Scaffold a new Ruby project or gem using `rubysmith` (for local apps and tools) or `gemsmith` (for publishable gems).

---

## Decision: App/Tool vs. Gem

| Signal | Use | Tool |
|:-------|:----|:-----|
| Building something for yourself or your team | Local app/tool | `rubysmith` |
| Will publish to rubygems.org | Publishable gem | `gemsmith` |

If you're unsure, `rubysmith` is the safer default — you can always extract a gem later.

---

## Walkthrough A: Local Ruby App

### 1. Trigger the scaffold

Say:

```
Scaffold a new Ruby tool called log_processor with RSpec and Git
```

The orchestrator routes to `rubysmithing-scaffold`. It detects "tool" and selects `rubysmith`.

### 2. Review the proposed command

Before executing, the agent shows you the assembled command:

```
Tool:    rubysmith
Project: log_processor
Flags:   --git --rake --rspec --readme
Command: rubysmith build log_processor --git --rake --rspec --readme
```

Confirm or ask for adjustments (e.g., add `--docker`, `--github`, `--license`).

### 3. Execute and review the tree

The agent runs the command and displays the generated file tree:

```
log_processor/
├── Gemfile
├── Rakefile
├── README.md
├── .rubocop.yml
├── lib/
│   └── log_processor.rb
└── spec/
    ├── spec_helper.rb
    └── log_processor_spec.rb
```

### 4. Optional: Standard Mode hardening

After scaffolding, the agent offers to apply Standard Mode conventions:

- Add `# frozen_string_literal: true` to all `.rb` files
- Wire Zeitwerk autoloader in the boot file
- Replace any `puts` with `journald-logger` calls
- Add `async` and `circuit_breaker` to `Gemfile` if not present

Say "yes, apply Standard Mode" or "skip" to proceed.

### 5. Chain to next agent (optional)

`rubysmithing-scaffold` suggests next steps based on your project type:

- **Needs a terminal UI?** → `rubysmithing-tui`
- **Needs LLM/AI components?** → `rubysmithing-genai`
- **Ready for YARD docs?** → `rubysmithing-yardoc`

---

## Walkthrough B: Publishable Gem

### 1. Prerequisite: gemsmith config

`gemsmith` requires author configuration before it will run. If you haven't done this:

```bash
gemsmith --edit
```

This opens `~/.config/gemsmith/configuration.yml` for editing. Fill in your name, email, and GitHub handle.

### 2. Trigger the scaffold

```
Create a new gem called text_normalizer for publishing to rubygems.org
```

`rubysmithing-scaffold` detects "gem" + "rubygems.org" and selects `gemsmith`.

### 3. Review the proposed command

```
Tool:    gemsmith
Project: text_normalizer
Flags:   --rspec --zeitwerk --github
Command: gemsmith build text_normalizer --rspec --zeitwerk --github
```

Ask specifically about:
- `--cli` — add a command-line entry point
- `--security` — enable gem signing

### 4. Execute and review the tree

```
text_normalizer/
├── text_normalizer.gemspec
├── Gemfile
├── Rakefile
├── lib/
│   ├── text_normalizer.rb
│   └── text_normalizer/
│       └── version.rb
├── spec/
│   └── text_normalizer_spec.rb
└── .github/
    └── workflows/
        └── ci.yml
```

### 5. Proceed to implementation

With the skeleton in place, ask rubysmithing to generate the core implementation. See the [Text Processing Gem walkthrough](text-processing-gem.md) for the next steps.

---

## Common Flags Reference

### rubysmith flags

| Flag | Effect |
|:-----|:-------|
| `--git` | Initialize git repository |
| `--rake` | Add Rakefile with default tasks |
| `--rspec` | Add RSpec testing setup |
| `--readme` | Generate README.md |
| `--docker` | Add Dockerfile |
| `--github` | Add GitHub Actions CI |
| `--license` | Add LICENSE file |
| `--citation` | Add CITATION.cff |

### gemsmith flags

| Flag | Effect |
|:-----|:-------|
| `--rspec` | Add RSpec testing setup |
| `--zeitwerk` | Add Zeitwerk autoloader |
| `--github` | Add GitHub Actions CI |
| `--cli` | Add Thor-based CLI entry point |
| `--security` | Enable gem signing |
| `--circleci` | Add CircleCI instead of GitHub Actions |

---

## What to Do After Scaffolding

1. `cd` into the new directory
2. `bundle install`
3. Run `rubocop` to confirm baseline conventions pass
4. Proceed to implementation using rubysmithing: "Add a `LogProcessor::Pipeline` class to `lib/log_processor/pipeline.rb`"

The orchestrator will detect `.rubocop.yml` in the new project and generate all subsequent code to match.

---

## Related

- [Text Processing Gem](text-processing-gem.md) — full implementation example after scaffolding
- [Architecture: rubysmithing-scaffold](../architecture.md)
