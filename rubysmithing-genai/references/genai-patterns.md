# GenAI Patterns

Implementation patterns for the AI/NLP layer. Referenced by rubysmithing-genai
before scaffolding. Always verify current API syntax via rubysmithing-context
before generating — these patterns show structure, not guaranteed current syntax.

---

## RubyLLM Chat

### Basic Chat
```ruby
# Always query: /crmne/ruby_llm "chat basic usage"
chat = RubyLLM.chat(model: "claude-sonnet-4-5")
response = chat.ask("What is RAG?")
puts response.content
```

### Streaming
```ruby
chat.ask("Explain embeddings") do |chunk|
  print chunk.content
end
```

### Tool Calling
```ruby
# Define tools as Ruby blocks — verify current tool definition syntax via Context7
chat = RubyLLM.chat(model: "claude-sonnet-4-5")
chat.with_tool(:search) do |query:|
  SearchService.call(query)
end
response = chat.ask("Search for recent AI papers")
```

### Structured Output (ruby_llm-schema)
```ruby
# Query: /danielfriis/ruby_llm-schema "schema validation response"
```

---

## RAG Pipeline

### Document Ingestion
```ruby
# frozen_string_literal: true
# Query: /jeremyevans/sequel "insert batch" and /pgvector/pgvector "vector column insert"

module MyApp
  module RAG
    class Ingester
      def ingest(document:, source:)
        chunks = segment(document)
        embeddings = embed_batch(chunks)
        store_batch(chunks, embeddings, source:)
      end

      private

      def segment(text)
        PragmaticSegmenter::Segmenter.new(text: text).segment
      end

      def embed_batch(chunks)
        # ruby_llm batch embedding — verify current API via Context7
        chunks.map { |chunk| RubyLLM.embed(chunk) }
      end

      def store_batch(chunks, embeddings, source:)
        DB.transaction do
          chunks.zip(embeddings).each do |chunk, embedding|
            DB[:documents].insert(
              content: chunk,
              embedding: embedding.vector,  # pgvector column
              source: source
            )
          end
        end
      end
    end
  end
end
```

### Query / Retrieval
```ruby
module MyApp
  module RAG
    class Retriever
      K = 5  # top-k results

      def retrieve(query:)
        query_embedding = RubyLLM.embed(query).vector
        DB[:documents]
          .select(:content, :source)
          .order(Sequel.lit("embedding <=> ?", query_embedding))
          .limit(K)
          .all
      end
    end
  end
end
```

### Full RAG Chain
```ruby
module MyApp
  module RAG
    class Pipeline
      def run(query:)
        context = Retriever.new.retrieve(query:)
        augmented_prompt = build_prompt(query:, context:)
        RubyLLM.chat.ask(augmented_prompt)
      end

      private

      def build_prompt(query:, context:)
        chunks = context.map { |r| r[:content] }.join("\n\n")
        "Context:\n#{chunks}\n\nQuestion: #{query}"
      end
    end
  end
end
```

---

## DSPy Reasoning Modules

```ruby
# Query: /vicentereig/dspy.rb "signature predict chain of thought"
# Structure — verify syntax via Context7 before use

module MyApp
  module Reasoning
    # Signature defines input/output contract
    class SummarizeSignature < DSPy::Signature
      input :document, type: :string, desc: "Document to summarize"
      output :summary, type: :string, desc: "Concise summary"
      output :key_points, type: :array, desc: "Bullet points"
    end

    # Module uses the signature
    class Summarizer < DSPy::Module
      def initialize
        @predict = DSPy::ChainOfThought.new(SummarizeSignature)
      end

      def forward(document:)
        @predict.call(document: document)
      end
    end
  end
end
```

---

## MCP Server

```ruby
# Query: /yjacquin/fast-mcp "tool definition server boot"
# Structure — verify syntax via Context7

require "fast_mcp"

server = FastMCP::Server.new("my-mcp-server")

server.tool "search_documents",
  description: "Search the document store by semantic similarity",
  parameters: {
    query: { type: "string", description: "Search query" },
    k:     { type: "integer", description: "Number of results", default: 5 }
  } do |query:, k: 5|
    MyApp::RAG::Retriever.new.retrieve(query:, k:).to_json
  end

server.run
```

---

## Embedding Generator (local vs remote)

### Remote (ruby_llm)
```ruby
module MyApp
  module Embeddings
    class RemoteGenerator
      MODEL = "text-embedding-3-small"

      def generate(text)
        RubyLLM.embed(text, model: MODEL)
      end

      def generate_batch(texts)
        texts.map { |t| generate(t) }
      end
    end
  end
end
```

### Local (informers)
```ruby
# Query: /ankane/informers "embedding model usage"
module MyApp
  module Embeddings
    class LocalGenerator
      def initialize
        # Verify current Informers API via Context7
        @model = Informers.pipeline("feature-extraction", "sentence-transformers/all-MiniLM-L6-v2")
      end

      def generate(text)
        @model.call(text)
      end
    end
  end
end
```

---

## NLP Processor (ruby-spacy)

```ruby
# Query: /yohasebe/ruby-spacy "pipeline entity extraction"
module MyApp
  module NLP
    class Processor
      def initialize
        # Verify current ruby-spacy API via Context7
        @nlp = Spacy::Language.new("en_core_web_sm")
      end

      def extract_entities(text)
        doc = @nlp.read(text)
        doc.ents.map { |ent| { text: ent.text, label: ent.label_ } }
      end

      def segment_sentences(text)
        doc = @nlp.read(text)
        doc.sents.map(&:text)
      end
    end
  end
end
```

---

## Async + Circuit Breaker Wrapper (apply to all external calls)

```ruby
# Wrap any LLM call in both async context and circuit breaker
module MyApp
  module AI
    class ResilientClient
      include BreakerMachines::DSL

      circuit_breaker :llm_api,
        threshold: 5,
        timeout: 30,
        reset_timeout: 60

      def call_async(prompt)
        Async do
          with_circuit_breaker(:llm_api) do
            RubyLLM.chat.ask(prompt)
          end
        end
      end
    end
  end
end
```
