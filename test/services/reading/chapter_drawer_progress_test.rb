# frozen_string_literal: true

require 'test_helper'

module Reading
  class ChapterDrawerProgressTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @user = users(:user_one)
      @chapter_one = chapters(:one)
      @chapter_two = chapters(:two)
    end

    test 'marks earlier chapters read and current chapter as current' do
      reading_progresses(:one).update!(chapter: @chapter_two, status: :active)

      progress = ChapterDrawerProgress.build(
        fiction: @fiction,
        viewer: @user,
        current_chapter: @chapter_two
      )

      assert_equal :read, progress.status_for(@chapter_one)
      assert_equal :current, progress.status_for(@chapter_two)
    end

    test 'marks all chapters read when fiction is finished' do
      reading_progresses(:one).update!(chapter: @chapter_one, status: :finished)

      progress = ChapterDrawerProgress.build(
        fiction: @fiction,
        viewer: @user,
        current_chapter: @chapter_two
      )

      assert_equal :current, progress.status_for(@chapter_two)
      assert_equal :read, progress.status_for(@chapter_one)
    end

    test 'marks other chapters unread without reading progress' do
      ReadingProgress.where(fiction: @fiction, user: @user).delete_all

      progress = ChapterDrawerProgress.build(
        fiction: @fiction,
        viewer: @user,
        current_chapter: @chapter_two
      )

      assert_equal :unread, progress.status_for(@chapter_one)
      assert_equal :current, progress.status_for(@chapter_two)
    end

    test 'guest sees only the open chapter as current' do
      progress = ChapterDrawerProgress.build(
        fiction: @fiction,
        viewer: nil,
        current_chapter: @chapter_two
      )

      assert_equal :unread, progress.status_for(@chapter_one)
      assert_equal :current, progress.status_for(@chapter_two)
    end
  end
end
