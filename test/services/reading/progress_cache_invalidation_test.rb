# frozen_string_literal: true

require 'test_helper'

module Reading
  class ProgressCacheInvalidationTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)
      @fiction = fictions(:one)
      @other_fiction = fictions(:two)
      @invalidation = ProgressCacheInvalidation.new(@user, @fiction)
      all_keys.each { |key| Rails.cache.write(key, 'keep') }
    end

    test 'clear_resume drops the reading history' do
      @invalidation.clear_resume

      assert_nil Rails.cache.read(history_key)
    end

    test 'clear_resume keeps library sidebars and fiction stats and ranks' do
      @invalidation.clear_resume

      assert_equal %w[keep], cached(all_keys - [history_key]).uniq
    end

    test 'clear drops the reading history and every section sidebar' do
      @invalidation.clear

      assert_empty cached([history_key] + sidebar_keys).compact
    end

    test 'clear drops stats and ranks for the fiction' do
      @invalidation.clear

      assert_empty cached(fiction_keys(@fiction)).compact
    end

    test 'clear keeps stats and ranks for other fictions' do
      @invalidation.clear

      assert_equal %w[keep keep], cached(fiction_keys(@other_fiction))
    end

    test 'clear keeps other users caches' do
      other_key = "user:#{users(:user_two).id}:reading_history"
      Rails.cache.write(other_key, 'keep')
      @invalidation.clear

      assert_equal 'keep', Rails.cache.read(other_key)
    end

    private

    def history_key = "user:#{@user.id}:reading_history"

    def sidebar_keys
      ReadingProgress.statuses.keys.flat_map do |section|
        ["user:#{@user.id}:related_fictions:#{section}", "user:#{@user.id}:favourite_translators:#{section}"]
      end
    end

    def fiction_keys(fiction) = ["fiction-#{fiction.slug}-stats", "fiction-#{fiction.slug}-ranks"]

    def all_keys = [history_key] + sidebar_keys + fiction_keys(@fiction) + fiction_keys(@other_fiction)

    def cached(keys) = keys.map { |key| Rails.cache.read(key) }
  end
end
