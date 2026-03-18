# Gem Registry — Context7 IDs × Architectural Roles

Cross-reference of the project gem stack with Context7 library IDs, architectural
planes, and common usage patterns. Used by rubysmithing-context to resolve library
IDs without a resolve step, and by rubysmithing-genai/tui for stack-aware scaffolding.

Last updated: 2026-03

---

## Runtime Spine (Boot + Wiring)

| Gem | Context7 ID | Role | Notes |
|---|---|---|---|
| dotenv | — | Env var loader | No Context7 entry; API is stable (`Dotenv.load`) |
| tty-config | — | Config loader | No Context7 entry; check rubydoc.info |
| zeitwerk | — | Code autoloader | No Context7 entry; API is stable |
| rake | — | Task automation | No Context7 entry |
| journald-logger | — | Structured logging | No Context7 entry |

---

## CLI & Terminal UI Layer

| Gem | Context7 ID | Role | Key Patterns |
|---|---|---|---|
| bubbletea | `/marcoroth/bubbletea-ruby` | TUI framework (Elm arch) | Model / Update / View lifecycle; 48 snippets |
| lipgloss | `/marcoroth/lipgloss-ruby` | Terminal styling | Style composition, join_horizontal/vertical; 72 snippets |
| bubblezone | `/marcoroth/bubblezone-ruby` | Mouse events | Zone registration, click detection; 53 snippets |
| gum | `/marcoroth/gum-ruby` | Shell UI utilities | choose, input, confirm wrappers; 72 snippets |
| bubbles | `/marcoroth/bubbles-ruby` | TUI components | List, TextArea, Spinner, Progress |
| glamour | `/marcoroth/glamour-ruby` | Markdown rendering | Render markdown strings in terminal |
| harmonica | `/marcoroth/harmonica-ruby` | Animation/transitions | Spring physics for UI transitions |
| huh | `/marcoroth/huh-ruby` | Form builder | Form groups, Select, Input, Confirm |
| ntcharts | `/marcoroth/ntcharts-ruby` | Terminal charts | Line, Bar, Scatter charts |
| highline | — | CLI fallback | No Context7 entry; legacy/fallback only |
| drydock | — | CLI framework | No Context7 entry |

---

## Storage & Persistence

| Gem | Context7 ID | Role | Key Patterns |
|---|---|---|---|
| sequel | `/jeremyevans/sequel` | Database toolkit / ORM | Dataset API, migrations, plugins |
| pgvector | `/pgvector/pgvector` | Vector similarity search | `vector` column type, `<=>` operator, `nearest_neighbors` |
| pg | — | PostgreSQL driver | No Context7 entry; used via sequel |
| redis | — | Redis client | No Context7 entry; API is stable |
| redic | — | Lightweight Redis client | No Context7 entry |
| ohm | — | Redis object modeling | No Context7 entry |
| ohm-contrib | — | Ohm extensions | No Context7 entry |

---

## Async, Networking & Orchestration

| Gem | Context7 ID | Role | Key Patterns |
|---|---|---|---|
| async | `/socketry/async` | Fiber concurrency | `Async { }` blocks, `Async::Task`, barriers |
| falcon | `/socketry/falcon` | Async HTTP server | Rack-compatible, fiber scheduler |
| gush | `/chaps-io/gush` | DAG workflow engine | Job definition, workflow creation, Redis backend |
| faraday | — | HTTP client | No Context7 entry; API is stable |
| circuit_breaker | `/wsargent/circuit_breaker` | Circuit breaker | State machine-based, thread-safe |

---

## AI / NLP Layer

| Gem | Context7 ID | Role | Key Patterns |
|---|---|---|---|
| ruby_llm | `/crmne/ruby_llm` | Unified LLM interface | `.chat`, `.embed`, tool definitions, streaming |
| ruby_llm-mcp | — | MCP integration | No Context7 entry; check crmne/ruby_llm-mcp |
| ruby_llm-schema | `/danielfriis/ruby_llm-schema` | Structured outputs | Schema validation on LLM responses |
| dspy.rb | `/vicentereig/dspy.rb` | LLM programming framework | Signatures, Predict, ChainOfThought, ReAct |
| dspy-ruby_llm | — | DSPy ↔ RubyLLM adapter | No Context7 entry |
| informers | `/ankane/informers` | Local transformer inference | Embedding and classification models |
| ruby-spacy | `/yohasebe/ruby-spacy` | spaCy NLP via Ruby | Pipeline loading, entity extraction, parsing |
| deepsearch-rb | — | Web research | No Context7 entry |

**Additional Context7 docs for AI layer:**

- `/websites/rubyllm` — RubyLLM website docs (use for high-level patterns)
- `/websites/spacy_io` — spaCy docs (use alongside ruby-spacy for pipeline concepts)
- `/explosion/spacy-llm` — spaCy LLM integration patterns
- `/huggingface/sentence-transformers` — sentence embedding concepts

---

## Data Processing

| Gem | Context7 ID | Role | Key Patterns |
|---|---|---|---|
| pragmatic_segmenter | `/diasks2/pragmatic_segmenter` | Sentence segmentation | `PragmaticSegmenter::Segmenter.new(text:).segment` |
| front_matter_parser | — | YAML frontmatter extraction | No Context7 entry |
| jsonl | — | JSON Lines parser | No Context7 entry |
| yajl-ruby | — | Streaming JSON parser | No Context7 entry |

---

## Algorithms / Knowledge Structures

| Gem | Context7 ID | Role | Notes |
|---|---|---|---|
| algorithms | — | Data structures | No Context7 entry |
| rubyfca | — | Formal Concept Analysis | No Context7 entry |
| gemoji | — | Emoji lookup | No Context7 entry; CLI rendering only |

---

## Validation & Types

| Gem | Context7 ID | Role | Key Patterns |
|---|---|---|---|
| dry-schema | `/dry-rb/dry-schema` | Schema validation | `Dry::Schema.Params`, `.call`, `.errors` |
| dry-types | `/dry-rb/dry-types` | Type system | `Types::Strict::String`, coercion |

---

## MCP Tooling

| Gem | Context7 ID | Role | Notes |
|---|---|---|---|
| fast-mcp | `/yjacquin/fast-mcp` | Fast MCP server | Tool registration, server boot |

---

## Project Archetypes → Required Gem Sets

Use these to determine which gems to resolve via Context7 for a given project type.

### Minimal CLI Tool

```
Runtime spine + drydock/highline + journald-logger
```

### Terminal AI App (basic chatbot)

```
Runtime spine + bubbletea + lipgloss + ruby_llm + circuit_breaker + async
```

### RAG Application

```
Runtime spine + bubbletea + ruby_llm + pgvector + sequel + pg
+ pragmatic_segmenter + async + circuit_breaker
```

### Agent with Tool-Calling

```
Runtime spine + bubbletea + ruby_llm + ruby_llm-mcp + dspy.rb + dspy-ruby_llm
+ async + gush + circuit_breaker + redis + ohm
```

### File Processing / Export Tool (e.g. GDrive browser)

```
Runtime spine + bubbletea + lipgloss + huh + glamour + gum + async + faraday
```

### Full AI Orchestration Stack

```
All gems — use the full emergent architecture diagram from the dependency mapping doc
```
