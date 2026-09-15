# frozen_string_literal: true

require 'test_helper'

class DraftableTest < ActiveSupport::TestCase
  setup do
    @user = users(:user_one)
    @fiction = fictions(:one)
    @chapter = Chapter.new(
      scanlator_ids: [1],
      title: 'Draftable chapter',
      number: 1,
      content: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.' * 100,
      user: @user,
      fiction: @fiction
    )
  end

  test 'chapter defaults to published status' do
    assert_predicate @chapter, :published?
    assert_not @chapter.draft?
  end

  test 'chapter draft? is true when status is draft' do
    @chapter.status = :draft

    assert_predicate @chapter, :draft?
    assert_not @chapter.published?
  end

  test 'released scope excludes drafts when published_at is nil' do
    travel_to Time.zone.parse('2026-04-15 12:00') do
      @chapter.published_at = nil
      @chapter.status = :draft

      assert_predicate @chapter, :save
      assert_not Chapter.released.exists?(@chapter.id)
      assert_includes Chapter.drafts, @chapter
    end
  end

  test 'public_visible? is false for drafts and scheduled chapters' do
    travel_to Time.zone.parse('2026-06-01 12:00') do
      assert_predicate @chapter, :public_visible?

      @chapter.status = :draft

      assert_not @chapter.public_visible?

      @chapter.status = :published
      @chapter.published_at = 1.hour.from_now

      assert_not @chapter.public_visible?
    end
  end
end
