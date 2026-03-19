#!/usr/bin/env ruby
# frozen_string_literal: true

# rubysmithing-context: Persistent SQLite gem cache via Sequel
# Stores resolved Context7 library IDs and method signatures.
# Cache location: ~/.rubysmithing/context_cache.db
# TTL: 7 days per gem entry (configurable per-entry via ttl_days column)
#
# Usage (from rubysmithing-context skill logic):
#   cache = ContextCache.new
#
#   # Normal fetch — returns nil if missing or past TTL
#   entry = cache.fetch("ruby_llm")
#
#   # Stale fetch — returns expired entries when Context7 is unavailable
#   entry = cache.fetch_stale("ruby_llm")   # => entry with stale: true
#
#   # Store a resolved entry
#   cache.store("ruby_llm", context7_id: "/crmne/ruby_llm", method_sigs: "...", example: "...")
#
#   # Generate warning block for stale/unverified usage
#   puts cache.staleness_warning("ruby_llm", entry)

require "sequel"
require "json"
require "fileutils"

module Rubysmithing
  class ContextCache
    DB_DIR   = File.expand_path("~/.rubysmithing")
    DB_PATH  = File.join(DB_DIR, "context_cache.db")
    TTL_DAYS = 7

    def initialize
      FileUtils.mkdir_p(DB_DIR)
      @db = Sequel.sqlite(DB_PATH)
      migrate!
    end

    # Returns cached entry hash or nil if missing or past TTL.
    # Use this for the normal hot-path lookup.
    def fetch(gem_name)
      row = @db[:gem_cache].where(gem_name: gem_name).first
      return nil unless row

      ttl = row[:ttl_days] || TTL_DAYS
      age_days = (Time.now - row[:resolved_at]) / 86_400
      return nil if age_days > ttl

      deserialize(row).merge(stale: false)
    end

    # Returns cached entry even if past TTL, flagged as stale.
    # Use this as Tier 1 fallback when Context7 is unavailable or rate-limited.
    # Returns nil only if the gem has never been cached at all.
    def fetch_stale(gem_name)
      row = @db[:gem_cache].where(gem_name: gem_name).first
      return nil unless row

      ttl = row[:ttl_days] || TTL_DAYS
      age_days = (Time.now - row[:resolved_at]) / 86_400

      deserialize(row).merge(
        stale: age_days > ttl,
        age_days: age_days.round(1)
      )
    end

    # Upsert a resolved entry. ttl_days defaults to TTL_DAYS (7).
    def store(gem_name, context7_id:, method_sigs: [], example: nil, ttl_days: TTL_DAYS)
      payload = {
        gem_name:    gem_name,
        context7_id: context7_id,
        method_sigs: method_sigs.to_json,
        example:     example,
        resolved_at: Time.now,
        ttl_days:    ttl_days
      }

      if @db[:gem_cache].where(gem_name: gem_name).count.positive?
        @db[:gem_cache].where(gem_name: gem_name).update(payload)
      else
        @db[:gem_cache].insert(payload)
      end
    end

    # Evict a stale or incorrect entry — useful when Context7 returns better docs.
    def evict(gem_name)
      @db[:gem_cache].where(gem_name: gem_name).delete
    end

    # List all cached gems with age and staleness status.
    def list
      @db[:gem_cache].select(:gem_name, :context7_id, :resolved_at, :ttl_days).map do |row|
        ttl  = row[:ttl_days] || TTL_DAYS
        age  = ((Time.now - row[:resolved_at]) / 86_400).round(1)
        {
          gem:       row[:gem_name],
          id:        row[:context7_id],
          age_days:  age,
          ttl_days:  ttl,
          status:    age > ttl ? :stale : :fresh
        }
      end
    end

    # Generates a warning comment block to inject above code using a stale or
    # unresolved gem. Pass entry: nil to produce an unverified (never-cached) block.
    def staleness_warning(gem_name, entry: nil)
      if entry&.fetch(:stale, false)
        age = entry[:age_days]
        cached_at = entry[:resolved_at]&.strftime("%Y-%m-%d") || "unknown"
        <<~WARNING
          # [WARNING: Stale API Syntax — Context7 Unavailable]
          # Could not reach Context7 to refresh documentation for: #{gem_name}
          # Falling back to cached data last verified: #{cached_at} (#{age} days ago)
          # This code MAY be outdated. Verify against: https://rubygems.org/gems/#{gem_name}
          # Re-run after Context7 is reachable to refresh: cache.evict("#{gem_name}")
        WARNING
      else
        <<~WARNING
          # [WARNING: Unverified API Syntax]
          # Context7 could not resolve documentation for: #{gem_name}
          # The following code is based on training data and MAY be outdated or incorrect.
          # Verify against: https://rubygems.org/gems/#{gem_name} before use.
          # Run: bundle exec ruby -e "require '#{gem_name}'; puts #{gem_name.gsub('-','_').split('_').map(&:capitalize).join}::VERSION rescue nil"
        WARNING
      end
    end

    private

    def deserialize(row)
      {
        gem_name:    row[:gem_name],
        context7_id: row[:context7_id],
        method_sigs: JSON.parse(row[:method_sigs] || "[]"),
        example:     row[:example],
        resolved_at: row[:resolved_at],
        ttl_days:    row[:ttl_days] || TTL_DAYS
      }
    end

    def migrate!
      @db.create_table?(:gem_cache) do
        String  :gem_name,    null: false, unique: true
        String  :context7_id, null: false
        Text    :method_sigs  # JSON array of signature strings
        Text    :example      # minimal working code example
        Time    :resolved_at, null: false
        Integer :ttl_days,    default: 7
      end

      # Add ttl_days column to existing databases that predate this schema version.
      unless @db[:gem_cache].columns.include?(:ttl_days)
        @db.alter_table(:gem_cache) { add_column :ttl_days, Integer, default: 7 }
      end
    end
  end
end

# CLI usage: ruby context_cache.rb list | evict <gem> | check <gem> | stale <gem>
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
    result ? pp(result) : puts("Not cached or past TTL: #{gem_name}")
  when "stale"
    # Fetch even if stale — used to inspect fallback data quality
    gem_name = ARGV[1] or abort "Usage: stale <gem_name>"
    result = cache.fetch_stale(gem_name)
    if result
      pp result
      puts cache.staleness_warning(gem_name, entry: result) if result[:stale]
    else
      puts "Never cached: #{gem_name}"
    end
  else
    puts "Usage: context_cache.rb [list|evict <gem>|check <gem>|stale <gem>]"
  end
end
