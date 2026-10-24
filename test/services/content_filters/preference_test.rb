# frozen_string_literal: true

require 'test_helper'

module ContentFilters
  class PreferenceTest < ActiveSupport::TestCase
    setup do
      @everyone = fictions(:one)
      @sixteen = fictions(:two)
      @eighteen = fictions(:eighteen)
      FictionGenre.create!(fiction: @sixteen, genre: genres(:two))
      FictionGenre.create!(fiction: @eighteen, genre: genres(:two))
    end

    test 'open keeps every band' do
      preference = Preference.open

      assert_not_predicate preference, :active?
      assert_equal({}, preference.searchkick_where)
      assert_equal [@everyone.id, @sixteen.id, @eighteen.id], listed_ids(preference)
    end

    test 'an open fingerprint is the literal open' do
      assert_equal 'open', Preference.open.fingerprint
    end

    test 'a rating of 16 drops 18+ only' do
      preference = Preference.new(max_rating: 16, hidden_genre_ids: [].freeze)

      assert_equal [@everyone.id, @sixteen.id], listed_ids(preference)
      assert_equal({ content_rating: { lte: 16 } }, preference.searchkick_where)
    end

    test 'a rating of 0 drops 16+ and 18+' do
      preference = Preference.new(max_rating: 0, hidden_genre_ids: [].freeze)

      assert_equal [@everyone.id], listed_ids(preference)
      assert_equal({ content_rating: { lte: 0 } }, preference.searchkick_where)
    end

    test 'hidden genres drop matching works and ignore id order in the fingerprint' do
      forward = Preference.new(max_rating: nil, hidden_genre_ids: [genres(:one).id, genres(:two).id])
      reverse = Preference.new(max_rating: nil, hidden_genre_ids: [genres(:two).id, genres(:one).id])

      assert_equal [], listed_ids(forward)
      assert_equal forward.fingerprint, reverse.fingerprint
      assert_equal({ _not: { genre_ids: [genres(:one).id, genres(:two).id] } }, forward.searchkick_where)
    end

    test 'except_genre keeps an explicitly opened genre and still hides the others' do
      preference = Preference.new(max_rating: 16, hidden_genre_ids: [genres(:one).id, genres(:two).id])
      opened = preference.except_genre(genres(:one).id)

      assert_equal [@everyone.id], listed_ids(opened)
      assert_predicate preference, :hides_eighteen?
      assert_not_predicate Preference.open, :hides_eighteen?
    end

    test 'plain romance hides unless the work has bl, gl, or lgbt' do
      romance = Genre.create!(name: 'Романтика', slug: 'romance')
      lgbt = Genre.create!(name: 'LGBT', slug: 'lgbt')
      omega = Genre.create!(name: 'Омегаверс', slug: 'omegaverse')
      FictionGenre.create!(fiction: @everyone, genre: romance)
      FictionGenre.create!(fiction: @sixteen, genre: romance)
      FictionGenre.create!(fiction: @sixteen, genre: lgbt)
      FictionGenre.create!(fiction: @eighteen, genre: romance)
      FictionGenre.create!(fiction: @eighteen, genre: omega)
      preference = Preference.new(package_keys: ['romance_bl'])

      assert_equal [@sixteen.id], listed_ids(preference)
      assert_not preference.rejects_genre_ids?([romance.id, genres(:bl).id])
      assert preference.rejects_genre_ids?([romance.id, omega.id])
    end

    test 'two packages hide the union of their genres' do
      fantasy = Genre.create!(name: 'Фентезі', slug: 'fantasy')
      FictionGenre.create!(fiction: @everyone, genre: genres(:bl))
      FictionGenre.create!(fiction: @sixteen, genre: fantasy)
      ids = Packages.genre_ids_for(%w[shelves another_world])
      preference = Preference.new(package_keys: %w[shelves another_world], hidden_genre_ids: ids)

      assert_equal [@eighteen.id], listed_ids(preference)
    end

    test 'rating and genres compose' do
      preference = Preference.new(max_rating: 16, hidden_genre_ids: [genres(:two).id])

      assert_equal [@everyone.id], listed_ids(preference)
      assert_equal(
        { content_rating: { lte: 16 }, _not: { genre_ids: [genres(:two).id] } },
        preference.searchkick_where
      )
    end

    private

    def listed_ids(preference)
      preference.apply(Fiction.where(id: [@everyone.id, @sixteen.id, @eighteen.id])).order(:id).pluck(:id)
    end
  end
end
