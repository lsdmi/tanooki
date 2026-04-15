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

  test 'valid chapter' do
    assert @chapter.valid?
  end

  test 'valid without title' do
    @chapter.title = nil
    assert @chapter.valid?
  end

  test 'valid with short title' do
    @chapter.title = 'A'
    assert @chapter.valid?
  end

  test 'invalid with long title' do
    @chapter.title = 'A' * 101
    refute @chapter.valid?
    assert_not_nil @chapter.errors[:title]
  end

  test 'invalid without content' do
    @chapter.content = nil
    refute @chapter.valid?
    assert_not_nil @chapter.errors[:content]
  end

  test 'invalid with short content' do
    @chapter.content = 'A' * 497
    refute @chapter.valid?
    assert_not_nil @chapter.errors[:content]
  end

  test 'invalid without user' do
    @chapter.user = nil
    refute @chapter.valid?
    assert_not_nil @chapter.errors[:user]
  end

  test 'invalid without fiction' do
    @chapter.fiction_id = nil
    refute @chapter.valid?
    assert_not_nil @chapter.errors[:fiction]
  end

  test 'invalid with negative chapter number' do
    @chapter.number = -1
    refute @chapter.valid?
    assert_not_nil @chapter.errors[:number]
  end

  test 'invalid with non-integer chapter number' do
    @chapter.number = 1.5
    assert @chapter.valid?
  end

  test 'valid with zero chapter number' do
    @chapter.number = 0
    assert @chapter.valid?
  end

  test 'valid with large content length' do
    @chapter.content = 'A' * 500
    assert @chapter.valid?
  end

  test 'valid with maximum title length' do
    @chapter.title = 'A' * 100
    assert @chapter.valid?
  end

  test 'invalid with too long title' do
    @chapter.title = 'A' * 101
    refute @chapter.valid?
    assert_not_nil @chapter.errors[:title]
  end

  test 'should destroy associated comments' do
    chapter = chapters(:one)
    chapter.comments << comments(:comment_one)

    assert_difference('Comment.count', -1) do
      chapter.destroy
    end
  end

  test 'released and scheduled scopes' do
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
      assert c.save
      assert_includes Chapter.released, c

      c.update!(published_at: 1.day.from_now)
      assert_not Chapter.released.exists?(c.id)
      assert_includes Chapter.scheduled, c
    end
  end

  test 'scheduled? is true only while published_at is in the future' do
    travel_to Time.zone.parse('2026-06-01 12:00') do
      @chapter.published_at = nil
      assert_not @chapter.scheduled?

      @chapter.published_at = 1.hour.ago
      assert_not @chapter.scheduled?

      @chapter.published_at = 1.hour.from_now
      assert @chapter.scheduled?
    end
  end

  test 'published_at cannot be in the past for new chapters' do
    @chapter.published_at = 1.day.ago
    refute @chapter.valid?
    assert_includes @chapter.errors[:published_at], 'не може бути в минулому'
  end
end
