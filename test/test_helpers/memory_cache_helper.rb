# frozen_string_literal: true

# Swaps Rails.cache for an in-process store, since the test store is shared and persistent.
module MemoryCacheHelper
  def with_memory_cache
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)
    yield
  ensure
    Rails.cache = original_cache
  end
end
