# frozen_string_literal: true

require 'test_helper'

module Fictions
  class WarmIndexCacheJobTest < ActiveJob::TestCase
    test 'warms fiction index caches' do
      original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)
      Rails.cache.clear

      WarmIndexCacheJob.perform_now

      assert Rails.cache.exist?('popular_novelty_ids')
      assert Rails.cache.exist?('fiction_index/genres')
      assert Rails.cache.exist?('fiction_index/hero_ad')
    ensure
      Rails.cache = original_cache
    end
  end
end
