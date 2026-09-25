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

    test 'moves the resume cursor and stamps resume_at' do
      freeze_time do
        assert RecordProgress.new(chapter: @chapter, user: @user).call
        assert_equal @chapter.id, @progress.reload.chapter_id
        assert_equal Time.current, @progress.resume_at
      end
    end

    test 'does not insert a chapter read' do
      assert_no_difference -> { ReadingChapterRead.count } do
        RecordProgress.new(chapter: @chapter, user: @user).call
      end
    end

    test 'moving an existing cursor clears the reading history cache' do
      write_caches
      RecordProgress.new(chapter: @chapter, user: @user).call

      assert_nil Rails.cache.read(history_key)
    end

    test 'moving an existing cursor keeps related-fictions and fiction-stats caches' do
      write_caches
      RecordProgress.new(chapter: @chapter, user: @user).call

      assert_equal 'keep', Rails.cache.read(related_key)
      assert_equal 'keep', Rails.cache.read(stats_key)
    end

    test 'first engaged chapter of a fiction creates the library row' do
      @progress.destroy!

      assert_difference -> { ReadingProgress.count }, 1 do
        RecordProgress.new(chapter: @chapter, user: @user).call
      end
    end

    test 'a re-created library row starts from reads that outlived the old one' do
      @progress.destroy!
      RecordProgress.new(chapter: @chapter, user: @user).call

      assert_equal 1, ReadingProgress.find_by!(user: @user, fiction: @fiction).completed_count
    end

    test 'first engaged chapter of a fiction clears library and fiction caches' do
      @progress.destroy!
      write_caches
      RecordProgress.new(chapter: @chapter, user: @user).call

      assert_nil Rails.cache.read(related_key)
      assert_nil Rails.cache.read(stats_key)
    end

    test 'stores the locator sent with the engaged event' do
      RecordProgress.new(chapter: @chapter, user: @user, locator: ResumeLocator.parse(percent: 30, block_index: 4)).call

      assert_in_delta 30, @progress.reload.resume_percent
      assert_equal 4, @progress.resume_block_index
    end

    test 'moving to another chapter drops the previous chapter locator' do
      @progress.update!(resume_percent: 80, resume_block_index: 40, resume_quote: 'old', resume_digest: 'a' * 16)
      RecordProgress.new(chapter: @chapter, user: @user).call

      assert_equal ResumeLocator::CLEARED, @progress.reload.attributes.symbolize_keys.slice(*ResumeLocator::CLEARED.keys)
    end

    test 'engaged again on the resume chapter only refreshes the locator' do
      @progress.update!(chapter: @chapter)

      assert RecordProgress.new(chapter: @chapter, user: @user, locator: ResumeLocator.parse(percent: 55)).call
      assert_in_delta 55, @progress.reload.resume_percent
      assert_nil @progress.resume_at
    end

    test 'does not write or clear cache when chapter is unchanged' do
      @progress.update!(chapter: @chapter)
      write_caches

      assert_not RecordProgress.new(chapter: @chapter, user: @user).call
      assert_nil @progress.reload.resume_at
      assert_equal 'keep', Rails.cache.read(history_key)
    end

    private

    def history_key = "user:#{@user.id}:reading_history"
    def related_key = "user:#{@user.id}:related_fictions:active"
    def stats_key = "fiction-#{@fiction.slug}-stats"

    def write_caches
      [history_key, related_key, stats_key].each { |key| Rails.cache.write(key, 'keep') }
    end
  end
end
