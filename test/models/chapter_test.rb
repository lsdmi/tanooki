# frozen_string_literal: true

require 'test_helper'

class ChapterTest < ActiveSupport::TestCase
  def setup
    @user = users(:user_one)
    @fiction = fictions(:one)
    @chapter = Chapter.new(
      scanlator_ids: [1],
      title: 'Test Chapter',
      number: 1,
      content: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.' * 100,
      user: @user,
      fiction: @fiction
    )
  end

  test 'should destroy associated comments' do
    chapter = chapters(:one)
    chapter.comments << comments(:comment_one)

    assert_difference('Comment.count', -1) do
      chapter.destroy
    end
  end

  test 'released scope includes chapter when published_at is nil' do
    travel_to Time.zone.parse('2026-04-15 12:00') do
      c = Chapter.new(
        scanlator_ids: [1],
        title: 'Scheduled scope test',
        number: 99,
        content: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.' * 100,
        user: @user,
        fiction: @fiction,
        published_at: nil
      )

      assert_predicate c, :save
      assert_includes Chapter.released, c
    end
  end

  test 'released scope excludes chapter when published_at is in the future' do
    travel_to Time.zone.parse('2026-04-15 12:00') do
      c = Chapter.new(
        scanlator_ids: [1],
        title: 'Future publish test',
        number: 99,
        content: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.' * 100,
        user: @user,
        fiction: @fiction,
        published_at: nil
      )
      c.save!
      c.update!(published_at: 1.day.from_now)

      assert_not Chapter.released.exists?(c.id)
    end
  end

  test 'scheduled? is true only while published_at is in the future' do
    travel_to Time.zone.parse('2026-06-01 12:00') do
      @chapter.published_at = nil

      assert_not @chapter.scheduled?

      @chapter.published_at = 1.hour.ago

      assert_not @chapter.scheduled?

      @chapter.published_at = 1.hour.from_now

      assert_predicate @chapter, :scheduled?
    end
  end

  test 'published_at cannot be in the past for new chapters' do
    @chapter.published_at = 1.day.ago

    assert_not_predicate @chapter, :valid?
    assert_includes @chapter.errors[:published_at], 'не може бути в минулому'
  end

  test 'link_fiction_to_scanlators links persisted chapter teams only' do
    chapter = chapters(:one)
    fiction = chapter.fiction
    other_team = scanlators(:two)
    fiction.fiction_scanlators.where(scanlator: other_team).destroy_all
    ChapterScanlator.create!(chapter:, scanlator: other_team)

    chapter.link_fiction_to_scanlators!

    assert FictionScanlator.exists?(fiction_id: fiction.id, scanlator_id: other_team.id)
  end
end
