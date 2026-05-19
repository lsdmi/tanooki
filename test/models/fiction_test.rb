# frozen_string_literal: true

require 'test_helper'

class FictionTest < ActiveSupport::TestCase
  def setup
    @user = users(:user_one)
    @fiction = Fiction.new(title: 'Test Fiction', author: 'Test Author', scanlator_ids: [1],
                           description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                           total_chapters: 5, user_id: @user.id)
    @fiction.cover.attach(Rack::Test::UploadedFile.new(Rails.root.join('app/assets/images/logo-default.svg'),
                                                       'image/svg'))
  end

  test 'should be valid' do
    assert_predicate @fiction, :valid?
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

  test 'cover should be in the correct format' do
    invalid_image = Rack::Test::UploadedFile.new(
      Rails.root.join('app/assets/stylesheets/actiontext.css')
    )

    @fiction.cover.attach(invalid_image)

    assert_not @fiction.valid?
  end

  test 'should destroy associated comments' do
    fiction = fictions(:one)
    fiction.comments << comments(:comment_one)

    assert_difference('Comment.count', -2) { fiction.destroy }
  end

  test 'should have many fiction genres' do
    assert_instance_of FictionGenre, @fiction.fiction_genres.build
  end

  test 'should have many genres through fiction genres' do
    assert_instance_of Genre, @fiction.genres.build
  end

  test 'should destroy associated fiction genres when destroyed' do
    fiction = fictions(:one)

    assert_difference('FictionGenre.count', -1) { fiction.destroy }
  end

  test 'valid when scanlator_ids unset but scanlator associations exist' do
    fiction = fictions(:one)
    fiction.scanlator_ids = nil

    assert_predicate fiction, :valid?
  end

  test 'invalid when scanlator_ids cleared and no scanlator associations' do
    fiction = fictions(:one)
    fiction.fiction_scanlators.destroy_all
    fiction.scanlator_ids = []

    assert_not fiction.valid?
    assert_includes fiction.errors[:scanlator_ids], 'має бути принаймні одна команда'
  end
end
