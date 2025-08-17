# frozen_string_literal: true

require 'test_helper'

class CacheClearerTest < ActiveSupport::TestCase
  def setup
    @user = users(:user_one)
    @fiction = fictions(:one)
    @cache_clearer = CacheClearer.new(@user, @fiction)
  end

  test 'initializes with user and fiction' do
    assert_equal @user, @cache_clearer.instance_variable_get(:@user)
    assert_equal @fiction, @cache_clearer.instance_variable_get(:@fiction)
  end

  test 'clear_reading_caches calls both cache clearing methods' do
    # Test that the public method calls both private methods by stubbing them
    user_cache_called = false
    fiction_cache_called = false

    @cache_clearer.stub :clear_user_caches, -> { user_cache_called = true } do
      @cache_clearer.stub :clear_fiction_caches, -> { fiction_cache_called = true } do
        @cache_clearer.clear_reading_caches
      end
    end

    assert user_cache_called, 'clear_user_caches should have been called'
    assert fiction_cache_called, 'clear_fiction_caches should have been called'
  end

  test 'clear_user_caches deletes all reading progress related caches' do
    # Mock ReadingProgress.statuses to return specific values
    expected_statuses = { 'active' => 0, 'finished' => 1, 'postponed' => 2, 'dropped' => 3 }

    # Track cache deletion calls
    cache_deletions = []
    Rails.cache.stub :delete, ->(key) { cache_deletions << key } do
      ReadingProgress.stub :statuses, expected_statuses do
        @cache_clearer.send(:clear_user_caches)
      end
    end

    # Verify all expected cache keys were deleted
    expected_statuses.each_key do |status|
      assert_includes cache_deletions, "user:#{@user.id}:related_fictions:#{status}"
      assert_includes cache_deletions, "user:#{@user.id}:favourite_translators:#{status}"
    end
    assert_includes cache_deletions, "user:#{@user.id}:reading_history"

    # Verify the total number of deletions
    expected_total = (expected_statuses.keys.length * 2) + 1
    assert_equal expected_total, cache_deletions.length
  end

  test 'clear_fiction_caches deletes fiction specific caches' do
    # Track cache deletion calls
    cache_deletions = []
    Rails.cache.stub :delete, ->(key) { cache_deletions << key } do
      @cache_clearer.send(:clear_fiction_caches)
    end

    # Verify the expected cache keys were deleted
    assert_includes cache_deletions, "fiction-#{@fiction.slug}-stats"
    assert_includes cache_deletions, "fiction-#{@fiction.slug}-ranks"
    assert_equal 2, cache_deletions.length
  end

  test 'clear_user_caches handles empty reading progress statuses' do
    # Mock ReadingProgress.statuses to return empty hash
    ReadingProgress.stub :statuses, {} do
      cache_deletions = []
      Rails.cache.stub :delete, ->(key) { cache_deletions << key } do
        @cache_clearer.send(:clear_user_caches)
      end

      # Should only delete reading_history when no statuses exist
      assert_includes cache_deletions, "user:#{@user.id}:reading_history"
      assert_equal 1, cache_deletions.length
    end
  end

  test 'clear_fiction_caches works with different fiction slugs' do
    different_fiction = fictions(:two)
    different_cache_clearer = CacheClearer.new(@user, different_fiction)

    # Track cache deletions for both clearers
    first_cache_deletions = []
    second_cache_deletions = []

    # Test first fiction cache clearer
    Rails.cache.stub :delete, ->(key) { first_cache_deletions << key } do
      @cache_clearer.send(:clear_fiction_caches)
    end

    # Test second fiction cache clearer
    Rails.cache.stub :delete, ->(key) { second_cache_deletions << key } do
      different_cache_clearer.send(:clear_fiction_caches)
    end

    # Verify each clearer only deletes its own fiction's caches
    assert_includes first_cache_deletions, "fiction-#{@fiction.slug}-stats"
    assert_includes first_cache_deletions, "fiction-#{@fiction.slug}-ranks"
    assert_includes second_cache_deletions, "fiction-#{different_fiction.slug}-stats"
    assert_includes second_cache_deletions, "fiction-#{different_fiction.slug}-ranks"

    # Verify no cross-contamination
    assert_not_includes first_cache_deletions, "fiction-#{different_fiction.slug}-stats"
    assert_not_includes second_cache_deletions, "fiction-#{@fiction.slug}-stats"
  end

  test 'clear_user_caches iterates through all reading progress statuses' do
    # Mock the statuses to return specific values
    expected_statuses = { 'active' => 0, 'finished' => 1 }
    ReadingProgress.stub :statuses, expected_statuses do
      # Create a spy to track cache deletions
      cache_deletions = []

      # Stub Rails.cache.delete to track calls
      Rails.cache.stub :delete, ->(key) { cache_deletions << key } do
        @cache_clearer.send(:clear_user_caches)
      end

      # Verify all expected cache keys were deleted
      expected_statuses.each_key do |status|
        assert_includes cache_deletions, "user:#{@user.id}:related_fictions:#{status}"
        assert_includes cache_deletions, "user:#{@user.id}:favourite_translators:#{status}"
      end
      assert_includes cache_deletions, "user:#{@user.id}:reading_history"

      # Verify the total number of deletions
      expected_total = (expected_statuses.keys.length * 2) + 1
      assert_equal expected_total, cache_deletions.length
    end
  end
end
