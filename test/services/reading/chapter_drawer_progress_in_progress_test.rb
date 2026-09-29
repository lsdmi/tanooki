# frozen_string_literal: true

require 'test_helper'

module Reading
  class ChapterDrawerProgressInProgressTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)
      @chapter_two = chapters(:two)
      ReadingChapterRead.where(user: @user).delete_all
    end

    test 'resume chapter off screen is in progress, not current' do
      reading_progresses(:one).update!(chapter: @chapter_two, status: :active)

      assert_equal :in_progress, build(current_chapter: chapters(:one)).status_for(@chapter_two)
    end

    test 'the open resume chapter stays current' do
      reading_progresses(:one).update!(chapter: @chapter_two, status: :active)

      assert_equal :current, build(current_chapter: @chapter_two).status_for(@chapter_two)
    end

    test 'a read resume chapter shows as read, not in progress' do
      reading_progresses(:one).update!(chapter: @chapter_two, status: :active)
      ReadingChapterRead.create!(user: @user, fiction: @chapter_two.fiction, chapter: @chapter_two,
                                 completed_at: Time.current, source: 'scroll')

      assert_equal :read, build(current_chapter: nil).status_for(@chapter_two)
    end

    test 'a finished fiction has no chapter in progress' do
      reading_progresses(:one).update!(chapter: @chapter_two, status: :finished)

      assert_equal :read, build(current_chapter: nil).status_for(@chapter_two)
    end

    test 'guests have no chapter in progress' do
      progress = ChapterDrawerProgress.build(fiction: fictions(:one), viewer: nil)

      assert_equal :unread, progress.status_for(@chapter_two)
    end

    private

    def build(current_chapter:)
      ChapterDrawerProgress.build(fiction: fictions(:one), viewer: @user, current_chapter:)
    end
  end
end
