# frozen_string_literal: true

require 'test_helper'

module Fictions
  class IndexVariablesManagerTest < ActiveSupport::TestCase
    test 'hot_updates_counts returns fiction_id counts hash' do
      counts = IndexVariablesManager.hot_updates_counts

      assert_kind_of Hash, counts
      counts.each_value { |v| assert_kind_of Integer, v }
    end

    test 'most_reads returns unloaded relation' do
      with_memory_cache do
        result = IndexVariablesManager.most_reads

        assert_kind_of ActiveRecord::Relation, result
        assert_not_predicate result, :loaded?
      end
    end

    test 'most_reads preserves cached id order' do
      with_memory_cache do
        result = IndexVariablesManager.most_reads
        ids = IndexVariablesManager.send(:cached_most_reads_ids)

        assert_equal ids.first(10), result.limit(10).ids if ids.any?
      end
    end

    test 'popular_novelty returns unloaded relation' do
      with_memory_cache do
        result = IndexVariablesManager.popular_novelty

        assert_kind_of ActiveRecord::Relation, result
        assert_not_predicate result, :loaded?
      end
    end

    test 'popular_novelty preserves cached id order' do
      with_memory_cache do
        result = IndexVariablesManager.popular_novelty
        ids = IndexVariablesManager.send(:cached_popular_novelty_ids)

        assert_equal ids, result.ids if ids.any?
      end
    end

    test 'originals are ordered by their latest released chapter' do
      with_memory_cache do
        genre = genres(:original)
        older = fictions(:one)
        newer = fictions(:two)
        [older, newer].each { |fiction| fiction.genres << genre unless fiction.genres.exists?(genre.id) }
        stamp_released_at(chapters(:one), 3.days.ago)
        stamp_released_at(chapters(:two), 2.days.ago)
        stamp_released_at(chapters(:three), 1.hour.ago)

        assert_equal [newer.id, older.id], IndexVariablesManager.originals.ids
      end
    end

    test 'hot_updates returns unloaded relation' do
      result = IndexVariablesManager.hot_updates

      assert_kind_of ActiveRecord::Relation, result
      assert_not_predicate result, :loaded?
    end

    test 'hot_updates preserves cached id order' do
      result = IndexVariablesManager.hot_updates
      ids = IndexHotUpdates.send(:cached_ids)

      assert_equal ids.first(10), result.limit(10).ids if ids.any?
    end

    private

    def stamp_released_at(chapter, time)
      chapter.update_columns(created_at: time, published_at: time) # rubocop:disable Rails/SkipsModelValidations
    end

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
