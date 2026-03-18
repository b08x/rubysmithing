# Routing Guide — Sub-skill Escalation Heuristics

Reference for the hub SKILL.md router. Maps intent signals to the correct sub-skill.
When a request matches multiple signals, prefer the most specific sub-skill.

---

## Signal → Sub-skill Mapping

### rubysmithing-context triggers
Fire before any other sub-skill when:
- User names a specific gem (any gem, not just curated ones)
- Request involves a specific method/API pattern ("how do I do X with sequel")
- Gem hasn't been resolved in this session yet

Never fire for: stdlib only, generic Ruby patterns, already-resolved gems.

---

### rubysmithing-genai triggers

**Strongest signals (always escalate):**
- "chatbot", "chat agent", "conversational AI"
- "RAG", "retrieval augmented generation", "vector search", "semantic search"
- "embedding", "embed documents", "pgvector"
- "DSPy", "reasoning module", "chain of thought", "ReAct"
- "MCP server", "MCP tool", "model context protocol"
- "agent", "tool-calling", "function calling"
- "streaming response", "stream from LLM"
- "ruby_llm", "RubyLLM"

**Moderate signals (escalate unless clearly simpler):**
- "NLP", "entity extraction", "named entity recognition"
- "sentence segmentation", "chunking", "document processing"
- "local inference", "informers"
- "prompt template", "prompt pipeline"
- "spaCy", "ruby-spacy"

---

### rubysmithing-tui triggers

**Strongest signals (always escalate):**
- "TUI", "terminal UI", "terminal interface"
- "BubbleTea", "bubbletea", "Lipgloss", "Huh", "Gum", "NTCharts"
- "file browser", "file picker", "directory browser"
- "dashboard", "control panel", "monitor"
- "human in the loop", "HIL component", "review interface"
- "interactive terminal", "terminal app"

**Moderate signals (escalate unless clearly simpler):**
- "form", "interactive prompt" (when more than one field)
- "progress bar", "spinner" (when inside a larger UI)
- "keyboard navigation", "cursor movement"
- "split pane", "sidebar", "panel layout"

---

### rubysmithing-refactor triggers

**Strongest signals (always escalate):**
- "refactor", "clean up", "fix conventions"
- "this code is messy", "help me improve this"
- "anti-patterns", "rubocop violations"
- "Zeitwerk compliance", "autoload issue"
- "make this idiomatic"

---

### rubysmithing-report triggers

**Strongest signals (always escalate):**
- "assess", "audit", "review this project"
- "what's wrong with this code"
- "code quality report", "convention violations"
- "score my code", "how compliant is this"

---

## Handle Directly (no escalation)

Generate code directly in the hub for:

| Request type | Examples |
|---|---|
| PORO / value object | "Create a struct for an embedding result" |
| Rake task | "Write a rake task to run ingestion" |
| Config wiring | "Set up zeitwerk for this project" |
| Boot layer | "Wire dotenv and tty-config together" |
| Simple utility module | "Write a text normalizer module" |
| Gemfile editing | "Add pgvector and sequel to the Gemfile" |
| Error class hierarchy | "Define error classes for my AI module" |
| Data pipeline (no AI) | "Parse JSONL files and insert into Sequel" |

---

## Ambiguous Signals → Ask

When the request is ambiguous between two sub-skills, ask one clarifying question:

- "scaffold a chatbot" with no UI mention → ask: "Terminal UI with BubbleTea, or headless class?"
- "build a document processor" → ask: "RAG pipeline with embeddings, or plain text processing?"
- "create an agent" → ask: "MCP-based tool-calling agent, or DSPy reasoning module?"
