# frozen_string_literal: true

require 'test_helper'

module Reading
  class RecordPositionTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)
      @chapter = chapters(:two)
      @progress = reading_progresses(:one)
      @progress.update!(chapter: @chapter)
    end

    test 'stores the locator on the resume chapter' do
      assert record(percent: 42.5, block_index: 7, quote: 'Розділ')
      assert_equal [42.5, 7, 'Розділ'],
                   @progress.reload.values_at(:resume_percent, :resume_block_index, :resume_quote)
    end

    test 'ignores positions from a chapter the cursor is not on' do
      assert_not record(percent: 42.5, chapter: chapters(:one))
      assert_nil @progress.reload.resume_percent
    end

    test 'ignores positions when there is no library row' do
      @progress.destroy!

      assert_no_difference -> { ReadingProgress.count } do
        assert_not record(percent: 42.5)
      end
    end

    test 'does not bump updated_at, so library order stays put' do
      updated_at = @progress.reload.updated_at

      travel 1.minute do
        record(percent: 42.5)
      end

      assert_equal updated_at, @progress.reload.updated_at
    end

    test 'an unchanged position writes nothing and keeps caches' do
      record(percent: 42.5)
      Rails.cache.write(history_key, 'keep')

      assert_not record(percent: 42.5)
      assert_equal 'keep', Rails.cache.read(history_key)
    end

    test 'a new position clears only the reading history cache' do
      Rails.cache.write(history_key, 'keep')
      Rails.cache.write(stats_key, 'keep')
      record(percent: 42.5)

      assert_nil Rails.cache.read(history_key)
      assert_equal 'keep', Rails.cache.read(stats_key)
    end

    test 'guests and missing locators write nothing' do
      assert_not RecordPosition.new(chapter: @chapter, user: nil, locator: ResumeLocator.parse(percent: 1)).call
      assert_not RecordPosition.new(chapter: @chapter, user: @user, locator: nil).call
    end

    private

    def record(chapter: @chapter, **locator)
      RecordPosition.new(chapter:, user: @user, locator: ResumeLocator.parse(locator)).call
    end

    def history_key = "user:#{@user.id}:reading_history"
    def stats_key = "fiction-#{@chapter.fiction.slug}-stats"
  end
end
