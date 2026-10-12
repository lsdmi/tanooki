# frozen_string_literal: true

require 'test_helper'

module Library
  class ChapterNavigationTest < ActiveSupport::TestCase
    setup do
      RequestMemo.reset
      @fiction = fictions(:one)
    end

    test 'following stays with the team when another member posted the next chapter' do
      teammate = publish(number: 2, user: users(:user_two), scanlator: scanlators(:one))
      move_team(chapters(:two), scanlators(:two))

      assert_equal teammate, ChapterNavigation.following_chapter(@fiction, chapters(:one))
    end

    test 'following stays with the same person when that team has no next chapter' do
      move_team(chapters(:two), scanlators(:two))
      publish(number: 2, user: users(:user_two), scanlator: scanlators(:two))

      assert_equal chapters(:two), ChapterNavigation.following_chapter(@fiction, chapters(:one))
    end

    private

    def publish(number:, user:, scanlator:)
      chapter = Chapter.create!(
        fiction: @fiction, user:, title: 'Other', number:, content: 'x' * 500, scanlator_ids: [scanlator.id]
      )
      ChapterScanlator.create!(chapter:, scanlator:)
      chapter
    end

    def move_team(chapter, scanlator)
      ChapterScanlator.find_by!(chapter_id: chapter.id).update!(scanlator:)
    end
  end
end
