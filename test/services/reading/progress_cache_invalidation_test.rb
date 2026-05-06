# frozen_string_literal: true

require 'test_helper'

module Reading
  class ProgressCacheInvalidationTest < ActiveSupport::TestCase
    def setup
      @user = users(:user_one)
      @fiction = fictions(:one)
      @cache_invalidation = ProgressCacheInvalidation.new(@user, @fiction)
    end

    test 'initializes with user and fiction' do
      assert_equal @user, @cache_invalidation.instance_variable_get(:@user)
      assert_equal @fiction, @cache_invalidation.instance_variable_get(:@fiction)
    end

    test 'clear calls both cache clearing methods' do
      user_cache_called = false
      fiction_cache_called = false

      @cache_invalidation.stub :clear_user_caches, -> { user_cache_called = true } do
        @cache_invalidation.stub :clear_fiction_caches, -> { fiction_cache_called = true } do
          @cache_invalidation.clear
        end
      end

      assert user_cache_called, 'clear_user_caches should have been called'
      assert fiction_cache_called, 'clear_fiction_caches should have been called'
    end

    test 'clear_user_caches deletes all reading progress related caches' do
      expected_statuses = { 'active' => 0, 'finished' => 1, 'postponed' => 2, 'dropped' => 3 }

      cache_deletions = []
      Rails.cache.stub :delete, ->(key) { cache_deletions << key } do
        ReadingProgress.stub :statuses, expected_statuses do
          @cache_invalidation.send(:clear_user_caches)
        end
      end

      expected_keys = expected_statuses.each_key.flat_map do |status|
        [
          "user:#{@user.id}:related_fictions:#{status}",
          "user:#{@user.id}:favourite_translators:#{status}"
        ]
      end
      expected_keys << "user:#{@user.id}:reading_history"

      assert_equal expected_keys.sort, cache_deletions.sort
    end

    test 'clear_fiction_caches deletes fiction specific caches' do
      cache_deletions = []
      Rails.cache.stub :delete, ->(key) { cache_deletions << key } do
        @cache_invalidation.send(:clear_fiction_caches)
      end

      assert_includes cache_deletions, "fiction-#{@fiction.slug}-stats"
      assert_includes cache_deletions, "fiction-#{@fiction.slug}-ranks"
      assert_equal 2, cache_deletions.length
    end

    test 'clear_user_caches handles empty reading progress statuses' do
      ReadingProgress.stub :statuses, {} do
        cache_deletions = []
        Rails.cache.stub :delete, ->(key) { cache_deletions << key } do
          @cache_invalidation.send(:clear_user_caches)
        end

        assert_includes cache_deletions, "user:#{@user.id}:reading_history"
        assert_equal 1, cache_deletions.length
      end
    end

    test 'clear_fiction_caches works with different fiction slugs' do
      different_fiction = fictions(:two)
      different_invalidation = ProgressCacheInvalidation.new(@user, different_fiction)

      first_cache_deletions = []
      second_cache_deletions = []

      Rails.cache.stub :delete, ->(key) { first_cache_deletions << key } do
        @cache_invalidation.send(:clear_fiction_caches)
      end

      Rails.cache.stub :delete, ->(key) { second_cache_deletions << key } do
        different_invalidation.send(:clear_fiction_caches)
      end

      expected_first = [
        "fiction-#{@fiction.slug}-stats",
        "fiction-#{@fiction.slug}-ranks"
      ].sort
      expected_second = [
        "fiction-#{different_fiction.slug}-stats",
        "fiction-#{different_fiction.slug}-ranks"
      ].sort

      assert_equal expected_first, first_cache_deletions.sort
      assert_equal expected_second, second_cache_deletions.sort
      assert_empty first_cache_deletions & second_cache_deletions
    end

    test 'clear_user_caches iterates through all reading progress statuses' do
      expected_statuses = { 'active' => 0, 'finished' => 1 }
      ReadingProgress.stub :statuses, expected_statuses do
        cache_deletions = []

        Rails.cache.stub :delete, ->(key) { cache_deletions << key } do
          @cache_invalidation.send(:clear_user_caches)
        end

        expected_keys = expected_statuses.each_key.flat_map do |status|
          [
            "user:#{@user.id}:related_fictions:#{status}",
            "user:#{@user.id}:favourite_translators:#{status}"
          ]
        end
        expected_keys << "user:#{@user.id}:reading_history"

        assert_equal expected_keys.sort, cache_deletions.sort
      end
    end
  end
end
