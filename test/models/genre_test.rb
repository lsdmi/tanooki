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

  test 'explicit_content? by slug and name' do
    bl = Genre.create!(name: 'BL', slug: 'bl')
    drama = Genre.create!(name: 'Драма-test', slug: 'drama-test')

    assert_predicate bl, :explicit_content?
    assert Genre.explicit_content?(slug: 'gl')
    assert_not Genre.explicit_content?(slug: 'romance')
    assert Genre.explicit_content?(name: 'BL')
    assert_not drama.explicit_content?
  ensure
    bl&.destroy
    drama&.destroy
  end

  test 'tag_variant returns adult for explicit genres' do
    assert_equal :adult, Genre.tag_variant(slug: 'omegaverse')
    assert_equal :adult, Genre.tag_variant(name: '18+')
    assert_equal :genre, Genre.tag_variant(slug: 'fantasy')
  end

  test 'sort_labels_adult_first puts 18+ and explicit genres before others' do
    slugs = { 'BL' => 'bl', 'Драма' => 'drama', 'Романтика' => 'romance' }
    labels = %w[Романтика 18+ Драма BL]

    assert_equal %w[18+ BL Романтика Драма], Genre.sort_labels_adult_first(labels, slugs: slugs)
  end
end
