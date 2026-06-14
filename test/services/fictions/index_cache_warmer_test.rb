# frozen_string_literal: true

require 'test_helper'

module Fictions
  class IndexCacheWarmerTest < ActiveSupport::TestCase
    setup do
      @original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)
      Rails.cache.clear
    end

    teardown do
      Rails.cache = @original_cache
    end

    test 'call warms index caches without error' do
      assert_nothing_raised { IndexCacheWarmer.call }
    end

    test 'call populates popular novelty ids cache' do
      IndexCacheWarmer.call

      assert Rails.cache.exist?('popular_novelty_ids')
    end

    test 'call populates most reads ids cache' do
      IndexCacheWarmer.call

      assert Rails.cache.exist?('most_reads_ids')
    end

    test 'call populates latest updates ids cache' do
      IndexCacheWarmer.call

      assert Rails.cache.exist?('latest_updates_ids')
    end
  end
end
