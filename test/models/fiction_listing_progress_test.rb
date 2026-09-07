# frozen_string_literal: true

require 'test_helper'

class FictionListingProgressTest < ActiveSupport::TestCase
  def setup
    @user = users(:user_one)
    @fiction = Fiction.new(title: 'Test Fiction', author: 'Test Author', scanlator_ids: [1],
                           description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                           expected_chapters: 5, status: :announced, user_id: @user.id)
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
end
