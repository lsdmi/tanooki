# frozen_string_literal: true

require 'test_helper'

class FictionTest < ActiveSupport::TestCase
  def setup
    @user = users(:user_one)
    @fiction = Fiction.new(title: 'Test Fiction', author: 'Test Author', scanlator_ids: [1],
                           description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                           total_chapters: 5, user_id: @user.id)
    @fiction.cover.attach(valid_cover_upload)
  end

  test 'should be valid' do
    assert_predicate @fiction, :valid?
  end

  test 'normalizes text fields by squishing whitespace' do
    @fiction.title = '  Test   Fiction  '
    @fiction.author = '  Test  Author  '
    @fiction.description = '  Lorem ipsum dolor sit amet, consectetur adipiscing elit.  '

    assert_equal 'Test Fiction', @fiction.title
    assert_equal 'Test Author', @fiction.author
    assert_equal 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.', @fiction.description
  end

  test 'title should not be too short' do
    @fiction.title = 'a' * 2

    assert_not @fiction.valid?
  end

  test 'title should not be too long' do
    @fiction.title = 'a' * 101

    assert_not @fiction.valid?
  end

  test 'alternative title should be optional' do
    @fiction.alternative_title = ''

    assert_predicate @fiction, :valid?
  end

  test 'alternative title could be short' do
    @fiction.alternative_title = 'a' * 2

    assert_predicate @fiction, :valid?
  end

  test 'alternative title should not be too long' do
    @fiction.alternative_title = 'a' * 101

    assert_not @fiction.valid?
  end

  test 'english title should be optional' do
    @fiction.english_title = ''

    assert_predicate @fiction, :valid?
  end

  test 'english title could be short' do
    @fiction.english_title = 'a' * 2

    assert_predicate @fiction, :valid?
  end

  test 'english title should not be too long' do
    @fiction.english_title = 'a' * 101

    assert_not @fiction.valid?
  end

  test 'author should not be too short' do
    @fiction.author = 'a'

    assert_not @fiction.valid?
  end

  test 'author should not be too long' do
    @fiction.author = 'a' * 51

    assert_not @fiction.valid?
  end

  test 'description should not be too short' do
    @fiction.description = 'a' * 24

    assert_not @fiction.valid?
  end

  test 'description should not be too long' do
    @fiction.description = 'a' * 1001

    assert_not @fiction.valid?
  end

  test 'total_chapters should be an integer' do
    @fiction.total_chapters = 5.5

    assert_not @fiction.valid?
  end

  test 'total_chapters should not be negative' do
    @fiction.total_chapters = -1

    assert_not @fiction.valid?
  end

  test 'cover rejects disallowed format on new upload' do
    invalid_image = Rack::Test::UploadedFile.new(
      Rails.root.join('app/assets/stylesheets/actiontext.css')
    )

    @fiction.cover.attach(invalid_image)

    assert_not @fiction.valid?
    assert_includes @fiction.errors[:cover], 'має бути WebP або AVIF'
  end

  test 'cover allows legacy attachment on save without re-upload' do
    fiction = fictions(:one)

    fiction.title = 'Updated Without New Cover'

    assert_predicate fiction, :valid?
  end
end
