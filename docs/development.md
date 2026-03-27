# Development

Guide for modifying the rubysmithing plugin: adding skills, editing agents, updating references, and working with hooks.

---

## Plugin Structure

This repository contains skill and agent definitions — not executable application code. There is no build system, no CI pipeline, and no Rakefiles. The only executable artifacts are:

- `skills/rubysmithing-context/scripts/context_cache.rb` — gem API cache CLI
- `skills/rubysmithing-analyse/scripts/create-scratchpad.sh` — scratchpad creator (run from user's project root)
- `docker/` — routing test harness for development validation

Most changes are edits to `.md` files.

---

## Agent Files

Agents live in `agents/rubysmithing-{name}.md`. Each file has YAML frontmatter followed by the agent's system prompt.

### Supported Frontmatter Fields (Agents)

```yaml
---
name: rubysmithing-example
description: >
  Routing description used to match requests to this agent.
  Include trigger phrases and scope here.
model: inherit     # or specific model ID
color: red         # UI hint
tools: ["Read", "Grep", "Glob", "Write", "Edit", "Agent"]
---
```

### Agent Descriptions and Prompt Injection

Agent `description:` fields use `<example>` XML tags for routing examples — this is the Claude Code platform convention for developer-authored static content. Rules that apply when modifying:

- **Never embed user-controlled input** in `description:` fields. Agent descriptions are loaded at routing time; injected content can alter agent selection.
- **Angle brackets from user input** must be stripped before writing to any `.md` agent file.
- **Static developer-authored XML tags** in frontmatter are safe. Only user-derived content is not.

### Adding a New Agent

1. Create `agents/rubysmithing-{name}.md` with frontmatter
2. Register it in `.claude-plugin/plugin.json` under `"agents"`
3. Add a routing entry in `agents/rubysmithing-orchestrator.md` routing table
4. Create the corresponding `skills/rubysmithing-{name}/SKILL.md` if the agent uses a skill

---

## Skill Files

Skills live in `skills/{name}/SKILL.md`. The plugin discovers skills by parsing frontmatter. Only `name:` and `description:` load at discovery time; the full body loads on activation.

### Supported Frontmatter Fields (Skills)

```yaml
---
name: skill-name
description: One-line activation trigger and scope description
color: red    # optional
---
```

**`requires:` is not a supported field.** Context prerequisites belong in the skill body text, not frontmatter. The `color:` field is optional and only affects UI display.

### Skill Size Limit

SKILL.md should stay under 500 lines. For larger reference material:

1. Create a file in `skills/{name}/references/`
2. Cite it by section name from SKILL.md: `See references/my-reference.md — Section 3`

### Adding a New Skill

```bash
mkdir -p skills/rubysmithing-{name}/{references,scripts,assets}
touch skills/rubysmithing-{name}/SKILL.md
```

SKILL.md template:

```markdown
---
name: rubysmithing-{name}
description: Activation triggers and scope. List phrases that should activate this skill.
color: red
---

# Rubysmithing — {Name}

Brief description of what this skill does.

## When This Skill Activates

List trigger phrases here.

## Context Prerequisites

(If this skill needs gem API verification, say so here in prose — not in frontmatter.)

## Step 1: ...
```

---

## Convention Hook

`hooks/scripts/check-ruby-conventions.sh` fires on every `.rb` file write. To modify it:

1. Read `hooks/hooks.json` to understand which tool events trigger it
2. The script receives tool call metadata as JSON on stdin — requires `jq` to parse
3. It filters to `.rb` files only; non-Ruby files are ignored
4. Violations inject a correction prompt into the conversation

Behavior without `jq`: the hook no-ops gracefully. This is intentional — the hook should never break a session if `jq` is absent.

---

## Routing Test Harness

The `docker/` directory contains a test harness that validates orchestrator routing decisions. Use it after making changes to agent descriptions or the routing table.

```bash
# Run routing tests (from plugin root)
./docker/entrypoint.sh --test

# Or directly:
./docker/test-routing.sh
```

The harness sends test prompts to the orchestrator and verifies that each routes to the expected sub-agent. Exit code 0 = all tests passed; exit code 1 = one or more failures.

See `docker/test-routing.sh` for the full test matrix.

---

## Gem API Cache

The SQLite cache for gem API verification lives at a path managed by `context_cache.rb`. Cache entries carry a `last_verified` date; entries older than 3 months should be re-verified via Context7.

Cache management:

```bash
ruby skills/rubysmithing-context/scripts/context_cache.rb list              # all gems + staleness
ruby skills/rubysmithing-context/scripts/context_cache.rb check <gem>       # fresh fetch (TTL-aware)
ruby skills/rubysmithing-context/scripts/context_cache.rb stale <gem>       # force stale + warning
ruby skills/rubysmithing-context/scripts/context_cache.rb evict <gem>       # force re-resolution
```

When adding a new gem to the stack, add its Context7 library ID to `skills/rubysmithing-context/references/gem-registry.md` so the tiered degradation protocol can use it as a fallback.

---

## Gem Registry

`skills/rubysmithing-context/references/gem-registry.md` maps gem names to Context7 library IDs and architectural roles (~225 entries). When updating:

- Use the format: `gem-name | /context7-library-id | architectural-role | last-verified`
- Run `/rubysmithing:context <gem>` to verify the ID resolves correctly before committing it

---

## Key Conventions for This Plugin

When modifying or adding `.rb` files (the cache script, scratchpad script):

- `# frozen_string_literal: true` on every file
- `module_function` not `extend self`
- `Async { }` not `Thread.new`
- `journald-logger` for logging — never `puts`
- Zeitwerk: file paths must mirror module/class hierarchy

These are enforced by the PostToolUse hook when you write `.rb` files in this repo.

---

## Error Contract

All sub-agents use the shared error schema at `skills/rubysmithing/references/error-contract.md`. When writing new agent prompts, follow this contract — never return bare failure strings from sub-agents. The orchestrator uses `[AGENT ERROR]` blocks to make recovery decisions.

---

## Related

- [Architecture](architecture.md) — system design and routing
- [Getting Started](getting-started.md) — prerequisites
- [ADR Index](adr/README.md) — why key decisions were made
