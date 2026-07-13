# frozen_string_literal: true

require 'test_helper'

module Fictions
  class IndexVariablesManagerCacheTest < ActiveSupport::TestCase
    test 'most_reads uses cached ids after first fetch' do
      with_memory_cache do
        IndexVariablesManager.most_reads

        IndexVariablesManager.stub(:most_reads_scope, -> { raise 'cache miss' }) do
          assert_nothing_raised { IndexVariablesManager.most_reads.limit(5).load }
        end
      end
    end

    test 'popular_novelty uses cached ids after first fetch' do
      with_memory_cache do
        IndexVariablesManager.popular_novelty

        IndexVariablesManager.stub(:popular_novelty_scope, -> { raise 'cache miss' }) do
          assert_nothing_raised { IndexVariablesManager.popular_novelty.limit(5).load }
        end
      end
    end

    test 'popular_novelty omits deleted fictions from cached ids' do
      with_memory_cache do
        fiction = fictions(:one)
        Rails.cache.write('popular_novelty_ids', [fiction.id, 999_999], expires_in: 1.hour)

        loaded_ids = IndexVariablesManager.popular_novelty.pluck(:id)

        assert_equal [fiction.id], loaded_ids
      end
    end

    test 'hot_updates uses cached ids after first fetch' do
      with_memory_cache do
        IndexVariablesManager.hot_updates

        IndexHotUpdates.stub(:ranked_scope, -> { raise 'cache miss' }) do
          assert_nothing_raised { IndexVariablesManager.hot_updates.limit(5).load }
        end
      end
    end

    test 'latest_updates uses cached ids after first fetch' do
      with_memory_cache do
        IndexVariablesManager.latest_updates

        IndexVariablesManager.stub(:latest_updates_ranked, -> { raise 'cache miss' }) do
          assert_nothing_raised { IndexVariablesManager.latest_updates.limit(5).load }
        end
      end
    end

    test 'latest_updates_for_homepage loads only eight cached ids' do
      with_memory_cache do
        ids = (1..12).to_a
        Rails.cache.write('latest_updates_ids', ids, expires_in: 30.minutes)
        loaded_ids = nil

        IndexVariablesManager.stub(:load_fictions_by_cached_ids, lambda { |cached_ids, **|
          loaded_ids = cached_ids
          Fiction.none
        }) do
          IndexVariablesManager.latest_updates_for_homepage
        end

        assert_equal ids.first(8), loaded_ids
      end
    end

    test 'badge id sets reuse cached list ids' do
      with_memory_cache do
        Rails.cache.write('latest_updates_ids', [1, 2, 3], expires_in: 1.hour)

        IndexVariablesManager.stub(:latest_updates_ranked, -> { raise 'cache miss' }) do
          assert_equal Set.new([1, 2, 3]), IndexVariablesManager.latest_updates_ids_for_badges
        end
      end
    end

    test 'filtered_by_genre uses cached ids after first fetch' do
      with_memory_cache do
        genre = genres(:one)

        IndexVariablesManager.filtered_by_genre(genre)

        IndexVariablesManager.stub(:filtered_fiction_ids_for_genre, ->(_genre_id) { raise 'cache miss' }) do
          assert_nothing_raised { IndexVariablesManager.filtered_by_genre(genre).load }
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
