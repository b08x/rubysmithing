# Getting Started

## Prerequisites

Two external tools are required. The plugin degrades gracefully without them, but functionality is limited.

### Context7 MCP (required for gem API verification)

Context7 fetches live gem documentation before code is generated. Without it, `rubysmithing-context` falls back to stale cache, then gem-registry IDs, then injects `[WARNING: Unverified API Syntax]` — it never silently proceeds, but accuracy degrades.

Add to your Claude Code MCP settings (`~/.claude/settings.json` or project `.claude/settings.json`):

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    }
  }
}
```

Verify it's working:

```
/rubysmithing:context bubbletea
```

A successful check returns current method signatures and usage examples. A failed check returns a WARNING block.

### jq (required for convention enforcement hook)

The PostToolUse hook that validates `.rb` files after every write requires `jq` to parse tool call results. Without it, the hook silently no-ops.

```bash
# macOS
brew install jq

# Fedora/RHEL
dnf install jq

# Ubuntu/Debian
apt install jq
```

---

## Installation

Rubysmithing is a Claude Code plugin. Place the plugin directory in your Claude Code plugins path.

The plugin registers 12 agents, 5 slash commands, 9 skills, and 2 hooks automatically when Claude Code loads.

### Verify Installation

Check that agents are registered:

```
/rubysmithing:context zeitwerk
```

You should see a Context7 resolution result or a tiered degradation block — either confirms the plugin is loaded.

---

## Ruby Version

The plugin's own scripts require Ruby 3.4.4 (see `.tool-versions`). If you use the gem cache CLI directly:

```bash
# Install correct Ruby version via rbenv or mise
rbenv install 3.4.4    # rbenv
mise install           # mise/asdf

# Install dependencies
bundle install
```

The plugin itself (agent/skill `.md` files) runs in Claude Code and has no Ruby version requirement. Only the cache management script (`context_cache.rb`) and any scaffolding commands you invoke in the terminal require a Ruby runtime.

---

## First Use

### Natural Language (Recommended)

Most tasks activate skills automatically. Just describe what you want:

```
Build me a Sequel-backed data ingestion pipeline with circuit breaker wrapping
```

The orchestrator detects Sequel as a non-stdlib gem, runs `rubysmithing-context` for API verification, then routes to `rubysmithing` (main) and generates Standard Mode Ruby code.

### Slash Commands

Five commands are available for direct invocation:

| Command | Purpose |
|:--------|:--------|
| `/rubysmithing:context <gem>` | Check or warm the gem API cache for a specific gem |
| `/rubysmithing:report [path]` | Run SIFT QA assessment on a file or directory |
| `/rubysmithing:scaffold [name]` | Initialize a new Ruby project or gem |
| `/rubysmithing:refactor <file>` | Audit and refactor a `.rb` file |
| `/rubysmithing:yardoc <file>` | Generate YARD documentation for a `.rb` file |

---

## Warming the Context Cache

Before starting a session that will generate code using specific gems, pre-warm the cache:

```
/rubysmithing:context bubbletea
/rubysmithing:context lipgloss
/rubysmithing:context sequel
```

Warmed entries serve instantly from SQLite on subsequent requests, avoiding Context7 round-trips mid-generation.

Check cache freshness:

```bash
ruby skills/rubysmithing-context/scripts/context_cache.rb list
```

Force re-resolution for a specific gem:

```bash
ruby skills/rubysmithing-context/scripts/context_cache.rb evict bubbletea
```

---

## Convention Detection

The plugin auto-detects your project's code style at the start of every task. To confirm what it detected:

Start a request with: "Check my project conventions and tell me what style target you found."

The orchestrator will scan for `.rubocop.yml`, `standard` in Gemfile, or `.rubysmith` config, and report the detected target before proceeding.

---

## What to Try First

If you're new to the plugin, start with one of these:

1. **Analyse a Ruby file you're about to change** — `rubysmithing-analyse` gives you a Gemba Walk before you touch anything:
   ```
   Gemba walk lib/my_service.rb before I refactor it
   ```

2. **Scaffold a new project** — see the [New Project walkthrough](walkthroughs/new-project.md)

3. **Run a QA report** on an existing file:
   ```
   /rubysmithing:report lib/my_service.rb
   ```

---

## Next Steps

- [Walkthroughs](walkthroughs/README.md) — step-by-step examples
- [Architecture](architecture.md) — how routing and agents work
- [Development](development.md) — modifying the plugin itself
