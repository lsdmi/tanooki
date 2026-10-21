# frozen_string_literal: true

require 'test_helper'

class UserHiddenGenreTest < ActiveSupport::TestCase
  test 'rejects a rating pill' do
    genre = Genre.create!(name: '16+', slug: 'sixteen-pill', description: 'Rating pill, not a genre.')
    hidden = UserHiddenGenre.new(user: users(:user_one_one_zero), genre:)

    assert_not hidden.valid?
    assert hidden.errors.of_kind?(:genre, :rating_label)
  end

  test 'rejects the same genre twice' do
    duplicate = UserHiddenGenre.new(user: users(:user_two), genre: genres(:one))

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:genre_id, :taken)
  end

  test 'caps a reader at thirty genres' do
    user = users(:user_one_one_zero)
    UserHiddenGenre::MAX_PER_USER.times do |index|
      genre = Genre.create!(name: "Прихований #{index}", slug: "hidden-#{index}")
      UserHiddenGenre.create!(user:, genre:)
    end

    extra = Genre.create!(name: 'Зайвий', slug: 'hidden-extra')
    overflow = UserHiddenGenre.new(user:, genre: extra)

    assert_not overflow.valid?
    assert overflow.errors.of_kind?(:base, :too_many_genres)
  end
end
