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

      assert Rails.cache.exist?(IndexVariablesManager::POPULAR_NOVELTY_IDS_CACHE_KEY)
      assert Rails.cache.exist?('recent_fiction_ids')
    end

    test 'call populates featured novelty chapter count next to popular novelty ids' do
      IndexCacheWarmer.call

      featured_id = Rails.cache.read(IndexVariablesManager::POPULAR_NOVELTY_IDS_CACHE_KEY)&.first

      assert_predicate featured_id, :present?
      assert Rails.cache.exist?(IndexVariablesManager.popular_novelty_featured_chapter_count_cache_key(featured_id))
    end

    test 'call populates most reads ids cache' do
      IndexCacheWarmer.call

      assert Rails.cache.exist?(['most_reads_ids', IndexVariablesManager::MOST_READS_INDEX_CARDS])
    end

    test 'call populates latest updates ids cache' do
      IndexCacheWarmer.call

      assert Rails.cache.exist?(IndexVariablesManager::LATEST_UPDATES_IDS_CACHE_KEY)
    end

    test 'call populates originals ids cache' do
      IndexCacheWarmer.call

      assert Rails.cache.exist?(['fiction_index/originals_ids', IndexVariablesManager::ORIGINALS_INDEX_CARDS])
    end

    test 'call populates fanfiction ids cache' do
      IndexCacheWarmer.call

      assert Rails.cache.exist?(['fiction_index/fanfiction_ids', IndexVariablesManager::FANFICTION_INDEX_CARDS])
    end

    test 'call populates genre spotlight cache' do
      IndexCacheWarmer.call

      assert Rails.cache.exist?(IndexGenreSpotlight.cache_key)
    end
  end
end
