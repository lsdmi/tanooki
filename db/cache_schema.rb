# frozen_string_literal: true

# This file is the schema for the cache database connection only (solid_cache_entries).
# Maintain via db/cache_migrate; do not dump from the primary schema.

ActiveRecord::Schema[8.0].define(version: 20_260_521_130_000) do
  create_table 'solid_cache_entries', charset: 'utf8mb4', collation: 'utf8mb4_general_ci', force: :cascade do |t|
    t.binary 'key', limit: 1024, null: false
    t.binary 'value', size: :long, null: false
    t.datetime 'created_at', null: false
    t.bigint 'key_hash', null: false
    t.integer 'byte_size', null: false
    t.index ['byte_size'], name: 'index_solid_cache_entries_on_byte_size'
    t.index %w[key_hash byte_size], name: 'index_solid_cache_entries_on_key_hash_and_byte_size'
    t.index ['key_hash'], name: 'index_solid_cache_entries_on_key_hash', unique: true
  end
end
