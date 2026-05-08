# frozen_string_literal: true

require 'test_helper'

class GenreTest < ActiveSupport::TestCase
  def setup
    @genre = genres(:three)
  end

  test 'should be valid' do
    assert_predicate @genre, :valid?
  end

  test 'name should be present' do
    @genre.name = ''

    assert_not @genre.valid?
  end

  test 'name should be unique' do
    duplicate_genre = @genre.dup

    assert_not duplicate_genre.valid?
  end

  test 'name should not be too long' do
    @genre.name = 'a' * 31

    assert_not @genre.valid?
  end

  test 'fiction association should be valid' do
    fiction = fictions(:one)
    fiction.genres << @genre

    assert_includes @genre.fictions, fiction
  end

  test 'should destroy associated fiction_genres' do
    fiction = fictions(:one)
    fiction.genres << @genre
    assert_difference 'FictionGenre.count', -1 do
      @genre.destroy
    end
  end

  test 'badge_asset_slug prefers stored slug' do
    g = Genre.create!(name: 'Жахи-test-badge', slug: 'horror-test')

    assert_equal 'horror-test', Genre.badge_asset_slug('Жахи-test-badge')
  ensure
    g&.destroy
  end

  test 'badge_asset_slug returns nil when no genre matches name' do
    assert_nil Genre.badge_asset_slug('__no_such_genre_name__')
  end
end
