# frozen_string_literal: true

require 'test_helper'

module Fictions
  class IndexVariablesManagerTest < ActiveSupport::TestCase
    test 'hot_updates_counts returns fiction_id counts hash' do
      counts = IndexVariablesManager.hot_updates_counts

      assert_kind_of Hash, counts
      counts.each_value { |v| assert_kind_of Integer, v }
    end

    test 'most_reads returns a materialized array' do
      result = IndexVariablesManager.most_reads

      assert_kind_of Array, result
      result.each { |fiction| assert_kind_of Fiction, fiction }
    end

    test 'hot_updates returns a fresh relation ordered by cached ids' do
      result = IndexVariablesManager.hot_updates

      assert_kind_of ActiveRecord::Relation, result
      assert_not_predicate result, :loaded?

      ids = IndexVariablesManager.send(:cached_hot_updates_ids)
      assert_equal ids.first(10), result.limit(10).ids if ids.any?
    end

    test 'most_reads uses cache after first fetch' do
      original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)
      Rails.cache.clear

      first = IndexVariablesManager.most_reads

      IndexVariablesManager.stub(:most_reads_scope, -> { raise 'cache miss' }) do
        second = IndexVariablesManager.most_reads

        assert_equal first.map(&:id), second.map(&:id)
      end
    ensure
      Rails.cache = original_cache
    end

    test 'hot_updates uses cached ids after first fetch' do
      original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)
      Rails.cache.clear

      IndexVariablesManager.hot_updates

      IndexVariablesManager.stub(:hot_updates_ranked_scope, -> { raise 'cache miss' }) do
        assert_nothing_raised { IndexVariablesManager.hot_updates.limit(5).load }
      end
    ensure
      Rails.cache = original_cache
    end
  end
end
