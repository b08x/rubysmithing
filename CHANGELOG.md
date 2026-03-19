## [unreleased]

### ✨ Features

- *(rubysmithing-context)* Tiered degradation protocol for Context7 unavailability and rate limits: Tier 1 serves stale SQLite cache with warning block, Tier 2 retries with pre-mapped gem-registry ID, Tier 3 injects `[WARNING: Unverified API Syntax]` as last resort — generation never blocked
- *(rubysmithing-context)* `fetch_stale` method on `ContextCache` returns expired entries flagged with `stale: true` and `age_days` for Tier 1 fallback use
- *(rubysmithing-context)* `staleness_warning` method generates context-appropriate warning blocks (stale-cache variant vs never-cached variant)
- *(rubysmithing-context)* `stale <gem>` CLI subcommand exposes stale fetch + warning block from the terminal
- *(rubysmithing-context)* Rate limit handling: marks gem as do-not-retry for the session, serves from cache immediately without re-attempting Context7
- *(rubysmithing)* Added `rubysmithing-yardoc` to hub companion skills table — fully registered in routing

### 🐛 Bug Fixes

- *(rubysmithing-context)* `context_cache.rb` schema was missing the `ttl_days` column documented in `SKILL.md`; fixed in `migrate!` with backward-compatible `ALTER TABLE` guard for existing databases

### 🚜 Refactor

- *(skills)* Reorganize and refine rubysmithing suite to v1.0
- *(convention-detection)* Extracted 4-level convention detection cascade from 5+ inline locations into single canonical file `rubysmithing/references/convention-detection.md`; all skills now reference it by name
- *(lite-mode)* Clarified Lite Mode threshold: "single-file output ≤50 lines" — multi-file scaffold requests now always trigger Standard Mode regardless of per-file line count

### 📚 Documentation

- Initialize project with README and CHANGELOG
- Update README for v1.0 reorganization and modes
- *(rubysmithing-yardoc)* Added `requires: [rubysmithing-context]` frontmatter and Step 0 gem context check — type annotations for non-stdlib gems now use verified API shapes
- *(skill-frontmatter)* Added `requires:` field to all `SKILL.md` frontmatter providing machine-readable dependency declarations for the executing agent
- *(gem-registry)* Added `last_verified` (YYYY-MM) column to all tables in `gem-registry.md` with staleness guidance note; entries older than 3 months flagged for re-verification
- Update README and CHANGELOG to reflect SIFT report mitigations
