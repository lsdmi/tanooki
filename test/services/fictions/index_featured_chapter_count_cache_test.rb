# frozen_string_literal: true

require 'test_helper'

module Fictions
  class IndexFeaturedChapterCountCacheTest < ActiveSupport::TestCase
    test 'featured novelty chapter count is cached after first fetch' do
      with_memory_cache do
        count = IndexVariablesManager.popular_novelty_featured_chapter_count
        featured_id = IndexVariablesManager.send(:cached_popular_novelty_ids).first

        assert_kind_of Integer, count
        assert_equal Chapter.released.where(fiction_id: featured_id).count, count if featured_id

        Chapter.stub(:released, -> { raise 'cache miss' }) do
          assert_equal count, IndexVariablesManager.popular_novelty_featured_chapter_count
        end
      end
    end

    private

    def with_memory_cache
      original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)
      Rails.cache.clear
      yield
    ensure
      Rails.cache = original_cache
    end
  end
end
