# frozen_string_literal: true

require 'test_helper'

class FictionDestroyServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:user_one)
    @scanlator = scanlators(:one)
  end

  test 'destroys fiction when it has a single scanlator' do
    fiction = fictions(:two)

    assert_difference('Fiction.count', -1) do
      FictionDestroyService.new(fiction, @user).call
    end
  end

  test 'removes only the current user scanlator when fiction is shared' do
    fiction = fictions(:one)
    FictionScanlator.create!(fiction:, scanlator: scanlators(:two))

    assert_no_difference('Fiction.count') do
      FictionDestroyService.new(fiction, @user).call
    end

    fiction.reload
    remaining_chapters = fiction.chapters.joins(:scanlators).where(chapter_scanlators: { scanlator_id: @scanlator.id })

    assert(
      fiction.scanlators.ids == [scanlators(:two).id] && remaining_chapters.none?,
      'expected only the other scanlator and no chapters for the removed team'
    )
  end
end
