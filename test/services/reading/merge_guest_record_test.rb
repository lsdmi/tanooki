# frozen_string_literal: true

require 'test_helper'

module Reading
  class MergeGuestRecordTest < ActiveSupport::TestCase
    DIGEST = '0123456789abcdef'

    setup do
      @user = users(:user_one)
      @fiction = fictions(:one)
      @first = chapters(:one)
      @latest = chapters(:two)
      @progress = reading_progresses(:one)
      @progress.update!(chapter: @first, resume_at: 1.hour.ago, resume_percent: 20)
      ReadingChapterRead.where(user: @user).delete_all
    end

    test 'device newer than the account moves the cursor, with the device place' do
      freeze_time do
        assert merge(chapter: @latest, resume_at: 10.minutes.ago, percent: 42)

        @progress.reload

        assert_equal [@latest.id, 10.minutes.ago], [@progress.chapter_id, @progress.resume_at]
        assert_equal [42, 3, DIGEST], [@progress.resume_percent, @progress.resume_block_index, @progress.resume_digest]
      end
    end

    test 'account newer than the device keeps the cursor and its place but still takes the reads' do
      touched_at = @progress.reload.updated_at

      merge(chapter: @latest, resume_at: 2.hours.ago, percent: 42, reads: [@latest])

      @progress.reload

      assert_equal [@first.id, 20], [@progress.chapter_id, @progress.resume_percent.to_i]
      assert_equal [touched_at, 1], [@progress.updated_at, @progress.completed_count]
      assert ReadingChapterRead.exists?(user: @user, chapter: @latest, source: MergeGuestRecord::SOURCE)
    end

    test 'disjoint read sets are unioned, never filled between' do
      mark_read(@latest)

      merge(chapter: @first, resume_at: 2.hours.ago, reads: [@first])

      assert_equal [@first.id, @latest.id].sort, ReadingChapterRead.where(user: @user).pluck(:chapter_id).sort
      assert_equal 2, @progress.reload.completed_count
    end

    test 'reads the account already has change nothing' do
      mark_read(@first)

      assert_not merge(chapter: @first, resume_at: 2.hours.ago, reads: [@first])
    end

    test 'with no library row the device record starts one at its cursor' do
      @user = users(:user_two)

      assert merge(chapter: @first, resume_at: 5.minutes.ago, percent: 30, reads: [@first])

      progress = ReadingProgress.find_by!(user: @user, fiction: @fiction)

      assert_equal [@first.id, 'active', 1], [progress.chapter_id, progress.status, progress.completed_count]
    end

    test 'a row from before resume_at existed is compared by when it was last updated' do
      travel_to(3.hours.ago) { @progress.update!(resume_at: nil) }

      assert merge(chapter: @latest, resume_at: 2.hours.ago)
      assert_equal @latest.id, @progress.reload.chapter_id
    end

    test 'a device record with no resume_at never replaces an account cursor' do
      assert_not merge(chapter: @latest, resume_at: nil)
      assert_equal @first.id, @progress.reload.chapter_id
    end

    test 'chapters of another fiction are ignored, and a missing fiction merges nothing' do
      assert_not merge(chapter: chapters(:three), resume_at: 1.minute.ago, reads: [chapters(:three)])
      assert_not merge(fiction_id: 999_999, chapter: @latest, resume_at: 1.minute.ago)
      assert_equal @first.id, @progress.reload.chapter_id
    end

    test 'a merge that writes clears the broad reading caches' do
      Rails.cache.write("fiction-#{@fiction.slug}-stats", 'stale')

      merge(chapter: @latest, resume_at: 1.minute.ago)

      assert_nil Rails.cache.read("fiction-#{@fiction.slug}-stats")
    end

    private

    def merge(chapter:, resume_at:, fiction_id: @fiction.id, percent: nil, reads: [])
      raw = { fiction_id:, chapter_id: chapter.id, resume_at: resume_at&.iso8601(3), read_chapter_ids: reads.map(&:id) }
      raw[:locator] = { percent:, block_index: 3, quote: 'Він довго мовчав', digest: DIGEST } if percent
      MergeGuestRecord.new(user: @user, record: GuestRecord.parse(raw)).call
    end

    def mark_read(chapter)
      ReadingChapterRead.create!(user: @user, fiction: @fiction, chapter:, completed_at: Time.current, source: 'scroll')
    end
  end
end
