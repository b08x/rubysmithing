# Walkthrough: Text Processing Gem

Build a publishable Ruby gem for text normalization and tokenization — from gemsmith scaffold through core implementation, YARD documentation, and QA assessment.

This walkthrough exercises: `rubysmithing-scaffold` → `rubysmithing-context` → `rubysmithing` (main) → `rubysmithing-yardoc` → `rubysmithing-report`.

---

## What We're Building

A gem called `text_normalizer` that:

- Normalizes Unicode text (NFC, lowercase, strip accents)
- Tokenizes strings into word/sentence tokens
- Filters stop words
- Exposes a simple pipeline API: `TextNormalizer::Pipeline.new.call(text) → Result`

Uses: `dry-schema` for input validation, `zeitwerk` for autoloading, `journald-logger` for structured logging.

---

## Phase 1: Scaffold the Gem

### Prerequisite

Ensure gemsmith is configured:

```bash
gemsmith --edit
# Fill in: name, email, github_handle
```

### Request

```
Create a new gem called text_normalizer for publishing to rubygems.org —
with RSpec, Zeitwerk, and GitHub Actions CI
```

`rubysmithing-scaffold` selects `gemsmith`, assembles:

```
Tool:    gemsmith
Project: text_normalizer
Flags:   --rspec --zeitwerk --github
Command: gemsmith build text_normalizer --rspec --zeitwerk --github
```

After execution, the skeleton:

```
text_normalizer/
├── text_normalizer.gemspec
├── Gemfile
├── Rakefile
├── lib/
│   ├── text_normalizer.rb        # Zeitwerk entry point
│   └── text_normalizer/
│       └── version.rb
├── spec/
│   ├── spec_helper.rb
│   └── text_normalizer_spec.rb
└── .github/
    └── workflows/
        └── ci.yml
```

### Apply Standard Mode hardening

```
Apply Standard Mode conventions to the scaffold
```

The agent adds:
- `# frozen_string_literal: true` to all `.rb` files
- `journald-logger` to `Gemfile`
- `dry-schema` and `dry-types` to `Gemfile`

---

## Phase 2: Plan the Architecture

Before generating any code, describe the full structure you want:

```
In the text_normalizer gem, I need:
- TextNormalizer::Normalizer — handles Unicode NFC, lowercase, accent stripping
- TextNormalizer::Tokenizer — splits text into word tokens or sentence tokens (configurable)
- TextNormalizer::StopWordFilter — filters a configurable stop word list
- TextNormalizer::Pipeline — chains the above three in sequence, validates input
  with dry-schema, returns a Result struct with tokens and metadata
- TextNormalizer::Result — value object: tokens, original_text, processing_time_ms
```

The orchestrator detects multiple files → Standard Mode. It checks for non-stdlib gems (dry-schema, dry-types, journald-logger) → runs `rubysmithing-context` for each before generating.

---

## Phase 3: Verify Gem APIs

The orchestrator runs `rubysmithing-context` automatically, but you can pre-warm:

```
/rubysmithing:context dry-schema
/rubysmithing:context dry-types
```

This fetches current method signatures. Example verified output:

```ruby
# dry-schema (verified via Context7)
schema = Dry::Schema.Params do
  required(:text).filled(:string)
  optional(:mode).value(included_in?: %i[word sentence])
end
result = schema.call(text: "hello world", mode: :word)
result.success?  # => true
result.errors    # => {}
```

---

## Phase 4: Generate Core Classes

With APIs verified, request the implementation:

```
Generate TextNormalizer::Pipeline and TextNormalizer::Result using Standard Mode
conventions — Zeitwerk, dry-schema input validation, journald-logger, Result
as a Struct with keyword_init
```

Sample generated `lib/text_normalizer/pipeline.rb`:

```ruby
# frozen_string_literal: true

module TextNormalizer
  # Chains Normalizer → Tokenizer → StopWordFilter in sequence.
  # Validates input with dry-schema; returns a Result value object.
  class Pipeline
    SCHEMA = Dry::Schema.Params do
      required(:text).filled(:string)
      optional(:mode).value(included_in?: %i[word sentence]).default(:word)
    end

    def initialize(normalizer: Normalizer.new,
                   tokenizer: Tokenizer.new,
                   filter: StopWordFilter.new,
                   logger: Journald::Logger.new("text_normalizer.pipeline"))
      @normalizer = normalizer
      @tokenizer  = tokenizer
      @filter     = filter
      @logger     = logger
    end

    def call(text:, mode: :word)
      validation = SCHEMA.call(text:, mode:)
      raise ArgumentError, validation.errors.to_h.inspect unless validation.success?

      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      normalized = @normalizer.call(text)
      tokens     = @tokenizer.call(normalized, mode:)
      filtered   = @filter.call(tokens)
      elapsed    = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round(2)

      @logger.info("pipeline complete", token_count: filtered.size, mode:, ms: elapsed)

      Result.new(tokens: filtered, original_text: text, processing_time_ms: elapsed)
    end
  end
end
```

