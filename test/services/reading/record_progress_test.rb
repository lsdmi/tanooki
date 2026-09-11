# frozen_string_literal: true

require 'test_helper'

module Reading
  class RecordProgressTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)
      @chapter = chapters(:two)
      @fiction = @chapter.fiction
      @progress = reading_progresses(:one)
      @progress.update!(chapter: chapters(:one))
    end

    test 'updates chapter and clears reading history cache' do
      cache_key = "user:#{@user.id}:reading_history"
      Rails.cache.write(cache_key, 'stale')

      assert RecordProgress.new(chapter: @chapter, user: @user).call
      assert_equal @chapter.id, @progress.reload.chapter_id
      assert_nil Rails.cache.read(cache_key)
    end

    test 'does not clear cache when chapter is unchanged' do
      cache_key = "user:#{@user.id}:reading_history"
      @progress.update!(chapter: @chapter)
      Rails.cache.write(cache_key, 'keep')

      assert_not RecordProgress.new(chapter: @chapter, user: @user).call
      assert_equal 'keep', Rails.cache.read(cache_key)
    end
  end
end
