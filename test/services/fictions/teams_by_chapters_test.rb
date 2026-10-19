# frozen_string_literal: true

require 'test_helper'

module Fictions
  class TeamsByChaptersTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
    end

    test 'orders teams by published chapter count then title' do
      other = scanlators(:two)
      FictionScanlator.create!(fiction: @fiction, scanlator: other)
      ChapterScanlator.create!(chapter: chapters(:one), scanlator: other)
      ChapterScanlator.create!(chapter: chapters(:two), scanlator: other)
      extra = Chapter.create!(
        fiction: @fiction,
        user: users(:user_one),
        title: 'Extra',
        number: 3,
        content: 'x' * 500,
        scanlator_ids: [other.id]
      )
      ChapterScanlator.create!(chapter: extra, scanlator: other)

      assert_equal [other, scanlators(:one)], TeamsByChapters.call(@fiction)
    end

    test 'omits teams that only have drafts left' do
      other = scanlators(:two)
      FictionScanlator.create!(fiction: @fiction, scanlator: other)
      chapters(:one).update!(status: :draft, scanlator_ids: [scanlators(:one).id])
      chapters(:two).update!(status: :draft, scanlator_ids: [scanlators(:one).id])
      live = Chapter.create!(
        fiction: @fiction,
        user: users(:user_one),
        title: 'Still live',
        number: 3,
        content: 'x' * 500,
        scanlator_ids: [other.id]
      )
      ChapterScanlator.create!(chapter: live, scanlator: other)

      assert_equal [other], TeamsByChapters.call(@fiction)
    end
  end
end
