---
name: rubysmithing-genai
description: AI/NLP component scaffolding and advisory sub-skill for Ruby projects. Use when the task involves implementing LLM chat, agents, tool-calling, streaming, RAG pipelines, embedding generation, DSPy reasoning modules, MCP server/client integration, or NLP processing (ruby-spacy, pragmatic_segmenter, informers). Detects whether the request is a scaffolding task (generate a focused implementation file) or an advisory task (explain how to implement X using Y gem) and responds accordingly. Always queries rubysmithing-context for current gem API syntax before generating code.
---

# Rubysmithing — GenAI

Scaffolder and advisor for AI/NLP components in the Ruby terminal-native stack.
Generates single focused implementation files or explains integration patterns,
always against current gem API syntax resolved via rubysmithing-context.

## Stack Reference

This sub-skill operates on the AI/NLP and retrieval planes of the architecture:

```
Reasoning Layer:    dspy.rb + dspy-ruby_llm
LLM Abstraction:    ruby_llm + ruby_llm-mcp + ruby_llm-schema
Transport:          faraday + async + circuit_breaker
Retrieval:          pgvector + sequel + pg
Embeddings:         ruby_llm (embed) + informers (local)
NLP:                ruby-spacy + pragmatic_segmenter
Web Research:       deepsearch-rb
```

Load `references/genai-patterns.md` for implementation patterns for each layer.

## Mode Detection

### Scaffolding Mode
Triggered when the request asks to create, build, implement, generate, or scaffold.
Output: A single focused file (one class, one module, one pipeline).

### Advisory Mode
Triggered when the request asks how to, explain, what's the best way, or compare.
Output: Explanation + minimal code example, no full file unless asked.

## Pre-Generation Checklist

Before writing any implementation code:
1. **Trigger rubysmithing-context** for each gem involved in the implementation
2. **Identify architectural plane** — is this reasoning, retrieval, NLP, or transport?
3. **Confirm async context** — will this run inside an `Async` block? If yes, use non-blocking patterns
4. **Confirm circuit breaker** — all external LLM API calls must be wrapped

## Scaffolding Patterns

### Chatbot / Conversational Agent

```ruby
# lib/my_app/agents/chat_agent.rb
# frozen_string_literal: true
# Uses: ruby_llm, ruby_llm-schema (optional), circuit_breaker
```

Generate:
- `RubyLLM.chat` session setup with model configuration
- Tool definition block if tool-calling requested
- Streaming handler if streaming requested
- Schema validation if structured output requested
- Circuit breaker wrapper around the API call

### RAG Pipeline

```ruby
# lib/my_app/rag/pipeline.rb
# Uses: ruby_llm (embed + chat), pgvector, sequel, pragmatic_segmenter
```

Generate:
- Document ingestion method (segment → embed → store)
- Query method (embed query → pgvector similarity search → rerank → augment → generate)
- Sequel dataset methods for vector operations
- Async-compatible I/O for embedding calls

### DSPy Reasoning Module

```ruby
# lib/my_app/reasoning/[module_name].rb
# Uses: dspy.rb, dspy-ruby_llm
```

Generate:
- Signature definition (input/output fields)
- Module class (Predict, ChainOfThought, or ReAct as appropriate)
- Optimizer setup if requested

### MCP Server

```ruby
# lib/my_app/mcp/server.rb
# Uses: fast-mcp or ruby_llm-mcp
```

Generate:
- Tool definition blocks with input schemas
- Handler methods
- Server boot configuration

### Embedding Pipeline

```ruby
# lib/my_app/embeddings/generator.rb
# Uses: ruby_llm (remote) OR informers (local)
```

Ask user to confirm: remote API (ruby_llm) or local inference (informers)?
Default to ruby_llm unless local/offline operation is explicitly required.

### NLP Processor

```ruby
# lib/my_app/nlp/[processor_name].rb
# Uses: ruby-spacy, pragmatic_segmenter
```

Generate:
- spaCy model loading and pipeline setup
- Entity extraction, dependency parsing, or segmentation as requested

## Output Format

For scaffolded files:
1. **File path** — single focused file, Zeitwerk-compliant path
2. **Complete implementation** — no stubs, no placeholder comments
3. **Required gems** — list any Gemfile additions
4. **Context7 IDs used** — which gem docs were resolved
5. **Integration note** — one paragraph on how this file connects to the broader stack

For advisory responses:
1. **Recommendation** — direct answer, no hedging
2. **Code example** — minimal working snippet, not a full file
3. **Trade-offs** — if multiple approaches exist, name them with one-line trade-offs

## Spec Generation

Generate RSpec specs only when explicitly requested. When requested:
- Stub external LLM calls with VCR or manual doubles
- Test the reasoning logic, not the API response
- File: `spec/[path_matching_lib_file]_spec.rb`
