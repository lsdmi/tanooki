# frozen_string_literal: true

require 'test_helper'

module Reading
  class ContinueTargetTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)
      @progress = reading_progresses(:one)
      @first = chapters(:one)
      @latest = chapters(:two)
      ReadingChapterRead.where(user: @user).delete_all
    end

    test 'unread resume chapter continues there with the restore' do
      target = target_for(@first, percent: 40)

      assert_equal [@first, true, false], [target.chapter, target.resume?, target.all_read?]
    end

    test 'read and finished moves on to the following chapter without restoring' do
      mark_read(@first)
      target = target_for(@first, percent: ContinueTarget::FINISHED_PERCENT)

      assert_equal [@latest, false], [target.chapter, target.resume?]
    end

    test 'read with no stored position, as on pre-rebuild rows, counts as finished' do
      mark_read(@first)

      assert_equal @latest, target_for(@first, percent: nil).chapter
    end

    test 'read but stopped mid-chapter on a re-read goes back into it with the restore' do
      mark_read(@first)
      target = target_for(@first, percent: 35)

      assert_equal [@first, true], [target.chapter, target.resume?]
    end

    test 'latest chapter read is all read' do
      mark_read(@latest)

      assert_predicate target_for(@latest, percent: 100), :all_read?
    end

    test 'fiction marked finished is all read' do
      @progress.update!(status: :finished)

      assert_predicate target_for(@first, percent: 20), :all_read?
    end

    private

    def target_for(chapter, percent:)
      @progress.update!(chapter:, resume_percent: percent)
      listable = Library::ChapterNavigation.unique_chapters(
        Library::ChapterCatalog.ordered_chapters_desc(@progress.fiction, viewer: @user)
      )
      read_keys = ReadKeys.call(user: @user, fiction: @progress.fiction, progress: @progress)
      ContinueTarget.new(progress: @progress.reload, viewer: @user, listable:, read_keys:)
    end

    def mark_read(chapter)
      ReadingChapterRead.create!(user: @user, fiction: chapter.fiction, chapter:,
                                 completed_at: Time.current, source: 'scroll')
    end
  end
end
