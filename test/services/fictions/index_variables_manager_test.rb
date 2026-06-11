# frozen_string_literal: true

require 'test_helper'

module Fictions
  class IndexVariablesManagerTest < ActiveSupport::TestCase
    test 'hot_updates_counts returns fiction_id counts hash' do
      counts = IndexVariablesManager.hot_updates_counts

      assert_kind_of Hash, counts
      counts.each_value { |v| assert_kind_of Integer, v }
    end

    test 'most_reads returns a fresh relation ordered by cached ids' do
      result = IndexVariablesManager.most_reads

      assert_kind_of ActiveRecord::Relation, result
      assert_not_predicate result, :loaded?

      ids = IndexVariablesManager.send(:cached_most_reads_ids)
      assert_equal ids.first(10), result.limit(10).ids if ids.any?
    end

    test 'popular_novelty returns a fresh relation ordered by cached ids' do
      result = IndexVariablesManager.popular_novelty

      assert_kind_of ActiveRecord::Relation, result
      assert_not_predicate result, :loaded?

      ids = IndexVariablesManager.send(:cached_popular_novelty_ids)
      assert_equal ids.first(10), result.limit(10).ids if ids.any?
    end

    test 'hot_updates returns a fresh relation ordered by cached ids' do
      result = IndexVariablesManager.hot_updates

      assert_kind_of ActiveRecord::Relation, result
      assert_not_predicate result, :loaded?

      ids = IndexHotUpdates.send(:cached_ids)
      assert_equal ids.first(10), result.limit(10).ids if ids.any?
    end

    test 'most_reads uses cached ids after first fetch' do
      original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)
      Rails.cache.clear

      IndexVariablesManager.most_reads

      IndexVariablesManager.stub(:most_reads_scope, -> { raise 'cache miss' }) do
        assert_nothing_raised { IndexVariablesManager.most_reads.limit(5).load }
      end
    ensure
      Rails.cache = original_cache
    end

    test 'popular_novelty uses cached ids after first fetch' do
      original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)
      Rails.cache.clear

      IndexVariablesManager.popular_novelty

      IndexVariablesManager.stub(:popular_novelty_scope, -> { raise 'cache miss' }) do
        assert_nothing_raised { IndexVariablesManager.popular_novelty.limit(5).load }
      end
    ensure
      Rails.cache = original_cache
    end

    test 'popular_novelty omits deleted fictions from cached ids' do
      original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)
      Rails.cache.clear

      fiction = fictions(:one)
      Rails.cache.write('popular_novelty_ids', [fiction.id, 999_999], expires_in: 1.hour)

      loaded_ids = IndexVariablesManager.popular_novelty.pluck(:id)

      assert_equal [fiction.id], loaded_ids
    ensure
      Rails.cache = original_cache
    end

    test 'hot_updates uses cached ids after first fetch' do
      original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)
      Rails.cache.clear

      IndexVariablesManager.hot_updates

      IndexHotUpdates.stub(:ranked_scope, -> { raise 'cache miss' }) do
        assert_nothing_raised { IndexVariablesManager.hot_updates.limit(5).load }
      end
    ensure
      Rails.cache = original_cache
    end
  end
end