Note what Standard Mode applied automatically:
- `frozen_string_literal: true`
- `dry-schema` validation at the system boundary
- `journald-logger` (not `puts`)
- Keyword arguments (3+ parameters)
- `Struct.new(keyword_init: true)` for Result

---

## Phase 5: Generate the Normalizer and Tokenizer

```
Generate TextNormalizer::Normalizer using Ruby's unicode_normalize and standard
string methods — no gem dependencies, Lite Mode is fine for this one
```

For Lite Mode (single file, stdlib only):

```ruby
# frozen_string_literal: true

module TextNormalizer
  class Normalizer
    def call(text)
      text.unicode_normalize(:nfc)
          .downcase
          .gsub(/\p{M}/, "")
    end
  end
end
```

```
Generate TextNormalizer::Tokenizer — word mode splits on \b, sentence mode
splits on sentence-ending punctuation
```

---

## Phase 6: Generate YARD Documentation

With implementation in place:

```
/rubysmithing:yardoc lib/text_normalizer/pipeline.rb
```

`rubysmithing-yardoc` uses AST analysis and type inference to generate:

```ruby
# frozen_string_literal: true

module TextNormalizer
  # Chains Normalizer → Tokenizer → StopWordFilter in sequence.
  # Validates input with dry-schema; returns a {Result} value object.
  #
  # @example Basic usage
  #   pipeline = TextNormalizer::Pipeline.new
  #   result = pipeline.call(text: "Hello, World!")
  #   result.tokens  # => ["hello", "world"]
  #
  # @example Sentence tokenization
  #   result = pipeline.call(text: "Hello. How are you?", mode: :sentence)
  #   result.tokens  # => ["Hello.", "How are you?"]
  class Pipeline

    # @param normalizer [TextNormalizer::Normalizer]
    # @param tokenizer [TextNormalizer::Tokenizer]
    # @param filter [TextNormalizer::StopWordFilter]
    # @param logger [Journald::Logger]
    def initialize(normalizer: Normalizer.new,
                   tokenizer: Tokenizer.new,
                   filter: StopWordFilter.new,
                   logger: Journald::Logger.new("text_normalizer.pipeline"))

    # Normalizes, tokenizes, and filters the input text.
    #
    # @param text [String] the text to process
    # @param mode [Symbol] tokenization mode — :word (default) or :sentence
    # @return [TextNormalizer::Result]
    # @raise [ArgumentError] if text is blank or mode is invalid
    def call(text:, mode: :word)
```

---

## Phase 7: QA Assessment

```
/rubysmithing:report lib/text_normalizer/
```

`rubysmithing-report` runs SIFT Protocol V1.0 across all files. For 3+ files, meta-judge generates a scored footer. Example summary:

```
SIFT Protocol V1.0 — TextNormalizer

Convention compliance:     PASS  (frozen_string_literal ✓, Zeitwerk ✓, module_function ✓)
Input validation:          PASS  (dry-schema at Pipeline boundary)
Error handling:            PASS  (ArgumentError raised with schema errors)
Logging:                   PASS  (journald-logger, no puts)
External call protection:  N/A   (no external calls in this gem)

Score: 4.5/5.0 — PASS

Suggestions:
- Consider adding a circuit_breaker if future versions call external
  services (e.g., NLP APIs)
- StopWordFilter hardcodes English — expose language config via constructor
```

---

## Summary

| Phase | Agent | Output |
|:------|:------|:-------|
| Scaffold | `rubysmithing-scaffold` | gemsmith skeleton + Standard Mode hardening |
| API verification | `rubysmithing-context` | Verified dry-schema, dry-types method signatures |
| Core implementation | `rubysmithing` (main) | Pipeline, Result, Normalizer, Tokenizer, StopWordFilter |
| Documentation | `rubysmithing-yardoc` | @param, @return, @example tags on all public methods |
| QA | `rubysmithing-report` | SIFT score + improvement suggestions |

---

## Related

- [New Project Walkthrough](new-project.md) — scaffold options in detail
- [Architecture: convention detection](../architecture.md#convention-detection)
- [Glossary: Standard Mode, dry-schema, Zeitwerk, SIFT Protocol](../glossary.md)
