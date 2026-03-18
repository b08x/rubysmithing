#!/usr/bin/env ruby
# frozen_string_literal: true

# rubysmithing-context: Persistent SQLite gem cache via Sequel
# Stores resolved Context7 library IDs and method signatures.
# Cache location: ~/.rubysmithing/context_cache.db
# TTL: 7 days per gem entry
#
# Usage (from rubysmithing-context skill logic):
#   cache = ContextCache.new
#   entry = cache.fetch("ruby_llm")
#   cache.store("ruby_llm", context7_id: "/crmne/ruby_llm", method_sigs: "...", example: "...")

require "sequel"
require "json"
require "fileutils"

module Rubysmithing
  class ContextCache
    DB_DIR  = File.expand_path("~/.rubysmithing")
    DB_PATH = File.join(DB_DIR, "context_cache.db")
    TTL_DAYS = 7

    def initialize
      FileUtils.mkdir_p(DB_DIR)
      @db = Sequel.sqlite(DB_PATH)
      migrate!
    end

    # Returns cached entry hash or nil if missing/stale
    def fetch(gem_name)
      row = @db[:gem_cache].where(gem_name: gem_name).first
      return nil unless row

      age_days = (Time.now - row[:resolved_at]) / 86_400
      return nil if age_days > TTL_DAYS

      {
        gem_name:    row[:gem_name],
        context7_id: row[:context7_id],
        method_sigs: JSON.parse(row[:method_sigs] || "[]"),
        example:     row[:example],
        resolved_at: row[:resolved_at]
      }
    end

    # Upsert a resolved entry
    def store(gem_name, context7_id:, method_sigs: [], example: nil)
      payload = {
        gem_name:    gem_name,
        context7_id: context7_id,
        method_sigs: method_sigs.to_json,
        example:     example,
        resolved_at: Time.now
      }

      if @db[:gem_cache].where(gem_name: gem_name).count.positive?
        @db[:gem_cache].where(gem_name: gem_name).update(payload)
      else
        @db[:gem_cache].insert(payload)
      end
    end

    # Evict a stale or incorrect entry — useful when Context7 returns better docs
    def evict(gem_name)
      @db[:gem_cache].where(gem_name: gem_name).delete
    end

    # List all cached gems with age
    def list
      @db[:gem_cache].select(:gem_name, :context7_id, :resolved_at).map do |row|
        age = ((Time.now - row[:resolved_at]) / 86_400).round(1)
        { gem: row[:gem_name], id: row[:context7_id], age_days: age }
      end
    end

    private

    def migrate!
      @db.create_table?(:gem_cache) do
        String  :gem_name,    null: false, unique: true
        String  :context7_id, null: false
        Text    :method_sigs  # JSON array of signature strings
        Text    :example      # minimal working code example
        Time    :resolved_at, null: false
      end
    end
  end
end

# CLI usage: ruby context_cache.rb list | evict <gem> | check <gem>
if __FILE__ == $PROGRAM_NAME
  require "pp"
  cache = Rubysmithing::ContextCache.new

  case ARGV[0]
  when "list"
    pp cache.list
  when "evict"
    gem_name = ARGV[1] or abort "Usage: evict <gem_name>"
    cache.evict(gem_name)
    puts "Evicted: #{gem_name}"
  when "check"
    gem_name = ARGV[1] or abort "Usage: check <gem_name>"
    result = cache.fetch(gem_name)
    result ? pp(result) : puts("Not cached or stale: #{gem_name}")
  else
    puts "Usage: context_cache.rb [list|evict <gem>|check <gem>]"
  end
end
