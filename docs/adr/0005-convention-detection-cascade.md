# ADR 0005: Convention Detection Cascade with Single Source of Truth

**Status:** Accepted

---

## Context

Ruby projects use different code style tools: RuboCop with custom config, StandardRB (a zero-config wrapper around RuboCop), Rubysmith defaults, or informal community idioms. Each has different rules around frozen_string_literal, method naming, and module structure.

If each skill and agent independently determines what style to apply, they will drift out of sync. A refactoring agent might apply RuboCop conventions while the code generation agent applies StandardRB — producing inconsistent output in the same session.

The alternative was to require users to specify the convention target in every request. This is unreliable (users forget) and redundant (the information is already in the project).

---

## Decision

Implement a single detection cascade, documented in one authoritative file:

```
skills/rubysmithing/references/convention-detection.md
```

All skills and agents reference this file — they never duplicate the detection logic. The cascade, in order:

1. `.rubocop.yml` present in project root → use RuboCop configuration
2. `standard` gem in `Gemfile` → use StandardRB
3. `.rubysmith` file or `rubysmith` gem in `Gemfile` → use Rubysmith defaults
4. None of the above → use community idioms from `skills/rubysmithing/references/conventions.md`

The orchestrator runs this detection at the start of every session and passes the detected target to all domain agents in the routing message. Agents do not re-detect — they use the value passed by the orchestrator.

---

## Consequences

**Benefits:**
- One change to `convention-detection.md` propagates to all agents — no drift
- Users never need to specify their style target; it's inferred from project files
- The detected target is logged at session start, so users can verify it was detected correctly
- Adding a new convention target (e.g., Shopify Ruby Style Guide) requires editing one file

**Trade-offs:**
- If `.rubocop.yml` exists but is empty or minimal, the cascade still selects RuboCop — potentially applying stricter rules than the user expects
- Projects with both `.rubocop.yml` and `standard` in Gemfile (a misconfiguration) will always select RuboCop due to cascade ordering
- The `conventions.md` community idiom fallback represents one team's opinion; teams with different idioms must add their own `.rubocop.yml` to override it

**Mitigation:** The orchestrator reports the detected target to the user at the start of each session. Users can override by saying "use StandardRB for this session" — the orchestrator accepts explicit overrides.

---

## Sources

- `skills/rubysmithing/references/convention-detection.md` — canonical cascade definition
- `skills/rubysmithing/references/conventions.md` — community idiom fallback patterns
- `CLAUDE.md` — Convention Detection section and "Convention detection: single source of truth" unique style entry
- `AGENTS.md` — "Detection cascade (stop at first match)" documentation
