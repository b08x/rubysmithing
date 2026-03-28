# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-22
**Project:** Rubysmithing v1.0 — Claude Code plugin for Ruby development

## OVERVIEW

Convention-aware Ruby development suite. Plugin config + documentation (no executable code). Hub-and-spoke skill system with 9 agents, 8 skills, 5 commands, convention enforcement hooks. Context7 MCP for live gem API verification.

## STRUCTURE

```
.
├── .claude-plugin/        # plugin.json (manifest), marketplace.json
├── agents/                # 9 .md files — orchestrator + 8 domain agents
├── commands/              # 5 .md files — slash command definitions
├── hooks/                 # hooks.json + scripts/check-ruby-conventions.sh
├── skills/                # 8 SKILL.md subdirectories
│   ├── rubysmithing/          # HUB — routes to sub-agents
│   │   └── references/        # convention-detection.md, conventions.md
│   ├── rubysmithing-context/  # Gem API via Context7 + SQLite cache
│   │   ├── references/        # gem-registry.md (225 lines, Context7 IDs)
│   │   └── scripts/           # context_cache.rb (list/check/stale/evict)
│   ├── rubysmithing-tui/      # Charm/Bubble TUI scaffolder
│   │   ├── references/        # tui-patterns.md (724 lines), design-patterns.md (501 lines)
│   │   └── assets/skeleton/   # Bubble app template (app_name → rename)
│   ├── rubysmithing-scaffold/ # rubysmith/gemsmith project init
│   ├── rubysmithing-genai/    # LLM, RAG, DSPy, MCP, embeddings
│   ├── rubysmithing-refactor/ # Convention-targeted rewriting
│   ├── rubysmithing-report/   # SIFT Protocol V1.0 QA
│   └── rubysmithing-yardoc/   # YARD docs with type inference
├── docker/                # entrypoint.sh + prompt.txt (dev/testing)
├── CLAUDE.md              # 205-line human-readable guidance
└── README.md              # 193-line public-facing docs
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Agent routing logic | `skills/rubysmithing/agents/rubysmithing-orchestrator.md` | Thin router, convention detection, weight assignment |
| Gem API verification | `skills/rubysmithing-context/` | SQLite cache + Context7 resolution |
| TUI code generation | `skills/rubysmithing-tui/` | VERIFIED API patterns only |
| Convention rules | `skills/rubysmithing/references/convention-detection.md` | Canonical cascade — all skills reference this |
| Community idioms | `skills/rubysmithing/references/conventions.md` | Fallback when no project config detected |
| QA assessment | `skills/rubysmithing-report/` | SIFT Protocol V1.0 |
| Gem registry | `skills/rubysmithing-context/references/gem-registry.md` | Context7 IDs × architectural roles |
| TUI anti-patterns | `skills/rubysmithing-tui/references/design-patterns.md` §7 | Checklist of forbidden patterns |

## CONVENTIONS

**Detection cascade** (stop at first match):
1. `.rubocop.yml` → RuboCop
2. `standard` in Gemfile → StandardRB
3. `.rubysmith` / rubysmith gem → Rubysmith defaults
4. None → community idioms from `conventions.md`

**Execution modes:**
- **Lite:** ≤50 lines, stdlib only, no architectural mandates
- **Standard:** async fibers, circuit_breaker, journald-logger, dry-schema, Zeitwerk

**Multi-file scaffold → always Standard Mode.**

**Skill frontmatter:** `name:` and `description:` are the only supported fields. Context prerequisites are documented in the skill body text.

## ANTI-PATTERNS (THIS PROJECT)

| Forbidden | Context |
|-----------|---------|
| `BubbleTea::Quit` | Use `Bubbletea.quit` (lowercase, module method) |
| `BubbleTea::Program.new` | Use `Bubbletea.run(App.new)` |
| `Lipgloss::Color.new("#HEX")` | Use `.foreground("#HEX")` plain string |
| `Lipgloss::Align::LEFT` | Use `:left` symbol |
| `Struct.new(...).with(...)` for App state | Use plain `@ivar` |
| `update` returns `nil` or bare model | Always `[self, command]` |
| Silent gem API failures | Fail loudly — tiered degradation |
| Using `puts` for logging | Use `journald-logger` |
| `extend self` | Use `module_function` |
| Nested conditionals | Guard clauses |
| Positional args (3+ params) | Keyword arguments |
| Missing `# frozen_string_literal: true` | Enforced by PostToolUse hook |

## UNIQUE STYLES

- **Hub-and-spoke:** orchestrator delegates to domain agents via routing table
- **Direct pass-through:** report/yardoc/scaffold outputs flow unchanged
- **Routing weights:** compound requests get effort allocation (genai 0.6, tui 0.4)
- **SQLite cache:** `rubysmithing-context` uses SQLite as source of truth, not session memory
- **Tiered degradation:** Context7 fails → stale cache → gem-registry → WARNING block
- **Convention detection:** single source of truth in `convention-detection.md`
- **TUI adapter:** `Components::Base` isolates Bubble API calls from screens/components
- **SIFT Protocol:** QA assessment with "System Design Review" and "Tech Advisory" modes

## COMMANDS

```bash
# Cache management
ruby skills/rubysmithing-context/scripts/context_cache.rb list              # cached gems
ruby skills/rubysmithing-context/scripts/context_cache.rb check <gem>       # fresh fetch
ruby skills/rubysmithing-context/scripts/context_cache.rb stale <gem>       # stale + warning
ruby skills/rubysmithing-context/scripts/context_cache.rb evict <gem>       # force re-resolve

# Slash commands (user-facing)
/rubysmithing:context <gem>   # check/warm gem API cache
/rubysmithing:report [path]   # SIFT QA assessment
/rubysmithing:scaffold [name] # initialize Ruby project
/rubysmithing:refactor <file> # audit and refactor
/rubysmithing:yardoc <file>   # generate YARD docs
```

## NOTES

- **No build system.** No tests, CI, or Rakefiles. Specs generated only on explicit request (TUI Update functions).
- **Prerequisites:** Context7 MCP + jq. Degrades gracefully without them.
- **Docker:** `docker/` is dev/testing artifact (entrypoint + prompt.txt), not production infrastructure.
- **TUI skeleton:** `assets/skeleton/` is template — rename `app_name`/`AppName`/`APP_NAME` to snake_case/CamelCase/SCREAMING_SNAKE.
- **Gem registry staleness:** entries carry `last_verified` date; re-verify >3 months old via Context7.
