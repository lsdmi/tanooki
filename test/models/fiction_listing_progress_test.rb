# frozen_string_literal: true

require 'test_helper'

class FictionListingProgressTest < ActiveSupport::TestCase
  def setup
    @user = users(:user_one)
    @fiction = Fiction.new(title: 'Test Fiction', author: 'Test Author', scanlator_ids: [1],
                           description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                           expected_chapters: 5, user_id: @user.id)
    @fiction.cover.attach(valid_cover_upload)
  end

  test 'expected_chapters should be an integer' do
    @fiction.expected_chapters = 5.5

    assert_not @fiction.valid?
  end

  test 'expected_chapters zero becomes nil' do
    @fiction.expected_chapters = 0
    @fiction.valid?

    assert_nil @fiction.expected_chapters
  end

  test 'expected_chapters zero is valid as unknown' do
    @fiction.expected_chapters = 0

    assert_predicate @fiction, :valid?
  end

  test 'expected_chapters may be omitted' do
    @fiction.expected_chapters = nil

    assert_predicate @fiction, :valid?
  end

  test 'expected_chapters cannot be below chapter_count on form save' do
    @fiction.chapter_count = 10
    @fiction.expected_chapters = 3

    assert_not @fiction.valid?
  end

  test 'raising chapter_count does not fail expected_chapters validation' do
    @fiction.expected_chapters = 5
    @fiction.save!
    @fiction.chapter_count = 10

    assert_predicate @fiction, :valid?
  end

  test 'listing_state is finished when completed_at is set' do
    @fiction.completed_at = Time.current
    @fiction.chapter_count = 10
    @fiction.last_chapter_at = Time.current

    assert_equal :finished, @fiction.listing_state
    assert_equal 'Завершено', @fiction.listing_state_label
  end

  test 'listing_state is announced when nothing is public yet' do
    @fiction.chapter_count = 4
    @fiction.last_chapter_at = nil

    assert_equal :announced, @fiction.listing_state
    assert_equal 'Анонсовано', @fiction.listing_state_label
  end

  test 'listing_state is stale when last_chapter_at is older than 90 days' do
    @fiction.chapter_count = 10
    @fiction.last_chapter_at = (FictionListingProgress::STALE_AFTER + 1.day).ago

    assert_equal :stale, @fiction.listing_state
    assert_equal 'Покинуто', @fiction.listing_state_label
  end

  test 'listing_state is ongoing when last_chapter_at is recent' do
    @fiction.chapter_count = 10
    @fiction.last_chapter_at = 1.day.ago

    assert_equal :ongoing, @fiction.listing_state
    assert_equal 'Видається', @fiction.listing_state_label
    assert_equal 'Видаєт.', @fiction.listing_state_label_short
  end
end
