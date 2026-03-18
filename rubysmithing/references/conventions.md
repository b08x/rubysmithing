# Ruby Conventions Reference

Fallback conventions when no project config is detected.
Covers community idioms, stack-specific patterns, and Zeitwerk compliance rules.

## File & Module Structure

### Zeitwerk Compliance
File paths must mirror module/class hierarchy exactly:
```
lib/my_app/data/processor.rb  →  MyApp::Data::Processor
lib/my_app/agents/chat.rb     →  MyApp::Agents::Chat
```

Root namespace maps to `lib/[app_name]/`. The loader is configured in the entry point:
```ruby
# app.rb / bin/[name]
loader = Zeitwerk::Loader.for_gem  # for gems
# or
loader = Zeitwerk::Loader.new      # for standalone apps
loader.push_dir("#{__dir__}/lib")
loader.setup
```

### Magic Comment
All files must start with:
```ruby
# frozen_string_literal: true
```

## Naming Conventions

| Type | Convention | Example |
|---|---|---|
| Methods | `snake_case` | `process_document` |
| Variables | `snake_case` | `embedding_vector` |
| Classes | `CamelCase` | `DataProcessor` |
| Modules | `CamelCase` | `EmbeddingHelpers` |
| Constants | `SCREAMING_SNAKE` | `MAX_TOKENS` |
| Predicates | `?` suffix | `ready?`, `streaming?` |
| Mutators | `!` suffix | `save!`, `process!` |
| Private helpers | `_` prefix optional | `_build_payload` |

## Method Design

### Keyword Arguments (3+ params)
```ruby
# Bad
def embed(text, model, batch_size, normalize)

# Good
def embed(text:, model: "text-embedding-3-small", batch_size: 100, normalize: true)
```

### Guard Clauses
```ruby
# Bad
def process(doc)
  if doc
    if doc.valid?
      if doc.content.present?
        # ... actual logic
      end
    end
  end
end

# Good
def process(doc)
  return unless doc
  return unless doc.valid?
  return if doc.content.empty?
  # ... actual logic
end
```

### Method Length
- Soft limit: 15 lines
- Hard limit: 30 lines — extract to private methods

## Module Patterns

### Utility Modules (no instance state)
```ruby
# Bad
module TextUtils
  extend self
  def normalize(text) = text.strip.downcase
end

# Good
module TextUtils
  module_function
  def normalize(text) = text.strip.downcase
end
```

### Mixins (instance behavior)
```ruby
module Embeddable
  def embed
    EmbeddingGenerator.run(content: to_s)
  end
end
```

## Value Objects

Use `Struct.new(keyword_init: true)` for simple data containers:
```ruby
EmbeddingResult = Struct.new(
  :vector,
  :model,
  :token_count,
  keyword_init: true
)
```

## Error Handling

### Custom Error Classes
```ruby
module MyApp
  Error = Class.new(StandardError)
  
  module Agents
    AgentError     = Class.new(MyApp::Error)
    TimeoutError   = Class.new(AgentError)
    ToolCallError  = Class.new(AgentError)
  end
end
```

### Never Silently Rescue
```ruby
# Bad
rescue => e
  nil

# Bad
rescue Exception => e  # catches SystemExit, SignalException

# Good
rescue MyApp::Error => e
  logger.error("Operation failed", error: e.message, class: e.class.name)
  raise  # or handle explicitly
```

## Configuration Pattern

Two-tier config (always):
```ruby
# config/application.rb
# frozen_string_literal: true

require "dotenv/load"       # loads .env into ENV
require "tty-config"

module MyApp
  class Configuration
    def self.load
      config = TTY::Config.new
      config.append_path(Dir.home)
      config.append_path(Dir.pwd)
      config.set_from_env("DATABASE_URL", var: "DATABASE_URL")
      config.set_from_env("LLM_API_KEY",  var: "ANTHROPIC_API_KEY")
      config
    end
  end
end
```

## Logging

Always use structured logging, never puts:
```ruby
require "journald/logger"

module MyApp
  LOGGER = Journald::Logger.new("my_app")

  LOGGER.info("Processing document", doc_id: doc.id, size: doc.size)
  LOGGER.error("API call failed",    error: e.message, attempt: attempt)
end
```

## Async Pattern

```ruby
require "async"

# Fiber-based I/O concurrency
Async do |task|
  task.async { fetch_document(url_1) }
  task.async { fetch_document(url_2) }
end

# With barrier (wait for all)
Async do
  barrier = Async::Barrier.new
  urls.each { |url| barrier.async { fetch(url) } }
  barrier.wait
end
```

## Circuit Breaker Pattern

All external API calls must be wrapped:
```ruby
require "breaker_machines"

class LLMClient
  include BreakerMachines::DSL

  circuit_breaker :llm_api,
    threshold: 5,
    timeout: 30,
    reset_timeout: 60

  def complete(prompt)
    with_circuit_breaker(:llm_api) do
      ruby_llm_call(prompt)
    end
  end
end
```
