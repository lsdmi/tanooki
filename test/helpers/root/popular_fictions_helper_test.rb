# frozen_string_literal: true

require 'test_helper'

module Root
  class PopularFictionsHelperTest < ActionView::TestCase
    include PopularFictionsHelper

    test 'popular_fiction_genre_links returns at most two genres sorted by name' do
      fiction = fictions(:one)
      fiction.genres = [genres(:three), genres(:one), genres(:two)]

      links = popular_fiction_genre_links(fiction)

      assert_equal 2, links.size
      assert_equal ['Жанр Альфа', 'Жанр Бета'], links.pluck(:name)
      assert_equal %w[genre-alpha genre-beta], links.pluck(:slug)
    end
  end
end
