# frozen_string_literal: true

class GenresHelperTest < ActionView::TestCase
  include GenresHelper

  test 'formatter converts genre name to slug' do
    genre = Genre.new(name: 'Rock, Pop - Music!')
    formatted_genre = genre_formatter(genre)

    assert_equal 'rock_pop_music', formatted_genre
  end
end
