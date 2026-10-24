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
        Rails.cache.write(IndexVariablesManager::POPULAR_NOVELTY_IDS_CACHE_KEY,
                          [fiction.id, 999_999], expires_in: 1.hour)
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

    test 'latest_updates_for_homepage limits the overfetched pool to the home card count' do
      with_memory_cache do
        ids = (1..12).to_a
        Rails.cache.write(IndexVariablesManager::LATEST_UPDATES_IDS_CACHE_KEY, ids, expires_in: IndexVariablesManager::LATEST_UPDATES_CACHE_EXPIRY)
        loaded_ids = nil
        loaded_limit = nil

        IndexVariablesManager.stub(:load_fictions_by_cached_ids, lambda { |cached_ids, **kwargs|
          loaded_ids = cached_ids
          loaded_limit = kwargs[:limit]
          Fiction.none
        }) do
          IndexVariablesManager.latest_updates_for_homepage
        end

        assert_equal ids, loaded_ids
        assert_equal IndexVariablesManager::LATEST_UPDATES_HOME_LIMIT, loaded_limit
      end
    end

    test 'novelty badges use the recent pool not the ranked cards' do
      with_memory_cache do
        Rails.cache.write(IndexVariablesManager::RECENT_FICTION_IDS_CACHE_KEY, [1, 2, 3], expires_in: 1.hour)
        Rails.cache.write(IndexVariablesManager::POPULAR_NOVELTY_IDS_CACHE_KEY, [1], expires_in: 1.hour)

        assert_equal Set.new([1, 2, 3]), IndexVariablesManager.popular_novelty_ids_for_badges
      end
    end

    test 'badge id sets reuse cached list ids' do
      with_memory_cache do
        Rails.cache.write(IndexVariablesManager::LATEST_UPDATES_IDS_CACHE_KEY, [1, 2, 3], expires_in: 1.hour)

        IndexVariablesManager.stub(:latest_updates_ranked, -> { raise 'cache miss' }) do
          assert_equal Set.new([1, 2, 3]), IndexVariablesManager.latest_updates_ids_for_badges
        end
      end
    end

    test 'originals uses cached ids after first fetch' do
      with_memory_cache do
        IndexVariablesManager.originals

        IndexVariablesManager.stub(:originals_ids_from_db, -> { raise 'cache miss' }) do
          assert_nothing_raised { IndexVariablesManager.originals.load }
        end
      end
    end

    test 'fanfictions uses cached ids after first fetch' do
      with_memory_cache do
        IndexVariablesManager.fanfictions

        IndexVariablesManager.stub(:fanfiction_ids_from_db, -> { raise 'cache miss' }) do
          assert_nothing_raised { IndexVariablesManager.fanfictions.load }
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
